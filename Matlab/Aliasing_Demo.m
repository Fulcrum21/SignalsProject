%% Load the existing 10 kHz sine recording
% Set MATLAB's Current Folder to Matlab and run the whole script.
[tone, FsTone] = audioread("../Audios/10kHz_Sine.wav");

%% Reduce the sampling rate from 44.1 kHz to 11.025 kHz
% Without filtering: retain every fourth sample.
toneNoFilter = tone(1:4:end);
FsDemo = FsTone / 4;

% With filtering: suppress high frequencies before reducing the rate.
toneFiltered = resample(tone, 1, 4);

% 10 kHz is above the new Nyquist limit of 5512.5 Hz.
% In this case, it folds to 11025 - 10000 = 1025 Hz without filtering.
expectedAliasHz = abs(FsDemo - 10000);
fprintf('New Nyquist limit: %.1f Hz\n', FsDemo/2);
fprintf('Expected alias of the 10 kHz tone: %.1f Hz\n', expectedAliasHz);

%% Plot the original and both processed spectra
% Repeat the same FFT calculation for the three signals.
demoSignals = {tone, toneNoFilter, toneFiltered};
demoRates = [FsTone, FsDemo, FsDemo];
demoTitles = ["Original 10 kHz Recording", ...
    "Downsampled - Without Anti-Aliasing Filter", ...
    "Downsampled - With Anti-Aliasing Filter"];

figure
for signalIndex = 1:3
    signal = demoSignals{signalIndex};
    signalFs = demoRates(signalIndex);

    % Normalize the FFT and retain the positive-frequency side.
    N = length(signal);
    signalFFT = fft(signal);
    magnitude = abs(signalFFT) / N;
    magnitude = magnitude(1:floor(N/2) + 1);
    frequency = (0:floor(N/2))' * signalFs / N;

    % Double paired magnitudes, leaving DC and any Nyquist bin unchanged.
    if mod(N, 2) == 0
        magnitude(2:end-1) = 2 * magnitude(2:end-1);
    else
        magnitude(2:end) = 2 * magnitude(2:end);
    end

    subplot(3, 1, signalIndex)
    plot(frequency, magnitude)
    xlabel("Frequency (Hz)")
    ylabel("Amplitude")
    title(demoTitles(signalIndex))
    xlim([0, signalFs/2])
    % Keep the same amplitude scale so suppression is visible and fair.
    ylim([0, 1.1 * max(abs(tone))])
    grid on

    % Record the largest spectral peak for each signal.
    [peakAmplitudes(signalIndex), peakIndex] = max(magnitude);
    peakFrequencies(signalIndex) = frequency(peakIndex);
    fprintf('%s: largest peak at %.2f Hz, amplitude %.6f\n', ...
        demoTitles(signalIndex), peakFrequencies(signalIndex), ...
        peakAmplitudes(signalIndex));
end
