function [cases, reference, referenceFs, sourcePath] = loadAvailableCases(repoRoot, handoffFiles)
%LOADAVAILABLECASES Use exact processing arrays, never infer samples from a name.
% An external MAT file must contain a struct vector named cases. Explicit
% handoffs take precedence over the built-in *fallback* sampling controls.
sourcePath = fullfile(repoRoot, 'Audios', 'SpeechMusic.wav');
[reference, referenceFs] = audioread(sourcePath);
info = audioinfo(sourcePath);
assert(iscolumn(reference) && referenceFs == 44100 && info.BitsPerSample == 16, ...
    'jesher:Reference', 'The agreed mono 44.1 kHz / 16-bit source is required.');
cases = repmat(template(), 0, 1);
fields = fieldnames(template());
for fileIndex = 1:numel(handoffFiles)
    data = load(handoffFiles{fileIndex}, 'cases');
    assert(isfield(data, 'cases') && isstruct(data.cases) && ~isempty(data.cases), ...
        'jesher:Handoff', 'Each handoff must contain a nonempty cases struct vector.');
    for j = 1:numel(data.cases)
        incoming = data.cases(j);
        assert(all(isfield(incoming, fields)), 'jesher:Handoff', ...
            'Missing case metadata in %s. Read inputs/README.md.', handoffFiles{fileIndex});
        c = template();
        for f = 1:numel(fields)
            c.(fields{f}) = incoming.(fields{f});
        end
        cases(end+1,1) = c; %#ok<AGROW>
    end
end
if ~isempty(cases)
    ids = string({cases.caseId});
    assert(numel(unique(ids)) == numel(ids), 'jesher:DuplicateCase', ...
        'Duplicate IDs in supplied handoffs; no result has been overwritten.');
end

c = template();
c.caseId = 'speechmusic_fs44100_b16_native_matlab';
c.samples = reference;
c.Fs = referenceFs;
c.filterMode = 'native';
c.processingStage = 'native_reference';
c.quantizerDescription = 'Original 16-bit PCM reference; no further quantization.';
c.samplingDescription = 'Native original sample grid, unchanged.';
c.provenance = 'Audios/SpeechMusic.wav, read by audioread in this run.';
cases = addFallback(cases, c);

prototypePath = fullfile(repoRoot, 'Results', 'Abdulrahman', 'AA02', 'sampling_22050.mat');
if isfile(prototypePath)
    data = load(prototypePath, 'prototype');
    p = data.prototype;
    assert(isequal(p.original.samples, reference) && p.original.Fs == referenceFs, ...
        'jesher:SourceMismatch', 'Sampling handoff does not match the original source.');
    assert(~p.normalizationApplied && ~p.quantizationApplied, 'jesher:Handoff', ...
        'The built-in adapter expects the documented sampling-only handoff.');
    for branch = {'filtered', 'unfiltered'}
        b = p.(branch{1});
        assert(b.sampleCount == numel(b.samples) && b.Fs == 22050, ...
            'jesher:Handoff', 'Unexpected sampling prototype metadata.');
        assert(b.lastSampleTimeSeconds == (numel(b.samples)-1)/b.Fs, ...
            'jesher:Handoff', 'Sampling prototype last-sample time is inconsistent.');
        c = template();
        c.caseId = b.caseId;
        c.samples = b.samples;
        c.Fs = b.Fs;
        c.filterMode = b.filterMode;
        c.firstSampleTimeSeconds = b.firstSampleTimeSeconds;
        c.delayCompensated = true;
        c.processingStage = 'sampling_only_control';
        c.quantizerDescription = 'b16 source/control; double sampling array, no explicit quantizer.';
        if strcmp(b.filterMode, 'lpf')
            assert(p.filter.delayCompensatedByResample, 'jesher:Handoff', ...
                'Sampling FIR delay has not been compensated.');
            c.samplingDescription = sprintf( ...
                'resample(x,1,2,10,5); %d taps; FIR delay already compensated.', ...
                numel(p.filter.coefficients));
        else
            c.samplingDescription = 'Direct x(1:2:end), without anti-aliasing filtering.';
        end
        c.provenance = 'Results/Abdulrahman/AA02/sampling_22050.mat: prototype';
        cases = addFallback(cases, c);
    end
end
end

function cases = addFallback(cases, c)
if isempty(cases) || ~any(strcmp({cases.caseId}, c.caseId))
    cases(end+1,1) = c;
end
end

function c = template()
c = struct('caseId','','platform','matlab','sourceFile','Audios/SpeechMusic.wav', ...
    'samples',[],'Fs',44100,'effectiveBits',16,'filterMode','native', ...
    'firstSampleTimeSeconds',0,'delayCompensated',true, ...
    'processingStage','','quantizationApplied',false,'normalizationApplied',false, ...
    'quantizerDescription','','samplingDescription','','provenance','', ...
    'alignmentPolicy','aa03_full_record_v1');
end
