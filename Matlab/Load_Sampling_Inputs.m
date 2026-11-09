function inputs = Load_Sampling_Inputs()
% Load exact arrays and timing metadata supplied by Abdulrahman, not WAV copies.
% Jesher's adapter checks the original recording and preserves the MATLAB data.
root = fileparts(fileparts(mfilename('fullpath')));
addpath(fullfile(root,'Jesher','matlab'));
matlabFile = fullfile(root,'Results','Abdulrahman','Sampling','sampling_all_rates.mat');
simulinkFile = fullfile(root,'Results','Abdulrahman','Sampling','simulink_cases.mat');
assert(isfile(matlabFile) && isfile(simulinkFile),'Run RUN_PROJECT to prepare sampling first.');
[inputs,reference,Fs] = jesher.loadAvailableCases(root,{matlabFile,simulinkFile});
% The adapter supplies the unchanged MATLAB reference. Pass the same reference
% through the Simulink quantizer's bypass for the matching native control.
native = inputs(strcmp({inputs.caseId},'speechmusic_fs44100_b16_native_matlab'));
native.platform = 'simulink';
native.caseId = 'speechmusic_fs44100_b16_native_simulink';
native.samples = reference;
native.Fs = Fs;
native.provenance = 'Original recording; unchanged native reference input.';
native.alignmentPolicy = 'full_record_resample_v1';
inputs(end+1,1) = native;
% Normalize description conventions only. No sample or timing changes here.
for k=1:numel(inputs)
    inputs(k).alignmentPolicy = 'full_record_resample_v1';
    if inputs(k).Fs==Fs, inputs(k).processingStage='native_reference';
    else, inputs(k).processingStage='sampling_only_control'; end
end
assert(numel(inputs)==18 && numel(unique(string({inputs.caseId})))==18, ...
    'Expected 9 sampling routes per platform, with unique identities.');
end
