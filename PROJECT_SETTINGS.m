function settings = PROJECT_SETTINGS()
% Edit these settings before running RUN_DEMO from the project root.
settings.Fs = 22050;          % 44100, 22050, 11025, 8000 or 4000 Hz
settings.bits = 8;            % 16 = unchanged sampling control; or 8, 4, 2
settings.filterMode = 'lpf';   % 'lpf' or 'none'; 44100 Hz uses 'native'
settings.platform = 'simulink'; % 'matlab' or 'simulink'
settings.playAllCases = false; % PLAY_PROJECT_AUDIO: true plays all 72 outputs.
end
