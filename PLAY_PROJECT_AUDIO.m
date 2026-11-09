%% Play the original and the most recent RUN_DEMO export at their actual rates.
% Start this script deliberately with the laptop speaker volume set by you.
projectRoot = fileparts(mfilename('fullpath'));
playbackSettings = PROJECT_SETTINGS();
playAllCases = playbackSettings.playAllCases; % Full matrix takes about 25 min.
if ~playAllCases, assert(exist('demoResult','var')==1,'Run RUN_DEMO first.'); end
[original,originalFs] = audioread(fullfile(projectRoot,'Audios','SpeechMusic.wav'));
fprintf('Playing the original recording.\n');
playblocking(audioplayer(original,originalFs));
if playAllCases
    runName=strtrim(fileread(fullfile(projectRoot,'Results','Integrated','latest_run.txt')));
    folder=fullfile(projectRoot,'Results','Integrated',runName);
    files=readtable(fullfile(folder,'metrics.csv'),'TextType','string');
    for k=1:height(files)
        fprintf('%d/%d: %s\n',k,height(files),files.caseId(k));
        [processed,processedFs]=audioread(fullfile(folder,'audio_package',char(files.wavFile(k))));
        pause(0.5); playblocking(audioplayer(processed,processedFs));
    end
else
    [processed,processedFs]=audioread(demoResult.wavFile);
    fprintf('Processed: %s\n',demoResult.caseId);
    pause(0.5); playblocking(audioplayer(processed,processedFs));
end
% Describe only what you actually hear; plots do not establish listening results.
