%% Run one complete case in MATLAB. Edit SETTINGS.m first if desired.
demoFolder = fileparts(mfilename('fullpath'));
addpath(demoFolder);
settings = SETTINGS();
[result, processed] = run_case('matlab',settings,true);
disp(struct2table(result));
writetable(struct2table(result),fullfile(settings.outputFolder,'last_case.csv'));
fprintf('\nWAV: %s\n',result.WavFile);
fprintf('NMSE and SNR above describe the EXPORTED WAV compared at the original rate.\n');
