%% Khaled_KH04_All_Cases.m
% This script creates 36 MATLAB cases and 36 Simulink cases (72 total).
% Connected files used:
%   Matlab/Khaled_Quantizer.m
%   Simulink/Khaled_Quantizer_Model.slx
%   Audios/SpeechMusic.wav
%   Results/Abdulrahman/Sampling/sampling_all_rates.mat
%   Results/Abdulrahman/Sampling/simulink_cases.mat
%
% Model configuration:
%   From Workspace: simIn, interpolation off, hold final value
%   MATLAB Function: fcn(u,B), same signed quantizer as Khaled_Quantizer
%   Constant block: Bsim
%   To Workspace: sim_q4, Timeseries, decimation 1, no data limit
%   Solver: fixed-step discrete; step 1/Fs
%
% This script deliberately does not export WAVs. Jesher handles file
% container bits/size and listening/quality after this MAT-array handoff.

clc;
clear;
close all;

%% 1. Paths and input verification
scriptFolder = fileparts(mfilename('fullpath'));
projectRoot = fileparts(scriptFolder);
addpath(scriptFolder);
addpath(fullfile(projectRoot, 'Simulink'));

inputFolder = fullfile(projectRoot,'Results','Abdulrahman','Sampling');
matInputFile = fullfile(inputFolder,'sampling_all_rates.mat');
simInputFile = fullfile(inputFolder,'simulink_cases.mat');
audioFile = fullfile(projectRoot,'Audios','SpeechMusic.wav');
modelFile = fullfile(projectRoot,'Simulink','Khaled_Quantizer_Model.slx');
outFolder = fullfile(projectRoot,'Results','Khaled','Combined');

assert(isfile(matInputFile), 'Missing MATLAB sampling handoff file.');
assert(isfile(simInputFile), 'Missing Simulink sampling handoff file.');
assert(isfile(audioFile), 'Missing original audio recording.');
assert(isfile(modelFile), 'Missing Khaled Simulink quantizer model.');
if ~exist(outFolder,'dir'), mkdir(outFolder); end

[original, originalFs] = audioread(audioFile);
assert(originalFs == 44100 && iscolumn(original), ...
    'Expected unchanged mono 44100 Hz primary recording.');
original = double(original(:));
originalN = numel(original);

M = load(matInputFile,'samplingHandoff');
S = load(simInputFile,'cases');
assert(isfield(M,'samplingHandoff') && isfield(S,'cases'), ...
    'Unexpected sampling handoff MAT variables.');
assert(isequal(M.samplingHandoff.original.samples(:),original), ...
    'Sampling handoff uses a different original recording.');
assert(M.samplingHandoff.original.Fs == originalFs, ...
    'Original sampling rate metadata mismatch.');

mCases = M.samplingHandoff.cases;
sCases = S.cases;
assert(numel(mCases)==8 && numel(sCases)==8, ...
    'Expected eight lower-rate cases from each platform.');

modelName = 'Khaled_Quantizer_Model';
load_system(modelFile);

%% 2. Define the 9 processing paths, each with 4 bit depths
rates = [44100, 22050, 11025, 8000, 4000];
bitDepths = [16, 8, 4, 2];
filterModes = {'native','none','lpf'};

caseTemplate = newCaseTemplate();
matlabCases = repmat(caseTemplate,0,1);
simulinkCases = repmat(caseTemplate,0,1);

rowTemplate = struct('caseId','','Fs',0,'filterMode','', ...
    'Bits',0,'SampleCount',0,'DurationSeconds',0, ...
    'InputDifference',0,'OutputDifference',0, ...
    'TimeDifferenceSeconds',0,'DifferentQuantizedSamples',0, ...
    'MATLAB_QuantizationMSE',0,'Simulink_QuantizationMSE',0);
checks = repmat(rowTemplate,0,1);
runId = datestr(now,30);

fprintf('Original: %d samples at %d Hz (%.6f s)\n', ...
    originalN,originalFs,originalN/originalFs);

%% 3. For every sampling path, apply all 4 quantizers
for ri = 1:numel(rates)
    rate = rates(ri);
    if rate == originalFs
        modesForRate = filterModes(1);  % native only
    else
        modesForRate = filterModes(2:3); % none and lpf
    end

    for mi = 1:numel(modesForRate)
        mode = modesForRate{mi};

        if strcmp(mode,'native')
            rawM = original;
            rawS = original;
            samplingDescM = 'Native, unchanged original sample grid.';
            samplingDescS = 'Native, unchanged original sample grid.';
            samplingMetaM = struct('source','original PCM16 recording');
            samplingMetaS = samplingMetaM;
            sourceM = 'Audios/SpeechMusic.wav';
            sourceS = sourceM;
        else
            ixM = find([mCases.Fs] == rate & ...
                strcmp({mCases.filterMode},mode));
            ixS = find([sCases.Fs] == rate & ...
                strcmp({sCases.filterMode},mode));
            assert(numel(ixM)==1 && numel(ixS)==1, ...
                'Sampling handoff lacks exactly one %d-Hz %s case per platform.', ...
                rate,mode);
            m = mCases(ixM);
            s = sCases(ixS);
            rawM = double(m.samples(:));
            rawS = double(s.samples(:));

            assert(strcmp(s.platform,'simulink') && ...
                strcmp(m.filterMode,s.filterMode) && m.Fs==s.Fs, ...
                'Incorrect sampling platform or case metadata.');
            assert(m.sampleCount == numel(rawM), ...
                'MATLAB sampling metadata sampleCount mismatch.');
            assert(m.firstSampleTimeSeconds == 0 && ...
                s.firstSampleTimeSeconds == 0, ...
                'Nonzero start time requires a separate alignment review.');

            samplingDescM = m.method;
            samplingDescS = s.samplingDescription;
            samplingMetaM = rmfield(m,'samples');
            samplingMetaS = rmfield(s,'samples');
            sourceM = sprintf('sampling_all_rates.mat:case %s',m.caseId);
            sourceS = sprintf('simulink_cases.mat:case %s',s.caseId);
        end

        expectedN = ceil(originalN*rate/originalFs);
        assert(numel(rawM)==expectedN && numel(rawS)==expectedN, ...
            'Source-covered sample count mismatch for %d Hz %s.',rate,mode);
        assert(all(isfinite(rawM)) && all(isfinite(rawS)), ...
            'Non-finite samples in a sampling handoff.');
        inputDifference = max(abs(rawM-rawS));

        time = (0:expectedN-1)'/rate;
        simIn = timeseries(rawS,time);

        fprintf('\nPath: %6d Hz, %-6s, N=%d, sampling max diff=%.4g\n', ...
            rate,mode,expectedN,inputDifference);

        for bi = 1:numel(bitDepths)
            B = bitDepths(bi);
            Bsim = B;

            % MATLAB route: quantize actual MATLAB sampling array.
            [qMAT,eMAT] = Khaled_Quantizer(rawM,B);

            % Simulink route: quantize actual Simulink sampling array.
            simulation = Simulink.SimulationInput(modelName);
            simulation = simulation.setVariable('simIn',simIn);
            simulation = simulation.setVariable('Fs',rate);
            simulation = simulation.setVariable('Bsim',Bsim);
            simulation = simulation.setModelParameter( ...
                'StopTime',sprintf('%.17g',time(end)), ...
                'SolverType','Fixed-step', ...
                'Solver','FixedStepDiscrete', ...
                'FixedStep',sprintf('%.17g',1/rate));
            result = sim(simulation);
            logged = result.get('sim_q4');
            qSIM = double(logged.Data(:));
            tSIM = double(logged.Time(:));

            assert(numel(qSIM)==expectedN && numel(tSIM)==expectedN, ...
                'Simulink output size mismatch (%d Hz, %s, %d bits).', ...
                rate,mode,B);
            timeDifference = max(abs(tSIM-time));
            assert(timeDifference < 1e-8, ...
                'Simulink time grid mismatch (%d Hz %s %d bits).', ...
                rate,mode,B);

            [qSIMreference,eSIM] = Khaled_Quantizer(rawS,B);
            assert(max(abs(qSIM-qSIMreference)) < 1e-12, ...
                'Simulink quantizer does not match MATLAB on its own input.');

            % Validate effective-bit level mapping and unchanged controls.
            checkLevels(qMAT,rawM,B);
            checkLevels(qSIM,rawS,B);

            idM = sprintf('speechmusic_fs%d_b%02d_%s_matlab',rate,B,mode);
            idS = sprintf('speechmusic_fs%d_b%02d_%s_simulink',rate,B,mode);
            provM = sprintf('%s; Khaled_Quantizer.m; run %s; MATLAB %s.', ...
                sourceM,runId,version('-release'));
            provS = sprintf('%s; Khaled_Quantizer_Model.slx; run %s; MATLAB %s.', ...
                sourceS,runId,version('-release'));

            cM = buildCase(caseTemplate,idM,'matlab',qMAT,eMAT, ...
                rate,B,mode,samplingDescM,samplingMetaM,provM);
            cS = buildCase(caseTemplate,idS,'simulink',qSIM,eSIM, ...
                rate,B,mode,samplingDescS,samplingMetaS,provS);
            matlabCases(end+1,1) = cM; %#ok<SAGROW>
            simulinkCases(end+1,1) = cS; %#ok<SAGROW>

            cr = rowTemplate;
            cr.caseId = sprintf('speechmusic_fs%d_b%02d_%s',rate,B,mode);
            cr.Fs = rate;
            cr.filterMode = mode;
            cr.Bits = B;
            cr.SampleCount = expectedN;
            cr.DurationSeconds = expectedN/rate;
            cr.InputDifference = inputDifference;
            cr.OutputDifference = max(abs(qMAT-qSIM));
            cr.TimeDifferenceSeconds = timeDifference;
            cr.DifferentQuantizedSamples = nnz(qMAT~=qSIM);
            cr.MATLAB_QuantizationMSE = mean(eMAT.^2);
            cr.Simulink_QuantizationMSE = mean(eSIM.^2);
            checks(end+1,1) = cr; %#ok<SAGROW>

            fprintf('  %2d bits: quantizer PASS; output max diff = %.4g; differing samples = %d\n', ...
                B,cr.OutputDifference,cr.DifferentQuantizedSamples);
        end
    end
end

%% 4. Verify all case IDs and matrix coverage
assert(numel(matlabCases)==36 && numel(simulinkCases)==36 && ...
    numel(checks)==36,'Incorrect case matrix size.');
allIDs = string([{matlabCases.caseId},{simulinkCases.caseId}]);
assert(numel(unique(allIDs))==72,'Duplicate case IDs found.');
assert(isequal(matlabCases(1).samples,original), ...
    'Native MATLAB 16-bit reference was changed.');
assert(isequal(simulinkCases(1).samples,original), ...
    'Native Simulink 16-bit reference was changed.');

%% 5. Save 36 cases per platform for Jesher
% Each MAT has top-level variable `cases` as required by Jesher's loader.
cases = matlabCases; %#ok<NASGU>
save(fullfile(outFolder,'KH04_MATLAB_Cases.mat'), ...
    'cases','-v7.3');

cases = simulinkCases; %#ok<NASGU>
save(fullfile(outFolder,'KH04_Simulink_Cases.mat'), ...
    'cases','-v7.3');

comparison = struct2table(checks);
writetable(comparison,fullfile(outFolder,'KH04_Comparison_Manifest.csv'));

% Combined case manifest for counting, filtering, and handoff inventory.
caseID = string(allIDs(:));
platform = [repmat("matlab",36,1); repmat("simulink",36,1)];
allCases = [matlabCases;simulinkCases];
actualFs = vertcat(allCases.Fs);
effectiveBits = vertcat(allCases.effectiveBits);
filterMode = string({allCases.filterMode})';
sampleCount = vertcat(allCases.sampleCount);
durationSeconds = vertcat(allCases.durationSeconds);
idealPackedBytes = vertcat(allCases.idealPackedBytes);
peakAbsAmplitude = arrayfun(@(c) max(abs(c.samples)),allCases);
inventory = table(caseID,platform,actualFs,effectiveBits,filterMode, ...
    sampleCount,durationSeconds,idealPackedBytes,peakAbsAmplitude);
writetable(inventory,fullfile(outFolder,'KH04_72_Case_Inventory.csv'));

fprintf('\n==========================================\n');
fprintf('KH-04 GENERATED: %d MATLAB, %d Simulink, %d total cases.\n', ...
    numel(matlabCases),numel(simulinkCases),numel(allCases));
fprintf('Maximum cross-platform output difference: %.12g\n', ...
    max([checks.OutputDifference]));
fprintf('Maximum cross-platform sample discrepancy count: %d\n', ...
    max([checks.DifferentQuantizedSamples]));
fprintf('Saved in: %s\n',outFolder);
if any(peakAbsAmplitude > 1)
    warning(['Some unmodified control samples exceed the PCM16 range. ', ...
        'Discuss with Jesher before WAV export; do not silently normalize.']);
end
fprintf('Handoff still requires Jesher acceptance and export checks.\n');
if any([checks.DifferentQuantizedSamples] > 0)
    fprintf(['NOTE: Differences between platforms may reflect differences in upstream ', ...
        'sampling arrays. Inspect KH04_Comparison_Manifest.csv.\n']);
else
    fprintf('All corresponding quantized arrays match sample by sample.\n');
end

%% Local helper functions
function c = newCaseTemplate()
% Required fields follow Jesher/inputs/README.md, plus useful audit fields.
c = struct( ...
    'caseId','','platform','','sourceFile','Audios/SpeechMusic.wav', ...
    'samples',[],'Fs',0,'effectiveBits',0,'filterMode','', ...
    'firstSampleTimeSeconds',0,'delayCompensated',true, ...
    'processingStage','','quantizationApplied',false, ...
    'normalizationApplied',false,'quantizerDescription','', ...
    'samplingDescription','','provenance','', ...
    'alignmentPolicy','full_record_resample_v1', ...
    'method','','samplingMetadata',struct(), ...
    'quantizationError',[],'sampleCount',0,'channelCount',1, ...
    'durationSeconds',0,'lastSampleTimeSeconds',0, ...
    'quantizationStep',NaN,'idealPackedBytes',0);
end

function c = buildCase(c,id,platform,q,errorSamples,Fs,B,mode, ...
    samplingDescription,samplingMetadata,provenance)
c.caseId = id;
c.platform = platform;
c.samples = double(q(:));
c.quantizationError = double(errorSamples(:));
c.Fs = Fs;
c.effectiveBits = B;
c.filterMode = mode;
c.firstSampleTimeSeconds = 0;
c.delayCompensated = true;
c.normalizationApplied = false;
c.quantizationApplied = B < 16;
if B == 16 && strcmp(mode,'native')
    c.processingStage = 'native_reference';
elseif B == 16
    c.processingStage = 'sampling_only_control';
elseif strcmp(mode,'native')
    c.processingStage = 'native_quantized';
else
    c.processingStage = 'combined_quantized';
end
if B == 16
    c.quantizerDescription = '16-bit reference/control; no additional quantization.';
    c.quantizationStep = NaN;
else
    step = 2/2^B;
    c.quantizationStep = step;
    c.quantizerDescription = sprintf([ ...
        '%d-bit signed uniform; fixed range [-1,1); %d levels; ', ...
        'step %.12g; levels -1 to %.12g; round ties away from zero; ', ...
        'clip indices [%d,%d]; no normalization.'], ...
        B,2^B,step,1-step,-2^(B-1),2^(B-1)-1);
end
c.samplingDescription = samplingDescription;
c.method = samplingDescription;
c.samplingMetadata = samplingMetadata;
c.provenance = provenance;
c.sampleCount = numel(q);
c.channelCount = 1;
c.durationSeconds = numel(q)/Fs;
c.lastSampleTimeSeconds = (numel(q)-1)/Fs;
c.idealPackedBytes = ceil(numel(q)*B/8);
end

function checkLevels(q,raw,B)
assert(isequal(size(q),size(raw)) && all(isfinite(q)), ...
    'Quantizer changed dimensions or returned non-finite values.');
if B == 16
    assert(isequal(q,raw),'16-bit control must be unchanged.');
else
    step = 2/2^B;
    assert(all(q >= -1-1e-12 & q <= 1-step+1e-12), ...
        'Quantizer amplitude outside fixed levels.');
    idx = q/step;
    assert(all(abs(idx-round(idx))<1e-9), ...
        'Quantizer output is not on the agreed uniform grid.');
    assert(numel(unique(q)) <= 2^B,'Too many quantization levels.');
end
end
