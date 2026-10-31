function metrics = computeMetrics(reference, processed)
%COMPUTEMETRICS Compare finite, already aligned mono double sample columns.
% Both arrays must describe the same physical sample times. Alignment is a
% separate operation; this function never truncates, shifts, or normalizes.

validateSamples(reference, 'reference');
validateSamples(processed, 'processed');
if ~isequal(size(reference), size(processed))
    error('jesher:UnequalLengths', ...
        'Aligned reference and processed arrays must have identical sizes.');
end

errorSignal = reference - processed;
referenceEnergy = sum(reference .^ 2);
errorEnergy = sum(errorSignal .^ 2);
if ~isfinite(referenceEnergy) || ~isfinite(errorEnergy)
    error('jesher:NonfiniteEnergy', ...
        'Energy overflow occurred; check the input sample magnitudes.');
end

if referenceEnergy == 0
    if errorEnergy == 0
        nmse = NaN;
        snrDb = NaN;
        status = 'zero_reference_silence';
    else
        nmse = Inf;
        snrDb = -Inf;
        status = 'zero_reference_error';
    end
elseif errorEnergy == 0
    nmse = 0;
    snrDb = Inf;
    status = 'unchanged';
else
    nmse = errorEnergy / referenceEnergy;
    % Log energies separately to avoid overflowing their quotient.
    snrDb = 10 * (log10(referenceEnergy) - log10(errorEnergy));
    status = 'finite';
end

metrics = struct('nmse', nmse, 'snrDb', snrDb, ...
    'referenceEnergy', referenceEnergy, 'errorEnergy', errorEnergy, ...
    'sampleCount', numel(reference), 'status', status);
end

function validateSamples(samples, name)
if ~isa(samples, 'double') || ~isreal(samples) || isempty(samples) || ...
        ~iscolumn(samples) || any(~isfinite(samples))
    error('jesher:InvalidSamples', ...
        '%s must be a nonempty, finite, real double mono column.', name);
end
end
