function wav = exportVerifiedWav(samples, Fs, path)
%EXPORTVERIFIEDWAV Write and re-import a mono 16-bit PCM WAV at its actual rate.
% Effective quantizer bits belong in the case metadata, separately from this
% carrier width. No independent normalization or silent clipping is allowed.

if ~isa(samples, 'double') || ~isreal(samples) || isempty(samples) || ...
        ~iscolumn(samples) || any(~isfinite(samples))
    error('jesher:InvalidSamples', ...
        'WAV samples must be a nonempty, finite, real double mono column.');
end
if ~isnumeric(Fs) || ~isreal(Fs) || ~isscalar(Fs) || ...
        ~isfinite(Fs) || Fs <= 0 || Fs ~= fix(Fs)
    error('jesher:InvalidRate', 'The WAV sample rate must be a positive integer in Hz.');
end
if ~(ischar(path) && isrow(path) && ~isempty(path)) && ...
        ~(isstring(path) && isscalar(path) && strlength(path) > 0)
    error('jesher:InvalidWavPath', 'Supply a nonempty WAV file path.');
end
path = char(path);
[folder, name, extension] = fileparts(path);
if ~strcmpi(extension, '.wav')
    error('jesher:InvalidWavPath', 'The export filename must end in .wav.');
end
pcmStep = 1 / 32768;
if any(samples < -1 | samples > 1 - pcmStep)
    error('jesher:WavRangeExceeded', ...
        ['16-bit PCM export requires samples in [-1, 1-1/32768]. ' ...
        'Resolve overshoot explicitly; the exporter will not normalize or clip.']);
end
if ~isempty(folder) && ~isfolder(folder)
    mkdir(folder);
end
audiowrite(path, samples, Fs, 'BitsPerSample', 16);
info = audioinfo(path);
[reimported, reimportedFs] = audioread(path);
if reimportedFs ~= Fs || info.SampleRate ~= Fs || ...
        info.NumChannels ~= 1 || info.TotalSamples ~= numel(samples) || ...
        info.BitsPerSample ~= 16 || ~isequal(size(reimported), size(samples))
    error('jesher:WavMetadataMismatch', ...
        'The re-imported WAV rate, count, channels, or carrier width differs from the export.');
end
roundTripError = reimported - samples;
maxError = max(abs(roundTripError));
% MATLAB PCM conversion can differ by almost one LSB; do not assume a
% half-LSB rounding convention. Reject any larger unexplained alteration.
if maxError > pcmStep + 8 * eps(1)
    error('jesher:WavRoundTripMismatch', ...
        'WAV round-trip error exceeds one 16-bit PCM step.');
end
file = dir(path);
wav = struct('filename', [name extension], 'containerBits', info.BitsPerSample, ...
    'fileBytes', file.bytes, 'sampleCount', info.TotalSamples, ...
    'durationSeconds', info.TotalSamples / info.SampleRate, ...
    'maxAbsRoundTripError', maxError, ...
    'rmsRoundTripError', sqrt(mean(roundTripError .^ 2)), ...
    'clippedSamples', 0);
end
