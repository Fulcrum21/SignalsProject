
%% First Combined Sampling and Quantization Case
% 8000 Hz, LPF, 4-bit
clc;
clear;
close all;

%% Project paths
scriptFolder = fileparts(mfilename('fullpath'));
root = fileparts(scriptFolder);

addpath(scriptFolder);
addpath(fullfile(root, 'Simulink'));

sourceFolder = fullfile(root, 'Results', ...
    'Abdulrahman', 'Sampling');

outputFolder = fullfile(root, 'Results', ...
    'Khaled', 'Combined');

if ~exist(outputFolder, 'dir')
    mkdir(outputFolder);
end

%% Load verified sampling handoffs
A = load(fullfile(sourceFolder, ...
    'sampling_all_rates.mat'));

S = load(fullfile(sourceFolder, ...
    'simulink_cases.mat'));

matlabCases = A.samplingHandoff.cases;
simulinkCases = S.cases;

%% Select the 8000 Hz LPF case
idxM = find([matlabCases.Fs] == 8000 & ...
    strcmp({matlabCases.filterMode}, 'lpf'), 1);

idxS = find([simulinkCases.Fs] == 8000 & ...
    strcmp({simulinkCases.filterMode}, 'lpf'), 1);

assert(~isempty(idxM) && ~isempty(idxS), ...
    '8000 Hz LPF sampling case not found.');

m = matlabCases(idxM);
s = simulinkCases(idxS);

assert(m.Fs == s.Fs, 'Sampling rates differ.');
assert(numel(m.samples) == numel(s.samples), ...
    'Sample counts differ.');

Fs = m.Fs;
Bsim = 4;

xSampledMAT = m.samples(:);
xSampledSIM = s.samples(:);

N = numel(xSampledMAT);
t = (0:N-1)' / Fs;

%% MATLAB quantization
[qMAT, eMAT] = Khaled_Quantizer(xSampledMAT, Bsim);

%% Simulink quantization
simIn = timeseries(xSampledSIM, t);

modelName = 'Khaled_Quantizer_Model';

load_system(fullfile(root, 'Simulink', ...
    [modelName '.slx']));

simInput = Simulink.SimulationInput(modelName);

simInput = simInput.setVariable('simIn', simIn);
simInput = simInput.setVariable('Fs', Fs);
simInput = simInput.setVariable('Bsim', Bsim);

simInput = simInput.setModelParameter( ...
    'StopTime', sprintf('%.17g', t(end)), ...
    'SolverType', 'Fixed-step', ...
    'Solver', 'FixedStepDiscrete', ...
    'FixedStep', sprintf('%.17g', 1/Fs));

simOut = sim(simInput);

simData = simOut.get('sim_q4');

qSIM = simData.Data(:);
tSIM = simData.Time(:);

assert(numel(qSIM) == N, ...
    'Simulink output sample count mismatch.');

maxTimeDiff = max(abs(tSIM - t));
assert(maxTimeDiff < 1e-8, ...
    'Simulink output timing mismatch.');

eSIM = xSampledSIM - qSIM;

%% Verify both platforms
maxDifference = max(abs(qMAT - qSIM));

fprintf('\n===== FIRST COMBINED CASE =====\n');
fprintf('Sampling rate: %d Hz\n', Fs);
fprintf('Effective bits: %d\n', Bsim);
fprintf('Sample count: %d\n', N);
fprintf('Duration: %.6f s\n', N/Fs);

fprintf('MATLAB distinct levels: %d\n', ...
    numel(unique(qMAT)));

fprintf('Simulink distinct levels: %d\n', ...
    numel(unique(qSIM)));

fprintf('Maximum difference: %.12g\n', ...
    maxDifference);

fprintf('Maximum timing difference: %.12g s\n', ...
    maxTimeDiff);

assert(numel(unique(qMAT)) <= 2^Bsim);
assert(numel(unique(qSIM)) <= 2^Bsim);

%% Prepare case metadata
quantizerInfo = ['4-bit uniform signed quantizer; ', ...
    'range [-1,1); step=0.125; ', ...
    'round to nearest, ties away from zero; ', ...
    'saturate indices to [-8,7].'];

c = struct();

c.caseId = 'speechmusic_fs8000_b04_lpf_matlab';
c.platform = 'matlab';
c.sourceFile = 'Audios/SpeechMusic.wav';
c.samples = qMAT;
c.Fs = Fs;
c.effectiveBits = Bsim;
c.filterMode = 'lpf';
c.firstSampleTimeSeconds = 0;
c.delayCompensated = true;
c.processingStage = 'combined_quantized';
c.quantizationApplied = true;
c.normalizationApplied = false;
c.quantizerDescription = quantizerInfo;
c.samplingDescription = ...
    'Abdulrahman 8000 Hz LPF MATLAB handoff';
c.provenance = ...
    'sampling_all_rates.mat; Khaled_Quantizer.m';
c.alignmentPolicy = 'full_record_resample_v1';

% Preserve full sampling metadata, excluding copied samples
c.samplingMetadata = rmfield(m, 'samples');

cases = c;

c2 = c;
c2.caseId = 'speechmusic_fs8000_b04_lpf_simulink';
c2.platform = 'simulink';
c2.samples = qSIM;
c2.samplingDescription = ...
    'Abdulrahman aligned 8000 Hz LPF Simulink output';
c2.provenance = ...
    'simulink_cases.mat; Khaled_Quantizer_Model.slx';
c2.samplingMetadata = rmfield(s, 'samples');

cases(2) = c2;

%% Save the two combined cases and error samples
save(fullfile(outputFolder, ...
    'KH04_First_Combined_Case.mat'), ...
    'cases', 'eMAT', 'eSIM', ...
    'maxDifference', 'maxTimeDiff', '-v7');

if maxDifference < 1e-12
    disp('PASS: Combined MATLAB and Simulink cases match.');
else
    warning('Combined cases differ. Review sampling inputs.');
end

disp('First KH-04 combined-case test completed.');
