function info = Play_Jesher_Case(wavFile, volumeGain, startSeconds, durationSeconds)
%PLAY_JESHER_CASE Play a WAV at its actual rate without case normalization.
% Call explicitly; the batch evaluation never starts audio automatically.
% Example from the repository root after adding Jesher/matlab to the path:
%   info = Play_Jesher_Case('Audios/SpeechMusic.wav', 0.5, 0, 20);
% Keep volumeGain, operating-system volume, device, and excerpt times fixed
% across the listening session. Stream completion does not establish that a
% human heard the audio; record that check in playback_checks_template.csv.

if nargin < 2, volumeGain = 0.5; end
if nargin < 3, startSeconds = 0; end
if nargin < 4, durationSeconds = Inf; end
validateattributes(volumeGain, {'numeric'}, ...
    {'real','finite','scalar','>',0,'<=',1});
validateattributes(startSeconds, {'numeric'}, ...
    {'real','finite','scalar','nonnegative'});
validateattributes(durationSeconds, {'numeric'}, {'real','scalar','positive'});
if ~(ischar(wavFile) || (isstring(wavFile) && isscalar(wavFile)))
    error('Jesher:InvalidPath', 'wavFile must be one file path.');
end
wavFile = char(wavFile);
[~, ~, extension] = fileparts(wavFile);
if ~strcmpi(extension, '.wav') || ~isfile(wavFile)
    error('Jesher:InvalidPath', 'Select an existing WAV file.');
end

header = audioinfo(wavFile);
[samples, Fs] = audioread(wavFile);
validateattributes(samples, {'double'}, {'real','finite','column','nonempty'});
if header.NumChannels ~= 1 || header.SampleRate ~= Fs
    error('Jesher:InvalidAudio', 'Expected a mono WAV with a consistent rate.');
end
firstIndex = floor(startSeconds * Fs) + 1;
if firstIndex > numel(samples)
    error('Jesher:InvalidExcerpt', 'The excerpt starts after the recording.');
end
if isinf(durationSeconds)
    lastIndex = numel(samples);
else
    excerptCount = floor(durationSeconds * Fs);
    if excerptCount < 1
        error('Jesher:InvalidExcerpt', 'The excerpt must contain a sample.');
    end
    lastIndex = min(numel(samples), firstIndex + excerptCount - 1);
end
excerpt = samples(firstIndex:lastIndex) * volumeGain;
if max(abs(excerpt)) > 1
    error('Jesher:PlaybackClipping', 'Playback gain would exceed full scale.');
end

fprintf('Playing %s\n', wavFile);
fprintf('%d Hz; %d source samples; %.9f s; fixed gain %.3f\n', ...
    Fs, numel(samples), numel(samples)/Fs, volumeGain);
fprintf('Excerpt %.9f to %.9f s (end exclusive).\n', ...
    (firstIndex-1)/Fs, lastIndex/Fs);
player = audioplayer(excerpt, Fs, 16);
playblocking(player);

info = struct('wavFile', wavFile, 'sampleRateHz', Fs, ...
    'sourceSampleCount', numel(samples), ...
    'sourceDurationSeconds', numel(samples)/Fs, ...
    'excerptStartSeconds', (firstIndex-1)/Fs, ...
    'excerptEndExclusiveSeconds', lastIndex/Fs, ...
    'excerptSampleCount', numel(excerpt), 'volumeGain', volumeGain, ...
    'streamCompleted', true, 'speakerCheckStatus', 'human_check_required');
end
