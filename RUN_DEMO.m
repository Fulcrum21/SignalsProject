%% One combined case for the live demonstration.
% Run RUN_PROJECT once first. Edit PROJECT_SETTINGS to select the case.
projectRoot = fileparts(mfilename('fullpath'));
addpath(fullfile(projectRoot,'Matlab'),fullfile(projectRoot,'Jesher','matlab'));
settings = PROJECT_SETTINGS();
demoResult = Run_Combined_Demo(settings);
disp(demoResult);
fprintf('Processing array: NMSE %.9g, SNR %.4f dB\n', ...
    demoResult.processingNMSE,demoResult.processingSNRdB);
fprintf('Exported WAV:     NMSE %.9g, SNR %.4f dB\n', ...
    demoResult.exportedNMSE,demoResult.exportedSNRdB);
% Simulink users can inspect the visible arithmetic and run it again.
if strcmp(settings.platform,'simulink'), open_system('Khaled_Quantizer_Model'); end
