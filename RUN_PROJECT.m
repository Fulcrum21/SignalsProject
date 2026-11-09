%% Run the combined course project from the repository root.
% Sampling: Abdulrahman's scripts and FOUR real sampling models.
% Quantization: the new Khaled stage, in MATLAB and real Simulink blocks.
% Evaluation: Jesher's existing NMSE/SNR, verified WAV export and audio ZIP.
% Nothing plays automatically. Run PLAY_PROJECT_AUDIO when ready to listen.
projectRoot = fileparts(mfilename('fullpath'));
cd(projectRoot);
addpath(fullfile(projectRoot,'Matlab'), fullfile(projectRoot,'Jesher','matlab'));

%% 1. Re-run MATLAB sampling, including the original 22.05 kHz prototype.
% These are scripts: keep their variables available for the sampling models.
cd(fullfile(projectRoot,'Matlab'));
Sampling_Abdulrahman
Prepare_Sampling_Handoff
close all; % Close the sampling figures after saving their report copies.

%% 2. Run Abdulrahman's four saved Simulink models, not a replacement model.
cd(projectRoot);
Compare_All_Sampling

%% 3. Apply 16/8/4/2-bit settings to the ACTUAL sampling outputs.
% Native 44.1 kHz cases use the original recording. There are 72 cases total.
handoffFile = Quantize_All_Cases();

%% 4. Reuse Jesher's evaluator. A new folder prevents mixing different runs.
runName = ['run_' char(datetime('now','Format','yyyyMMdd_HHmmss_SSS'))];
evaluationFolder = fullfile(projectRoot,'Results','Integrated',runName);
summary = Run_Jesher_Evaluation('HandoffFiles',{handoffFile}, ...
    'OutputFolder',evaluationFolder,'RequireComplete',true,'MakePlots',false);

%% 5. Storage, representative report figures and integration checks.
Make_Integrated_Results(evaluationFolder,handoffFile);
CHECK_INTEGRATION(evaluationFolder,handoffFile);
Write_Integrated_Report(evaluationFolder);
fid = fopen(fullfile(projectRoot,'Results','Integrated','latest_run.txt'),'w');
assert(fid>=0,'Cannot save the latest run location.');
fprintf(fid,'%s\n',runName); fclose(fid);
fprintf('\nCOMPLETE: 72 cases, actual sampling models, quantization, metrics and WAVs.\n');
fprintf('Results: %s\nRun RUN_DEMO for a single case; PLAY_PROJECT_AUDIO for listening.\n',evaluationFolder);
