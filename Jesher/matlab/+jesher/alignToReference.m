function [aligned, alignment] = alignToReference(reference, referenceFs, c)
%ALIGNTOREFERENCE Reconstruct onto the full original 44.1 kHz sample grid.
% AA-03 authorizes the native and 22.05 kHz routes. Other contract rates must
% carry an explicit full_record_resample_v1 policy from their owner. Both
% policies retain FIR/reconstruction edge effects and apply no lag search,
% amplitude normalization, or further delay correction.

validateSamples(reference, 'reference');
validateRate(referenceFs, 'referenceFs');
required = {'samples', 'Fs', 'firstSampleTimeSeconds', ...
    'delayCompensated', 'normalizationApplied', 'alignmentPolicy'};
if ~isstruct(c) || ~isscalar(c) || ~all(isfield(c, required))
    error('jesher:MissingAlignmentMetadata', ...
        'The case must supply samples, rate, start time, delay, normalization, and alignment policy.');
end
validateSamples(c.samples, 'case samples');
validateRate(c.Fs, 'case Fs');
if referenceFs ~= 44100
    error('jesher:UnsupportedReferenceRate', ...
        'The shared experiment uses the original 44100 Hz reference.');
end
if ~isnumeric(c.firstSampleTimeSeconds) || ~isreal(c.firstSampleTimeSeconds) || ...
        ~isscalar(c.firstSampleTimeSeconds) || ...
        ~isfinite(c.firstSampleTimeSeconds) || c.firstSampleTimeSeconds ~= 0
    error('jesher:UnsupportedStartTime', ...
        'The full-record policy requires an exact t=0 first sample.');
end
if ~islogical(c.delayCompensated) || ~isscalar(c.delayCompensated) || ...
        ~c.delayCompensated
    error('jesher:UncompensatedDelay', ...
        'Supply delay-compensated arrays and logical delayCompensated=true.');
end
if ~islogical(c.normalizationApplied) || ...
        ~isscalar(c.normalizationApplied) || c.normalizationApplied
    error('jesher:NormalizationNotAllowed', ...
        'Case amplitudes must be preserved, with logical normalizationApplied=false.');
end
if ~(ischar(c.alignmentPolicy) && isrow(c.alignmentPolicy)) && ...
        ~(isstring(c.alignmentPolicy) && isscalar(c.alignmentPolicy))
    error('jesher:UnsupportedAlignmentPolicy', ...
        'alignmentPolicy must name an explicitly documented policy.');
end
policy = char(c.alignmentPolicy);
switch policy
    case 'aa03_full_record_v1'
        allowedRates = [44100, 22050];
    case 'full_record_resample_v1'
        allowedRates = [44100, 22050, 11025, 8000, 4000];
    otherwise
        error('jesher:UnsupportedAlignmentPolicy', ...
            'Unknown alignment policy: %s.', policy);
end
if ~ismember(c.Fs, allowedRates)
    error('jesher:UnsupportedCaseRate', ...
        'This sampling rate is not covered by the supplied alignment policy.');
end

% This count follows a t=0 grid with the full recording duration. It rejects
% missing samples and surplus logged frames before reconstruction begins.
commonDivisor = gcd(referenceFs, c.Fs);
p = referenceFs / commonDivisor;
q = c.Fs / commonDivisor;
referenceCount = numel(reference);
expectedCount = ceil(referenceCount * q / p);
if numel(c.samples) ~= expectedCount
    error('jesher:UnexpectedCaseLength', ...
        'Expected %d samples at %g Hz for this recording, received %d.', ...
        expectedCount, c.Fs, numel(c.samples));
end
lastReferenceTime = (referenceCount - 1) / referenceFs;
lastCaseTime = (expectedCount - 1) / c.Fs;
% The last original time must fall before the next processed sample time.
% It may follow the last processed sample: resample supplies its documented
% boundary reconstruction, and the resulting edge error remains measured.
if lastReferenceTime >= lastCaseTime + 1 / c.Fs + 8 * eps(max(1, lastReferenceTime))
    error('jesher:InsufficientTimeCoverage', ...
        'The processed recording does not cover the original time interval.');
end

if c.Fs == referenceFs
    reconstructed = c.samples;
    method = 'native samples; no reconstruction';
else
    % Match AA-03 and MATLAB resample defaults explicitly: n=10, beta=5.
    reconstructed = resample(c.samples, p, q, 10, 5);
    method = sprintf('resample(samples,%d,%d,10,5); retain first referenceCount samples', p, q);
end
reconstructedCount = numel(reconstructed);
expectedReconstructedCount = ceil(expectedCount * p / q);
surplus = reconstructedCount - referenceCount;
maximumRoundingSurplus = ceil(p / q) - 1;
if reconstructedCount ~= expectedReconstructedCount || ...
        surplus < 0 || surplus > maximumRoundingSurplus
    error('jesher:UnexpectedReconstructionLength', ...
        'Reconstruction length does not match the documented grid-rounding rule.');
end
% Only rational-grid endpoint rounding is discarded, never unrelated samples.
aligned = reconstructed(1:referenceCount);
alignment = struct('policy', policy, 'method', method, ...
    'firstTimeSeconds', 0, 'lastTimeSeconds', lastReferenceTime, ...
    'sampleCount', referenceCount, ...
    'reconstructedSampleCount', reconstructedCount, ...
    'discardedEndpointSamples', surplus);
end

function validateSamples(samples, name)
if ~isa(samples, 'double') || ~isreal(samples) || isempty(samples) || ...
        ~iscolumn(samples) || any(~isfinite(samples))
    error('jesher:InvalidSamples', ...
        '%s must be a nonempty, finite, real double mono column.', name);
end
end

function validateRate(rate, name)
if ~isnumeric(rate) || ~isreal(rate) || ~isscalar(rate) || ...
        ~isfinite(rate) || rate <= 0 || rate ~= fix(rate)
    error('jesher:InvalidRate', '%s must be a positive integer in Hz.', name);
end
end
