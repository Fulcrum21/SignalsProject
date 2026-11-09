
clc;
clear;
close all;

%% 1. Locate the project
scriptFolder = fileparts(mfilename('fullpath'));
projectRoot = fileparts(scriptFolder);

audioPath = fullfile(projectRoot, ...
    'Audios', 'SpeechMusic.wav');

outDir = fullfile(projectRoot, ...
    'Results', 'Khaled');

if ~exist(outDir, 'dir')
    mkdir(outDir);
end

%% 2. Load original recording
[x, Fs] = audioread(audioPath);

fprintf('Original sampling rate: %d Hz\n', Fs);
fprintf('Original duration: %.3f seconds\n', ...
    size(x,1)/Fs);

%% 3. Define bit depths
bitDepths = [16, 8, 4, 2];

% Store quantized signals and errors
signals = cell(1,4);
errors = cell(1,4);

MSE = zeros(4,1);
SNR = zeros(4,1);

%% 4. Apply quantization
for k = 1:length(bitDepths)

    B = bitDepths(k);

    % Apply your quantizer function
    [xq, e] = Khaled_Quantizer(x, B);

    % Store signals and errors
    signals{k} = xq;
    errors{k} = e;

    % Mean squared error
    MSE(k) = mean(e(:).^2);

    % Signal-to-noise ratio
    signalPower = sum(x(:).^2);
    errorPower = sum(e(:).^2);

    if errorPower == 0
        SNR(k) = Inf;
    else
        SNR(k) = 10*log10( ...
            signalPower/errorPower);
    end

    % Confirm no samples were removed
    assert(isequal(size(xq),size(x)), ...
        'Sample count or channels changed!');

    % Save each quantized version
    effectiveBits = B;
    actualFs = Fs;
    numSamples = size(xq,1);
    numChannels = size(xq,2);
    duration = numSamples/actualFs;

    filename = sprintf('Quantized_%dbit.mat',B);

    save(fullfile(outDir,filename), ...
        'xq','e','effectiveBits','actualFs', ...
        'numSamples','numChannels','duration');

    fprintf('%d-bit completed.\n',B);
end

%% 5. Display comparison table
Results = table(bitDepths',MSE,SNR, ...
    'VariableNames',{'Bits','MSE','SNR_dB'});

disp('===== QUANTIZATION RESULTS =====');
disp(Results);

% Save numerical results
writetable(Results, ...
    fullfile(outDir,'Quantization_Results.csv'));

%% 6. Select a 10-ms section
[~, peakIndex] = max(abs(x(:,1)));

N = round(0.01*Fs);

startIndex = max(1,peakIndex-floor(N/2));
endIndex = min(size(x,1),startIndex+N-1);

idx = startIndex:endIndex;
t = (idx-1)/Fs;

%% 7. Plot comparison
figure('Color','w','Position',[100 100 1100 800]);

for k = 2:4

    B = bitDepths(k);

    % Original and quantized waveform
    subplot(3,2,2*(k-2)+1);

    plot(t,x(idx,1),'b');
    hold on;
    stairs(t,signals{k}(idx,1),'r');

    grid on;
    title(sprintf('Original vs %d-bit',B));
    xlabel('Time (s)');
    ylabel('Amplitude');
    legend('Original','Quantized');

    % Quantization error waveform
    subplot(3,2,2*(k-2)+2);

    plot(t,errors{k}(idx,1),'k');

    grid on;
    title(sprintf('%d-bit Error',B));
    xlabel('Time (s)');
    ylabel('Error amplitude');

end

sgtitle('Quantization Comparison at 44100 Hz');

%% 8. Save figure
saveas(gcf,fullfile(outDir, ...
    'All_BitDepths_Comparison.png'));

disp('All bit-depth experiments completed!');
