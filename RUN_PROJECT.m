%% Run the combined course project from the repository root.
% Sampling: Abdulrahman's scripts and FOUR real sampling models.
% Quantization: Khaled's published script and Khaled_Quantizer_Model.slx.
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

%% 3. Run Khaled's own 72-case producer without clearing this script's workspace.
Run_Khaled_Handoff();

%% 4. Jesher evaluates those exact handoffs, exports WAVs and writes the report.
RUN_JESHER
