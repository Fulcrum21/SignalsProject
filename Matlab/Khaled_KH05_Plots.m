%% Khaled_KH05_Plots.m
% CCEN 302 - KH-05 quantization and combined processing figures
% Loads the verified KH-04 output arrays; does NOT rerun Simulink.
%
% Input files (produced by Khaled_KH04_All_Cases.m):
%   Results/Khaled/Combined/KH04_MATLAB_Cases.mat
%   Results/Khaled/Combined/KH04_Simulink_Cases.mat
%   Results/Khaled/Combined/KH04_Comparison_Manifest.csv
%
% Figures:
%   1. Native-rate original vs 8, 4, and 2 bits (6 views per bit depth)
%   2. Native-rate MATLAB vs Simulink waveform comparison
%   3. Representative combined case: 8000 Hz, LPF, 4 bits (6 views)
%   4. Combined-case MATLAB vs Simulink difference
%   5. Diagnostic for the 8000 Hz unfiltered 4-bit threshold mismatch
%
% No Signal Processing Toolbox required: spectrogram uses a manual FFT/STFT.
% All comparisons use stored DOUBLE arrays, not separately exported WAVs.

clc;
close all;

%% 1. Paths and input checks
scriptFolder = fileparts(mfilename('fullpath'));
root = fileparts(scriptFolder);
inFolder = fullfile(root,'Results','Khaled','Combined');
outFolder = fullfile(root,'Results','Khaled','Figures');
if ~exist(outFolder,'dir'), mkdir(outFolder); end

matFile = fullfile(inFolder,'KH04_MATLAB_Cases.mat');
simFile = fullfile(inFolder,'KH04_Simulink_Cases.mat');
manifestFile = fullfile(inFolder,'KH04_Comparison_Manifest.csv');
assert(isfile(matFile) && isfile(simFile), ...
    'KH-04 MAT handoff files not found. Run Khaled_KH04_All_Cases.m first.');
assert(isfile(manifestFile), 'KH-04 comparison manifest missing.');

M = load(matFile,'cases');
S = load(simFile,'cases');
matCases = M.cases;
simCases = S.cases;
assert(numel(matCases)==36 && numel(simCases)==36, ...
    'Expected 36 MATLAB and 36 Simulink cases.');
ids = string([{matCases.caseId},{simCases.caseId}]);
assert(numel(unique(ids))==72, 'Case ID duplication detected.');
manifest = readtable(manifestFile);
assert(height(manifest)==36, 'Expected 36 rows in the comparison manifest.');

% Fixed display conventions for ALL spectrograms and FFT magnitudes.
spectrogramLimitsDB = [-100 0];    % approximate dBFS magnitude
fftLimitsDB = [-125 5];           % magnitude in dB relative to full-scale amplitude
spectrogramWindowSeconds = 0.025; % 25 ms
spectrogramOverlapFraction = 0.75;
waveformWindowSeconds = 0.010;    % 10 ms

%% 2. Verify the unchanged native reference
origCaseM = findCase(matCases,44100,16,'native');
origCaseS = findCase(simCases,44100,16,'native');
x = origCaseM.samples(:);
Fs = origCaseM.Fs;
assert(isequal(x,origCaseS.samples(:)), ...
    'Native-rate references differ across platforms.');
assert(all(origCaseM.quantizationError(:)==0), ...
    'Original reference unexpectedly contains quantization error.');

fprintf('KH-05: Loaded 36 MATLAB + 36 Simulink cases.\n');
fprintf('Original: %d samples, %d Hz, %.6f seconds.\n', ...
    numel(x),Fs,numel(x)/Fs);

%% 3. Native-rate results: 16-bit control plus 8/4/2-bit cases
bitDepths = [16 8 4 2];
CaseID = strings(4,1);
Bits = zeros(4,1);
MSE = zeros(4,1);
SNR_dB = zeros(4,1);
UsedLevels = zeros(4,1);
MaxPlatformDifference = zeros(4,1);

for k=1:numel(bitDepths)
    B = bitDepths(k);
    cm = findCase(matCases,Fs,B,'native');
    cs = findCase(simCases,Fs,B,'native');
    q = cm.samples(:);
    e = cm.quantizationError(:);
    qSim = cs.samples(:);
    assert(numel(q)==numel(x) && numel(qSim)==numel(x), ...
        'Native-rate sample count mismatch at %d bits.',B);
    assert(max(abs((x-q)-e))<1e-12, ...
        'Saved native quantization error is inconsistent at %d bits.',B);

    CaseID(k) = string(cm.caseId);
    Bits(k) = B;
    MSE(k) = mean(e.^2);
    UsedLevels(k) = numel(unique(q));
    MaxPlatformDifference(k) = max(abs(q-qSim));
    SNR_dB(k) = signalSNR(x,e);

    assert(MaxPlatformDifference(k)<1e-12, ...
        'Native MATLAB/Simulink quantizers disagree at %d bits.',B);

    if B < 16
        titleText = sprintf('Native 44.1 kHz | %d-bit quantization',B);
        outputName = sprintf('KH05_Native_%02dbit.png',B);
        createSixViewFigure(x,q,e,Fs,titleText, ...
            fullfile(outFolder,outputName),waveformWindowSeconds, ...
            spectrogramWindowSeconds,spectrogramOverlapFraction, ...
            spectrogramLimitsDB,fftLimitsDB);
        fprintf('Saved native %d-bit 6-view figure.\n',B);
    end
end

nativeTable = table(CaseID,Bits,MSE,SNR_dB,UsedLevels, ...
    MaxPlatformDifference);
writetable(nativeTable,fullfile(outFolder,'KH05_Native_Metrics.csv'));
disp('===== KH-05 NATIVE METRICS =====');
disp(nativeTable);

%% 4. Native-rate MATLAB vs Simulink overlay for ALL reduced bit depths
windowIdx = choosePeakWindow(x,Fs,waveformWindowSeconds);
windowMs = (windowIdx-1)*1000/Fs;
f = figure('Color','w','Position',[70 70 1200 780]);
tl = tiledlayout(3,2,'TileSpacing','compact','Padding','compact');
for k=1:3
    B = [8 4 2];
    b = B(k);
    cm = findCase(matCases,Fs,b,'native');
    cs = findCase(simCases,Fs,b,'native');
    yM = cm.samples(:);
    yS = cs.samples(:);
    nexttile;
    plot(windowMs,yM(windowIdx),'b-','LineWidth',1.0); hold on;
    plot(windowMs,yS(windowIdx),'r--','LineWidth',0.8);
    grid on;
    xlabel('Time (ms)'); ylabel('Normalized amplitude');
    title(sprintf('%d bits: MATLAB and Simulink',b));
    legend('MATLAB','Simulink','Location','best');
    xlim([windowMs(1) windowMs(end)]);
    nexttile;
    plot(windowMs,yM(windowIdx)-yS(windowIdx),'k-');
    grid on;
    xlabel('Time (ms)'); ylabel('Amplitude difference');
    title(sprintf('%d bits: exact-sample difference (max %.3g)', ...
        b,max(abs(yM-yS))));
    xlim([windowMs(1) windowMs(end)]);
end
title(tl,'KH-05 | Native-rate MATLAB / Simulink validation');
exportgraphics(f,fullfile(outFolder, ...
    'KH05_Native_MATLAB_vs_Simulink.png'),'Resolution',180);
close(f);

%% 5. Representative combined case: 8000 Hz, LPF, 4 bits
combinedFs = 8000;
combinedBits = 4;
combinedMode = 'lpf';
cM = findCase(matCases,combinedFs,combinedBits,combinedMode);
cS = findCase(simCases,combinedFs,combinedBits,combinedMode);
qM = cM.samples(:);
qS = cS.samples(:);
eM = cM.quantizationError(:);
eS = cS.quantizationError(:);

% The quantization error in KH-04 is e[n] = sampledInput[n] - quantized[n].
% Recover the SAME-RATE sampled input for an isolation-of-quantization plot.
sampledM = qM + eM;
sampledS = qS + eS;
assert(numel(sampledM)==numel(qM) && numel(qS)==numel(qM), ...
    'Combined sampled/quantized signal lengths differ.');
assert(max(abs((sampledM-qM)-eM))<1e-12, ...
    'Combined quantization error is inconsistent.');

createSixViewFigure(sampledM,qM,eM,combinedFs, ...
    'Combined: 8 kHz, LPF, 4-bit (MATLAB sampling + quantization)', ...
    fullfile(outFolder,'KH05_Combined_8000Hz_LPF_04bit.png'), ...
    waveformWindowSeconds,spectrogramWindowSeconds, ...
    spectrogramOverlapFraction,spectrogramLimitsDB,fftLimitsDB);

combinedInputMaxDiff = max(abs(sampledM-sampledS));
combinedOutputMaxDiff = max(abs(qM-qS));
combinedDifferentSamples = nnz(qM~=qS);
combinedMSE = mean(eM.^2);
combinedSNR = signalSNR(sampledM,eM);

fprintf('\nRepresentative combined case: %s\n',cM.caseId);
fprintf('Sampling input max difference: %.12g\n',combinedInputMaxDiff);
fprintf('Quantized output max difference: %.12g\n',combinedOutputMaxDiff);
fprintf('Differing output samples: %d\n',combinedDifferentSamples);
fprintf('Quantization-only MSE: %.12g\n',combinedMSE);
fprintf('Quantization-only SNR: %.5f dB\n',combinedSNR);

%% 6. Explicit combined MATLAB/Simulink comparison figure
idx = choosePeakWindow(sampledM,combinedFs,waveformWindowSeconds);
ms = (idx-1)*1000/combinedFs;
timeFull = (0:numel(qM)-1)'/combinedFs;
f = figure('Color','w','Position',[80 90 1150 690]);
tl = tiledlayout(2,2,'TileSpacing','compact','Padding','compact');
nexttile;
plot(ms,qM(idx),'b-','LineWidth',1.15); hold on;
plot(ms,qS(idx),'r--','LineWidth',0.9); grid on;
title('Quantized outputs in the same 10-ms window');
xlabel('Time (ms)'); ylabel('Normalized amplitude');
legend('MATLAB path','Simulink path','Location','best');
nexttile;
plot(ms,sampledM(idx),'b-'); hold on;
plot(ms,sampledS(idx),'r--'); grid on;
title('Actual sampled inputs (before quantization)');
xlabel('Time (ms)'); ylabel('Normalized amplitude');
legend('MATLAB sampling','Simulink sampling','Location','best');
nexttile;
plot(timeFull,qM-qS,'k'); grid on;
title(sprintf('Full-record output difference (max %.3g)', ...
    combinedOutputMaxDiff));
xlabel('Time (s)'); ylabel('Amplitude difference');
nexttile;
plot(timeFull,eM,'b'); hold on;
plot(timeFull,eS,'r--'); grid on;
title('Quantization-error waveforms');
xlabel('Time (s)'); ylabel('Error amplitude');
legend('MATLAB path','Simulink path','Location','best');
title(tl,'KH-05 | 8 kHz LPF, 4-bit platform comparison');
exportgraphics(f,fullfile(outFolder, ...
    'KH05_Combined_8000Hz_LPF_Platforms.png'),'Resolution',180);
close(f);

%% 7. Diagnose the one-sample 8 kHz, unfiltered 4-bit discrepancy
% Do NOT use this diagnostic to claim the quantizer algorithms differ:
% the two input sampling arrays may already differ slightly.
dM = findCase(matCases,8000,4,'none');
dS = findCase(simCases,8000,4,'none');
dqM = dM.samples(:);
dqS = dS.samples(:);
dInputM = dqM+dM.quantizationError(:);
dInputS = dqS+dS.quantizationError(:);
diffIdx = find(dqM ~= dqS);

if ~isempty(diffIdx)
    % Show the neighborhood around the largest quantized discrepancy.
    [~,j] = max(abs(dqM(diffIdx)-dqS(diffIdx)));
    center = diffIdx(j);
    neighborhood = max(1,center-15):min(numel(dqM),center+15);
    timeMs = 1000*(neighborhood-1)/8000;
    f = figure('Color','w','Position',[100 100 1050 600]);
    tl = tiledlayout(2,1,'TileSpacing','compact','Padding','compact');
    nexttile;
    plot(timeMs,dInputM(neighborhood),'bo-'); hold on;
    plot(timeMs,dInputS(neighborhood),'rx--'); grid on;
    xlabel('Time (ms)'); ylabel('Input amplitude');
    title('Unfiltered 8 kHz: slight upstream sampling differences');
    legend('MATLAB sampling','Simulink sampling','Location','best');
    nexttile;
    stairs(timeMs,dqM(neighborhood),'b-','LineWidth',1.2); hold on;
    stairs(timeMs,dqS(neighborhood),'r--','LineWidth',1.0); grid on;
    xlabel('Time (ms)'); ylabel('Quantized amplitude');
    title(sprintf('4-bit threshold crossing: %d differing output samples total', ...
        numel(diffIdx)));
    legend('MATLAB path','Simulink path','Location','best');
    title(tl,'KH-05 | Upstream differences can straddle a quantization threshold');
    exportgraphics(f,fullfile(outFolder, ...
        'KH05_Unfiltered_8000Hz_04bit_Diagnostic.png'),'Resolution',180);
    close(f);
end

%% 8. Summarize and save checks
summary = table( ...
    string(cM.caseId),combinedFs,combinedBits,string(combinedMode), ...
    numel(qM),numel(qM)/combinedFs,combinedMSE,combinedSNR, ...
    combinedInputMaxDiff,combinedOutputMaxDiff,combinedDifferentSamples, ...
    'VariableNames',{'CaseID','Fs','Bits','FilterMode', ...
    'SampleCount','DurationSeconds','QuantizationMSE', ...
    'QuantizationSNR_dB','InputMaxDiff','OutputMaxDiff', ...
    'DifferingOutputSamples'});
writetable(summary,fullfile(outFolder,'KH05_Combined_Summary.csv'));

fprintf('\nKH-05 figures created in:\n%s\n',outFolder);
fprintf('Native figures: 8, 4, 2 bits + platform overlay.\n');
fprintf('Combined figures: 8 kHz LPF 4-bit + platform overlay.\n');
fprintf('Diagnostic: unfiltered 8 kHz, 4-bit (if differences exist).\n');
fprintf('KH-05 plot generation finished.\n');

%% ========== Local helper functions ==========
function c = findCase(cases,rate,bits,mode)
    mask = [cases.Fs]==rate & [cases.effectiveBits]==bits & ...
        strcmp({cases.filterMode},mode);
    assert(nnz(mask)==1, ...
        'Expected exactly one case for Fs=%d, bits=%d, mode=%s.', ...
        rate,bits,mode);
    c=cases(find(mask,1));
end

function indices = choosePeakWindow(x,Fs,windowSeconds)
    n = max(3,round(windowSeconds*Fs));
    n = min(n,numel(x));
    [~,peak]=max(abs(x(:)));
    start=max(1,min(peak-floor(n/2),numel(x)-n+1));
    indices=(start:start+n-1)';
end

function out = signalSNR(x,errorSignal)
    signalEnergy=sum(x(:).^2);
    errorEnergy=sum(errorSignal(:).^2);
    if errorEnergy==0
        out=Inf;
    elseif signalEnergy==0
        out=-Inf;
    else
        out=10*log10(signalEnergy/errorEnergy);
    end
end

function [freq,db] = singleSidedFFTdb(x,Fs)
    x=double(x(:));
    n=numel(x);
    nFFT=2^nextpow2(n);
    y=fft(x,nFFT);
    oneSided=abs(y(1:nFFT/2+1))/n;
    if numel(oneSided)>2
        oneSided(2:end-1)=2*oneSided(2:end-1);
    end
    freq=(0:nFFT/2)'*(Fs/nFFT);
    db=20*log10(max(oneSided,1e-12));
end

function [T,F,db] = getSpectrogramDB(x,Fs,windowSeconds,overlapRatio)
    % Toolbox-free short-time Fourier transform (STFT).
    % Periodic Hamming window, identical for all signals at the same Fs.
    x=double(x(:));
    nWindow=max(64,2*floor(Fs*windowSeconds/2));
    nWindow=min(nWindow,numel(x));
    nOverlap=floor(nWindow*overlapRatio);
    hop=nWindow-nOverlap;
    assert(hop >= 1 && nWindow >= 2, ...
        'Invalid spectrogram window or overlap.');
    nFFT=max(512,2^nextpow2(nWindow));
    nFrames=1+floor((numel(x)-nWindow)/hop);
    assert(nFrames >= 1, 'Signal is too short for spectrogram.');

    % Periodic Hamming (defined explicitly: no hamming() toolbox call).
    w=0.54-0.46*cos(2*pi*(0:nWindow-1)'/nWindow);
    windowSum=sum(w);
    nFreq=nFFT/2+1;
    F=(0:nFreq-1)'*Fs/nFFT;
    T=zeros(nFrames,1);
    db=zeros(nFreq,nFrames);

    for frameNumber=1:nFrames
        first=1+(frameNumber-1)*hop;
        frame=x(first:first+nWindow-1).*w;
        Y=fft(frame,nFFT);
        % Approximate one-sided peak-amplitude spectrum, dBFS.
        magnitude=2*abs(Y(1:nFreq))/windowSum;
        db(:,frameNumber)=20*log10(max(magnitude,1e-12));
        T(frameNumber)=((first-1)+(nWindow-1)/2)/Fs;
    end
end

function createSixViewFigure(inputSignal,quantized,errorSignal,Fs, ...
    mainTitle,outPath,waveSeconds,winSeconds,overlapRatio, ...
    specLimits,fftLimits)
    inputSignal=double(inputSignal(:));
    quantized=double(quantized(:));
    errorSignal=double(errorSignal(:));
    assert(isequal(size(inputSignal),size(quantized),size(errorSignal)), ...
        'Plot data arrays must be same size.');
    idx=choosePeakWindow(inputSignal,Fs,waveSeconds);
    ms=(idx-1)*1000/Fs;
    [freq,dbInput]=singleSidedFFTdb(inputSignal,Fs);
    [~,dbOutput]=singleSidedFFTdb(quantized,Fs);
    [Tin,Fin,specIn]=getSpectrogramDB( ...
        inputSignal,Fs,winSeconds,overlapRatio);
    [Tout,Fout,specOut]=getSpectrogramDB( ...
        quantized,Fs,winSeconds,overlapRatio);

    f=figure('Color','w','Position',[50 50 1380 990]);
    tl=tiledlayout(3,2,'TileSpacing','compact','Padding','compact');

    nexttile;
    plot(ms,inputSignal(idx),'b','LineWidth',1); hold on;
    stairs(ms,quantized(idx),'r','LineWidth',0.8); grid on;
    xlabel('Time (ms)'); ylabel('Normalized amplitude');
    title('Input vs quantized waveform (same time grid)');
    legend('Input','Quantized','Location','best');
    xlim([ms(1) ms(end)]);

    nexttile;
    plot(freq/1000,dbInput,'b','LineWidth',0.7); hold on;
    plot(freq/1000,dbOutput,'r','LineWidth',0.65); grid on;
    xlabel('Frequency (kHz)'); ylabel('FFT magnitude (dB re FS)');
    title('Whole-record one-sided FFT');
    xlim([0 min(Fs/2000,10)]);
    ylim(fftLimits);
    legend('Input','Quantized','Location','best');

    nexttile;
    imagesc(Tin,Fin/1000,specIn); axis xy;
    xlabel('Time (s)'); ylabel('Frequency (kHz)');
    title('Input spectrogram (25-ms window)');
    caxis(specLimits); cb=colorbar; ylabel(cb,'Approx. magnitude (dBFS)');

    nexttile;
    imagesc(Tout,Fout/1000,specOut); axis xy;
    xlabel('Time (s)'); ylabel('Frequency (kHz)');
    title('Quantized spectrogram (same color scale)');
    caxis(specLimits); cb=colorbar; ylabel(cb,'Approx. magnitude (dBFS)');

    nexttile;
    plot(ms,errorSignal(idx),'k','LineWidth',0.9); grid on;
    xlabel('Time (ms)'); ylabel('Error amplitude');
    title('Quantization error e[n] = input - quantized');
    xlim([ms(1) ms(end)]);

    nexttile;
    histogram(errorSignal,80); grid on;
    xlabel('Error amplitude'); ylabel('Sample count');
    title(sprintf('Error distribution | MSE %.4g | SNR %.3f dB', ...
        mean(errorSignal.^2),signalSNR(inputSignal,errorSignal)));

    title(tl,mainTitle);
    exportgraphics(f,outPath,'Resolution',180);
    close(f);
end
