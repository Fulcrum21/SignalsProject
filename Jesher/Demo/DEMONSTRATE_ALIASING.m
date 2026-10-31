%% Optional known-tone example: 10 kHz folds to 2 kHz when sampled at 8 kHz.
demoFolder=fileparts(mfilename('fullpath')); addpath(demoFolder);
settings=SETTINGS();
settings.audioFile=fullfile(fileparts(fileparts(demoFolder)),'Audios','10kHz_Sine.wav');
settings.targetFs=8000; settings.bits=16;
settings.outputFolder=fullfile(demoFolder,'Results','Aliasing');
settings.filterMode='none';
[unfiltered,~]=run_case('matlab',settings,true);
settings.filterMode='lpf';
[filtered,~]=run_case('matlab',settings,true);
[u,Fs]=audioread(unfiltered.WavFile);
[f,~]=audioread(filtered.WavFile);
% Remove only a short edge region for this tone peak measurement, NOT for NMSE.
keep=round(0.1*Fs)+1:numel(u)-round(0.1*Fs);
amplitude=abs(fft(u(keep))); half=amplitude(1:floor(numel(keep)/2)+1);
[~,bin]=max(half(2:end)); measuredPeak=bin*Fs/numel(keep);
if norm(f(keep))==0
    suppressionDb=Inf; % Below the PCM16 output floor, not infinite acoustic attenuation.
else
    suppressionDb=20*log10(norm(u(keep))/norm(f(keep)));
end
fprintf('Theoretical alias: |10000 - 8000| = 2000 Hz.\n');
fprintf('Measured dominant unfiltered output frequency: %.3f Hz.\n',measuredPeak);
fprintf('Filtered-output RMS reduction versus unfiltered: %.3f dB.\n',suppressionDb);
writetable(table(measuredPeak,suppressionDb),fullfile(settings.outputFolder,'tone_check.csv'));
result=unfiltered; % PLAY_AUDIO now compares this tone with its aliased output.
