%% Small checks you can show without a testing framework.
demoFolder=fileparts(mfilename('fullpath')); addpath(demoFolder);
x=[-0.5;0;0.25;0.75];
[nmse,snrDb]=quality_metrics(x,x);
assert(nmse==0 && snrDb==Inf);
[nmse,snrDb]=quality_metrics(x,x/2);
assert(abs(nmse-0.25)<1e-14 && abs(snrDb-10*log10(4))<1e-12);
[nmse,snrDb]=quality_metrics(zeros(4,1),zeros(4,1));
assert(isnan(nmse) && isnan(snrDb));
[nmse,snrDb]=quality_metrics(zeros(4,1),ones(4,1));
assert(nmse==Inf && snrDb==-Inf);
for bits=[8 4 2]
    step=2/2^bits;
    values=[-1.1;-1;-step/2;0;step/2;1;1.1];
    indices=min(2^(bits-1)-1,max(-2^(bits-1),round(values/step)));
    quantized=indices*step;
    assert(all(quantized>=-1 & quantized<=1-step));
    assert(quantized(4)==0 && quantized(3)==-step && quantized(5)==step);
end
fprintf('Metric identity, predictable error, silence and quantizer boundaries passed.\n');
