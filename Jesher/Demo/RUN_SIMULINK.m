%% Run the same settings through actual Simulink blocks, then export/evaluate.
demoFolder = fileparts(mfilename('fullpath'));
addpath(demoFolder);
settings = SETTINGS();
[result, processed] = run_case('simulink',settings,true);
disp(struct2table(result));
writetable(struct2table(result),fullfile(settings.outputFolder,'last_case.csv'));
open_system(fullfile(demoFolder,'Audio_Demo.slx'));
fprintf('\nWAV: %s\n',result.WavFile);
fprintf('Open the Sampling, Quantization and Reconstruction subsystems to explain them.\n');
