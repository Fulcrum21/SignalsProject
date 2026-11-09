function Check_Quantizer()
% Independent expected boundary values, not just a copy of the quantizer code.
for bits=[8 4 2]
    d=2/2^bits;
    input=[-2;-1;-d/2;0;d/2;1-d;1;2];
    expected=[-1;-1;-d;0;d;1-d;1-d;1-d];
    [actual,errorSignal,q]=Uniform_Quantize(input,bits);
    assert(isequal(actual,expected),'Signed levels, half ties or saturation failed.');
    assert(isequal(errorSignal,input-expected) && q.saturatedSamples==3);
    [simulated,simError]=Quantize_Simulink(input,bits);
    assert(isequal(simulated,expected) && isequal(simError,errorSignal));
    % Sweep the range and verify the available levels without audio assumptions.
    sweep=linspace(-1,1,10001)';
    y=Uniform_Quantize(sweep,bits);
    assert(numel(unique(y))==2^bits && all(y>=-1 & y<=1-d));
end
input=[-2;-0.123;0;0.123;2];
assert(isequal(Uniform_Quantize(input,16),input),'16-bit bypass changed the input.');
assert(isequal(Quantize_Simulink(input,16),input),'Simulink control bypass failed.');
% Metric sanity checks: identical input, known error energy, and silence.
m=jesher.computeMetrics([1;1],[1;1]); assert(m.nmse==0 && isinf(m.snrDb));
m=jesher.computeMetrics([1;1],[0;0]); assert(m.nmse==1 && m.snrDb==0);
m=jesher.computeMetrics([0;0],[0;0]); assert(isnan(m.nmse) && isnan(m.snrDb));
fprintf('PASS: quantizer boundary, half-tie, saturation, level-count, bypass and metric checks.\n');
end
