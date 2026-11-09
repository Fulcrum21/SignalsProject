
function [xq, e] = Khaled_Quantizer(x, B)
% Uniform signed quantization
% x  : input audio samples
% B  : effective quantizer bits
% xq : quantized samples
% e  : quantization error

assert(ismember(B, [16 8 4 2]), ...
    'Bit depth must be 16, 8, 4, or 2');

assert(all(isfinite(x(:))), ...
    'Samples must be finite');

% Preserve the original 16-bit reference
if B == 16
    xq = x;
else
    % Quantization step
    delta = 2 / (2^B);

    % Round to nearest integer index
    index = round(x / delta);

    % Saturate indices to the allowed range
    minIndex = -2^(B-1);
    maxIndex = 2^(B-1) - 1;
    index = min(max(index, minIndex), maxIndex);

    % Convert indices back to amplitudes
    xq = index * delta;
end

% Quantization error
e = x - xq;

end
