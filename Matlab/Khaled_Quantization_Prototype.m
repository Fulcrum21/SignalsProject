
clc;
clear;
close all;

%% 1. Locate the project folders
scriptFolder = fileparts(mfilename('fullpath'));
projectRoot = fileparts(scriptFolder);

audioPath = fullfile(projectRoot, ...
    'Audios', 'SpeechMusic.wav');

outputFolder = fullfile(projectRoot, ...
    'Results', 'Khaled');

if ~exist(outputFolder, 'dir')
    mkdir(outputFolder);
end

%% 2. Load original recording
[x, Fs] = audioread(audioPath);

fprintf('Original sample rate: %d Hz\n', Fs);
fprintf('Number of samples: %d\n', size(x,1));
fprintf('Duration: %.3f seconds\n', size(x,1)/Fs);

%% 3. Apply 4-bit quantization
B = 4;

[xq, e] = Khaled_Quantizer(x, B);

fprintf('Effective bits: %d\n', B);
fprintf('Quantized sample rate: %d Hz\n', Fs);

%% 4. Calculate quantization error
MSE = mean(e(:).^2);

fprintf('Quantization MSE: %.8f\n', MSE);

%% 5. Choose a 50-ms waveform section
% Select a section near the largest amplitude
[~, peakIndex] = max(abs(x(:)));

windowSamples = round(0.05 * Fs);
startIndex = max(1, peakIndex - floor(windowSamples/2));
endIndex = min(size(x,1), startIndex + windowSamples - 1);

idx = startIndex:endIndex;
t = (idx-1)/Fs;

%% 6. Generate the plots
figure('Color','w');

% Original vs quantized waveform
subplot(3,1,1);
plot(t, x(idx), 'b');
hold on;
stairs(t, xq(idx), 'r');
grid on;
title('Original vs 4-bit Quantized Audio');
xlabel('Time (seconds)');
ylabel('Amplitude');
legend('Original','4-bit');

% Quantization error waveform
subplot(3,1,2);
plot(t, e(idx), 'k');
grid on;
title('Quantization Error');
xlabel('Time (seconds)');
ylabel('Error amplitude');

% Error distribution
subplot(3,1,3);
histogram(e(:), 80);
grid on;
title('Quantization Error Distribution');
xlabel('Error amplitude');
ylabel('Frequency');

%% 7. Save your results
save(fullfile(outputFolder, 'KH02_Prototype.mat'), ...
    'x', 'xq', 'e', 'Fs', 'B', 'MSE');

saveas(gcf, fullfile(outputFolder, ...
    'KH02_Quantization_Error.png'));

disp('Prototype completed successfully!');