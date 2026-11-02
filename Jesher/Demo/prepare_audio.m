function data = prepare_audio(settings)
%% Read the source and check the experiment settings.
[x,Fs] = audioread(settings.audioFile);
if size(x,2)>1, x = mean(x,2); end  % Explicit stereo-to-mono policy.
assert(~isempty(x) && all(isfinite(x)),'Source must contain finite audio samples.');
assert(ismember(settings.bits,[16 8 4 2]),'Choose 16, 8, 4 or 2 bits.');
assert(settings.targetFs>0 && settings.targetFs<=Fs && ...
    fix(settings.targetFs)==settings.targetFs,'Target rate must be an integer no higher than the source rate.');
assert(ismember(string(settings.filterMode),["native","lpf","none"]),'Unknown filter mode.');
data.x = x(:); data.Fs = Fs; data.N = numel(x);
data.mode = char(settings.filterMode);
if settings.targetFs == Fs
    data.mode = 'native';
else
    assert(~strcmp(data.mode,'native'),'Use lpf or none below the source rate.');
end
g = gcd(Fs,settings.targetFs);
data.p = settings.targetFs/g; data.q = Fs/g;
%% Use Abdulrahman's source-covered output times and unfiltered method.
data.originalTime = (0:data.N-1)'/Fs;
data.outputCount = floor((data.N-1)*settings.targetFs/Fs)+1;
data.outputTime = (0:data.outputCount-1)'/settings.targetFs;
if data.p==1
    data.lowerIndices = (1:data.q:data.N)';
    data.upperIndices = data.lowerIndices;
    data.interpolationWeight = zeros(data.outputCount,1);
    data.samplingMethod = sprintf('Direct sample selection x(1:%d:end); no anti-aliasing LPF.',data.q);
else
    % Simulink calculates low + weight*(high-low) from the source itself.
    data.lowerIndices = min(data.N-1,1+floor(data.outputTime*Fs));
    data.upperIndices = data.lowerIndices+1;
    lowerTime = data.originalTime(data.lowerIndices);
    upperTime = data.originalTime(data.upperIndices);
    data.interpolationWeight = (data.outputTime-lowerTime)./(upperTime-lowerTime);
    data.samplingMethod = 'Linear interpolation at uniform output times; no anti-aliasing LPF.';
end
if strcmp(data.mode,'lpf')
    data.samplingMethod = 'resample(x,p,q,10,5); retain source-covered output times; FIR delay already compensated.';
elseif strcmp(data.mode,'native')
    data.samplingMethod = 'Native original sample grid, unchanged.';
end
%% Prepare FIR parameters for actual Simulink rate-conversion blocks.
if data.p == data.q
    % Identity-delay filters keep the diagram valid; the native path bypasses them.
    h = [0 1 0]; reconstruction = [0 1 0];
else
    [~,h] = resample(zeros(max(data.q,4),1),data.p,data.q,10,5);
    [~,reconstruction] = resample(zeros(max(data.p,4),1),data.q,data.p,10,5);
end
data.h = h(:)';
data.filterDelay = (numel(h)-1)/(2*data.q);
assert(data.filterDelay==fix(data.filterDelay),'Unexpected fractional sampling-filter delay.');
% Add known zero tail and make input-frame length divisible by decimation q.
frameLength = data.q*ceil(data.N/data.q)+20*data.q;
data.inputFrame = [data.x; zeros(frameLength-data.N,1)];
data.filteredIndices = data.filterDelay+(1:data.outputCount)';
% Polyphase phase padding matches resample's time origin for noninteger ratios.
halfLength = (numel(reconstruction)-1)/2;
leadingZeros = mod(-halfLength,data.p);
data.reconstructionH = [zeros(1,leadingZeros),reconstruction(:)'];
data.reconstructionDelay = (halfLength+leadingZeros)/data.p;
reconstructionLength = data.p*ceil(data.outputCount/data.p)+20*data.p;
data.reconstructionTail = zeros(reconstructionLength-data.outputCount,1);
data.referenceIndices = data.reconstructionDelay+(1:data.N)';
data.quantStep = 2/2^settings.bits;
data.quantMin = -2^(settings.bits-1);
data.quantMax = 2^(settings.bits-1)-1;
end
