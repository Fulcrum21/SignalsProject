function [cases, reference, referenceFs, sourcePath] = loadAvailableCases(repoRoot, handoffFiles)
%LOADAVAILABLECASES Use exact processing arrays, never infer samples from a name.
% Accept top-level cases or samplingHandoff.cases. Explicit handoffs take
% precedence over automatic sampling controls; samples are never regenerated.
sourcePath = fullfile(repoRoot, 'Audios', 'SpeechMusic.wav');
[reference, referenceFs] = audioread(sourcePath);
info = audioinfo(sourcePath);
assert(iscolumn(reference) && referenceFs == 44100 && info.BitsPerSample == 16, ...
    'jesher:Reference', 'The agreed mono 44.1 kHz / 16-bit source is required.');
cases = repmat(template(), 0, 1);
fields = fieldnames(template());
required = setdiff(fields,{'method','samplingMetadata'});
%% Read explicitly supplied handoffs first.
for fileIndex = 1:numel(handoffFiles)
    data = load(handoffFiles{fileIndex});
    if isfield(data,'cases')
        supplied = data.cases;
    elseif isfield(data,'samplingHandoff')
        supplied = adaptSampling(data.samplingHandoff,handoffFiles{fileIndex},reference,referenceFs);
    else
        error('jesher:Handoff','Supply cases or samplingHandoff.cases: %s',handoffFiles{fileIndex});
    end
    assert(isstruct(supplied) && ~isempty(supplied),'jesher:Handoff','Empty or invalid handoff.');
    for j = 1:numel(supplied)
        incoming = supplied(j);
        assert(all(isfield(incoming,required)), 'jesher:Handoff', ...
            'Missing case metadata in %s. Read inputs/README.md.', handoffFiles{fileIndex});
        c = template();
        for f = 1:numel(fields)
            if isfield(incoming,fields{f}), c.(fields{f}) = incoming.(fields{f}); end
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

%% Automatic controls fill only IDs not supplied explicitly.
samplingPath = fullfile(repoRoot,'Results','Abdulrahman','Sampling','sampling_all_rates.mat');
if isfile(samplingPath)
    data = load(samplingPath,'samplingHandoff');
    controls = adaptSampling(data.samplingHandoff,samplingPath,reference,referenceFs);
    for j = 1:numel(controls)
        cases = addFallback(cases,controls(j));
    end
end

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
    'alignmentPolicy','aa03_full_record_v1','method','','samplingMetadata',struct());
end

function controls = adaptSampling(handoff,path,reference,referenceFs)
%% Map Abdulrahman's sampling-only metadata, keeping every supplied sample.
assert(isstruct(handoff) && isscalar(handoff) && isfield(handoff,'cases') && ...
    ~isempty(handoff.cases),'jesher:Handoff','Missing samplingHandoff.cases.');
assert(isequal(handoff.original.samples,reference) && handoff.original.Fs==referenceFs, ...
    'jesher:SourceMismatch','Sampling handoff source differs from Audios/SpeechMusic.wav.');
assert(~handoff.normalizationApplied && ~handoff.quantizationApplied && ...
    strcmpi(handoff.platform,'matlab') && handoff.sourceBitsPerSample==16, ...
    'jesher:Handoff','Expected unchanged MATLAB sampling-only controls from a 16-bit source.');
controls = repmat(template(),numel(handoff.cases),1);
for j = 1:numel(handoff.cases)
    entry = handoff.cases(j);
    assert(entry.sampleCount==numel(entry.samples) && ...
        entry.lastSampleTimeSeconds==entry.firstSampleTimeSeconds+(numel(entry.samples)-1)/entry.Fs && ...
        abs(entry.durationSeconds-numel(entry.samples)/entry.Fs)<1e-12, ...
        'jesher:Handoff','Sampling count/time metadata are inconsistent.');
    assert(ismember(entry.Fs,[22050 11025 8000 4000]) && ...
        ismember(string(entry.filterMode),["lpf","none"]),'jesher:Handoff','Unexpected sampling control.');
    if strcmp(entry.filterMode,'lpf')
        assert(entry.delayCompensatedByResample,'jesher:Handoff','FIR delay must already be compensated.');
    else
        assert(entry.rawFilterDelaySeconds==0,'jesher:Handoff','Unfiltered route must have no FIR delay.');
    end
    c = template();
    c.caseId = entry.caseId;
    c.samples = entry.samples;
    c.Fs = entry.Fs;
    c.sourceFile = handoff.sourceFile;
    c.filterMode = entry.filterMode;
    c.firstSampleTimeSeconds = entry.firstSampleTimeSeconds;
    c.platform = 'matlab';
    c.effectiveBits = 16;
    c.processingStage = 'sampling_only_control';
    c.quantizationApplied = false;
    c.normalizationApplied = false;
    c.delayCompensated = true; % LPF already compensated; none has no FIR delay.
    c.alignmentPolicy = 'full_record_resample_v1';
    c.quantizerDescription = 'b16 identifies source/control; double-valued sampling array, no additional quantization.';
    c.method = entry.method;
    c.samplingDescription = entry.method;
    c.samplingMetadata = rmfield(entry,'samples'); % Preserve ratios, coefficients and timing.
    c.provenance = sprintf('%s: samplingHandoff.cases(%d); MATLAB %s; exact supplied double array.', ...
        path,j,handoff.matlabRelease);
    if isfield(entry,'provenance')
        c.provenance = sprintf('%s Producer provenance: %s',c.provenance,entry.provenance);
    end
    controls(j) = c;
end
assert(numel(unique(string({controls.caseId})))==numel(controls), ...
    'jesher:DuplicateCase','Duplicate IDs in samplingHandoff.cases.');
end
