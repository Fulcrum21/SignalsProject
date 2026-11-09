function [quantized,errorSignal] = Quantize_Simulink(samples,bits)
% Simulink performs the arithmetic. MATLAB only sets inputs and reads outputs.
root = fileparts(fileparts(mfilename('fullpath')));
model='Quantization_Khaled';
if ~isfile(fullfile(root,'Simulink',[model '.slx'])), Build_Quantization_Model(); end
load_system(fullfile(root,'Simulink',[model '.slx']));
Setup_Quantization_Model(samples,bits);
out=sim(model);
quantized=out.quantizedSamples(:);
errorSignal=out.quantizationError(:);
assert(isequal(size(samples),size(quantized)) && isequal(errorSignal,samples-quantized), ...
    'Quantization must preserve sample count and report input minus output.');
end
