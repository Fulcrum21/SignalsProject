% Full-length MATLAB vs Simulink comparison
% Bit depths: 16, 8, 4, 2
% Original sampling rate: 44100 Hz
%
% Connected files:
% 1. Khaled_Quantizer.m
% 2. Khaled_Quantizer_Model.slx
% 3. SpeechMusic.wav

clc;
clear;
close all;

%% =========================================
% STEP 1: Locate project folders
% ==========================================

scriptFolder = fileparts(mfilename('fullpath'));
projectRoot = fileparts(scriptFolder);

audioPath = fullfile(projectRoot, ...
    'Audios', 'SpeechMusic.wav');

simulinkFolder = fullfile(projectRoot, 'Simulink');

outputFolder = fullfile(projectRoot, ...
    'Results', 'Khaled', 'Simulink');

% Create output folder if necessary
if ~exist(outputFolder, 'dir')
    mkdir(outputFolder);
end

% Make MATLAB and Simulink files accessible
addpath(scriptFolder);
addpath(simulinkFolder);

%% =========================================
% STEP 2: Load original audio
% ==========================================

[x, Fs] = audioread(audioPath);

% This Simulink model processes mono audio
assert(size(x,2) == 1, ...
    'Expected a mono recording.');

N = size(x,1);

duration = N / Fs;

% Generate timestamps for every sample
t = (0:N-1)' / Fs;

% Prepare From Workspace input
simIn = timeseries(x, t);

% Final sample timestamp
tEnd = t(end);

fprintf('\n===== ORIGINAL AUDIO =====\n');
fprintf('Sampling rate: %d Hz\n', Fs);
fprintf('Number of samples: %d\n', N);
fprintf('Duration: %.6f seconds\n', duration);
fprintf('Number of channels: %d\n', size(x,2));

%% =========================================
% STEP 3: Load Simulink model
% ==========================================

modelName = 'Khaled_Quantizer_Model';

modelFile = fullfile(simulinkFolder, ...
    [modelName '.slx']);

assert(isfile(modelFile), ...
    'Simulink model not found.');

load_system(modelFile);

fprintf('\nSimulink model loaded successfully.\n');

%% =========================================
% STEP 4: Define quantization settings
% ==========================================

bitDepths = [16 8 4 2];

numCases = length(bitDepths);

% Preallocate results
MSE_MAT = zeros(numCases,1);
MSE_SIM = zeros(numCases,1);

SNR_MAT = zeros(numCases,1);
SNR_SIM = zeros(numCases,1);

MaxDifference = zeros(numCases,1);
MaxTimeDifference = zeros(numCases,1);

signalPower = sum(x(:).^2);

%% =========================================
% STEP 5: Run all Simulink cases
% ==========================================

for k = 1:numCases

    Bsim = bitDepths(k);

    fprintf('\n=============================\n');
    fprintf('Running %d-bit quantization\n', Bsim);
    fprintf('=============================\n');

    %% 5.1 MATLAB reference quantization

    [xq_mat, e_mat] = Khaled_Quantizer(x, Bsim);

    %% 5.2 Prepare Simulink simulation

    simInput = Simulink.SimulationInput(modelName);

    % Supply variables required by the model
    simInput = simInput.setVariable('simIn', simIn);
    simInput = simInput.setVariable('Fs', Fs);
    simInput = simInput.setVariable('Bsim', Bsim);

    % Use the original sample timing
    simInput = simInput.setModelParameter( ...
        'StopTime', sprintf('%.17g', tEnd), ...
        'SolverType', 'Fixed-step', ...
        'Solver', 'FixedStepDiscrete', ...
        'FixedStep', sprintf('%.17g', 1/Fs));

    %% 5.3 Run Simulink

    simOut = sim(simInput);

    %% 5.4 Extract Simulink results

    % To Workspace block must be named sim_q4
    % and use Timeseries save format
    simData = simOut.get('sim_q4');

    xq_sim = simData.Data(:);
    t_sim = simData.Time(:);

    %% 5.5 Verify sample count

    fprintf('MATLAB samples: %d\n', numel(xq_mat));
    fprintf('Simulink samples: %d\n', numel(xq_sim));

    assert(numel(xq_sim) == N, ...
        'ERROR: Simulink sample count mismatch.');

    %% 5.6 Verify timestamps

    assert(numel(t_sim) == N, ...
        'ERROR: Simulink timestamp count mismatch.');

    MaxTimeDifference(k) = max(abs(t_sim-t));

    fprintf('Maximum time difference: %.12g s\n', ...
        MaxTimeDifference(k));

    assert(MaxTimeDifference(k) < 1e-8, ...
        'ERROR: Simulink timestamps are misaligned.');

    %% 5.7 Compare MATLAB and Simulink samples

    sampleDifference = xq_mat(:) - xq_sim(:);

    MaxDifference(k) = max(abs(sampleDifference));

    fprintf('Maximum sample difference: %.12g\n', ...
        MaxDifference(k));

    %% 5.8 Calculate quantization errors

    e_sim = x - xq_sim;

    %% 5.9 Calculate MSE

    MSE_MAT(k) = mean(e_mat(:).^2);

    MSE_SIM(k) = mean(e_sim(:).^2);

    %% 5.10 Calculate SNR

    errorPowerMAT = sum(e_mat(:).^2);
    errorPowerSIM = sum(e_sim(:).^2);

    if errorPowerMAT == 0
        SNR_MAT(k) = Inf;
    else
        SNR_MAT(k) = ...
            10*log10(signalPower/errorPowerMAT);
    end

    if errorPowerSIM == 0
        SNR_SIM(k) = Inf;
    else
        SNR_SIM(k) = ...
            10*log10(signalPower/errorPowerSIM);
    end

    fprintf('MATLAB MSE: %.10g\n', MSE_MAT(k));
    fprintf('Simulink MSE: %.10g\n', MSE_SIM(k));

    fprintf('MATLAB SNR: %.4f dB\n', SNR_MAT(k));
    fprintf('Simulink SNR: %.4f dB\n', SNR_SIM(k));

    %% 5.11 Verify numerical agreement

    if MaxDifference(k) < 1e-12
        fprintf('PASS: MATLAB and Simulink match!\n');
    else
        warning('MATLAB and Simulink outputs differ.');
    end

    %% 5.12 Save signal and metadata

    effectiveBits = Bsim;
    actualFs = Fs;
    numSamples = N;
    numChannels = size(x,2);

    filterMode = 'native';

    caseId = sprintf( ...
        'native_fs%d_b%02d_simulink', Fs, Bsim);

    if Bsim == 16
        quantizerMode = 'unchanged reference';
    else
        quantizerMode = ...
            'signed uniform rounding and clipping';
    end

    if Bsim == 16
        quantizationStep = NaN;
    else
        quantizationStep = 2 / (2^Bsim);
    end

    filename = sprintf('Simulink_%dbit.mat', Bsim);

    save(fullfile(outputFolder,filename), ...
        'xq_sim', ...
        'e_sim', ...
        't_sim', ...
        'effectiveBits', ...
        'actualFs', ...
        'numSamples', ...
        'numChannels', ...
        'duration', ...
        'filterMode', ...
        'caseId', ...
        'quantizerMode', ...
        'quantizationStep');

    fprintf('Saved: %s\n', filename);

end

%% =========================================
% STEP 6: Generate comparison table
% ==========================================

Comparison = table( ...
    bitDepths', ...
    MSE_MAT, ...
    MSE_SIM, ...
    SNR_MAT, ...
    SNR_SIM, ...
    MaxDifference, ...
    MaxTimeDifference, ...
    'VariableNames', { ...
    'Bits', ...
    'MSE_MATLAB', ...
    'MSE_Simulink', ...
    'SNR_MATLAB', ...
    'SNR_Simulink', ...
    'MaxDifference', ...
    'MaxTimeDifference'});

fprintf('\n=====================================\n');
fprintf('FULL MATLAB VS SIMULINK COMPARISON\n');
fprintf('=====================================\n');

disp(Comparison);

% Save table as CSV
writetable(Comparison, ...
    fullfile(outputFolder, ...
    'MATLAB_Simulink_Comparison.csv'));

%% =========================================
% STEP 7: Plot MATLAB vs Simulink SNR
% ==========================================

figure('Color','w', ...
    'Position',[100 100 900 500]);

% Exclude infinite SNR from plotting
valid = isfinite(SNR_MAT) & isfinite(SNR_SIM);

plot(bitDepths(valid), ...
    SNR_MAT(valid), ...
    'bo-', ...
    'LineWidth',1.5, ...
    'MarkerSize',8);

hold on;

plot(bitDepths(valid), ...
    SNR_SIM(valid), ...
    'rx--', ...
    'LineWidth',1.5, ...
    'MarkerSize',8);

grid on;

xlabel('Effective Bit Depth');
ylabel('SNR (dB)');

title('MATLAB vs Simulink Quantization SNR');

legend('MATLAB','Simulink', ...
    'Location','best');

xticks([2 4 8 16]);

% Save figure
saveas(gcf, ...
    fullfile(outputFolder, ...
    'MATLAB_Simulink_SNR.png'));

%% =========================================
% STEP 8: Plot MATLAB vs Simulink MSE
% ==========================================

figure('Color','w', ...
    'Position',[100 100 900 500]);

plot(bitDepths, ...
    MSE_MAT, ...
    'bo-', ...
    'LineWidth',1.5);

hold on;

plot(bitDepths, ...
    MSE_SIM, ...
    'rx--', ...
    'LineWidth',1.5);

grid on;

xlabel('Effective Bit Depth');
ylabel('Mean Squared Error');

title('MATLAB vs Simulink Quantization MSE');

legend('MATLAB','Simulink', ...
    'Location','best');

xticks([2 4 8 16]);

saveas(gcf, ...
    fullfile(outputFolder, ...
    'MATLAB_Simulink_MSE.png'));

%% =========================================
% STEP 9: Final verification
% ==========================================

allMatched = all(MaxDifference < 1e-12) && ...
    all(MaxTimeDifference < 1e-8);

fprintf('\n=====================================\n');

if allMatched
    fprintf('SUCCESS: ALL FOUR CASES MATCH!\n');
else
    fprintf('WARNING: SOME CASES DID NOT MATCH.\n');
end

fprintf('=====================================\n');

fprintf('Results saved in:\n%s\n', outputFolder);

fprintf('\nFull-length Simulink experiment completed!\n');
