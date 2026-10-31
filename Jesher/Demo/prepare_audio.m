function data = prepare_audio(settings)
% Load source and prepare timing/filter parameters, not processed audio.
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
data.outputCount = ceil(data.N*data.p/data.q);
% Nearest-source-time selection, with NO prefilter, for arbitrary rate ratios.
data.directIndices = min(data.N,1+round((0:data.outputCount-1)'*data.q/data.p));
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
