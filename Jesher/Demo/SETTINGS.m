function settings = SETTINGS()
% SETTINGS: these are the only settings to edit for the live demonstration.
demoFolder = fileparts(mfilename('fullpath'));
projectFolder = fileparts(fileparts(demoFolder));

settings.audioFile = fullfile(projectFolder,'Audios','SpeechMusic.wav');
settings.targetFs = 22050;       % 44100, 22050, 11025, 8000 or 4000 Hz
settings.bits = 8;              % 16 (control), 8, 4 or 2 effective bits
settings.filterMode = 'lpf';    % 'lpf' or 'none'; native rate uses 'native'

settings.outputFolder = fullfile(demoFolder,'Results');
end
