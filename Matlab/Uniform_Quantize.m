function [quantized,errorSignal,settings] = Uniform_Quantize(samples,bits)
%UNIFORM_QUANTIZE Signed uniform midtread quantizer with a fixed [-1,1) range.
% No normalization or time/rate changes. For B bits, delta = 2/2^B.
% Round ties away from zero, saturate the integer index, then multiply by delta.
% Example: 2-bit output levels are -1, -0.5, 0, 0.5.
% 16 is deliberately a bypass control, not another quantization operation.
assert(isa(samples,'double') && isreal(samples) && iscolumn(samples) && ...
    ~isempty(samples) && all(isfinite(samples)),'Use a finite mono double column.');
assert(isscalar(bits) && ismember(bits,[16 8 4 2]),'Choose 16, 8, 4 or 2 bits.');
settings.bits = bits;
settings.applied = bits<16;
settings.step = 2/2^bits;
settings.minimumIndex = -2^(bits-1);
settings.maximumIndex = 2^(bits-1)-1;
settings.rounding = 'nearest integer; exact half ties away from zero';
settings.range = '[-1,1); signed midtread levels; saturate after rounding';
settings.saturatedSamples = 0;
if bits==16
    quantized = samples;
else
    index = round(samples/settings.step);
    limited = min(max(index,settings.minimumIndex),settings.maximumIndex);
    settings.saturatedSamples = nnz(index~=limited);
    quantized = limited*settings.step;
end
errorSignal = samples-quantized; % SAME sampling grid: quantization error only.
end
