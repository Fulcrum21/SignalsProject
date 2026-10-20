% read the audio file
[originalAudio, Fs] = audioread("untitled.wav");

% Part 1: Original audio signal in time

% calculate the number of samples in the audio file
% and generate a time vector representing the time of each sample
numSamples = length(originalAudio);
time = (0:numSamples - 1) / Fs;

% plot the original audio signal vs time
figure(1)
plot(time,originalAudio)
xlim([0 20])
xlabel("Time (s)")
ylabel("Amplitude")
title("Original audio signal")

% Part 2: FFT of original audio signal

% calculate the fast fourier transform of the audio signal
% the fft function returns a vector of complex numbers
% representing the coefficients X[k] for each frequency bin Fs*k/N
% where Fs is the sampling frequency of the audio, and N is the number of
% samples
audioFFT = fft(originalAudio);

% we generate the vector representing the frequencies in the audioFFT
% the reason we only use half the frequencies is because the second half of
% the audioFFT represents the negative frequencies of the audio file
frequencies = (0:floor(numSamples/2)) * Fs / numSamples;
% find the magnitude of the complex coefficients X[k], normalized to the
% number of samples
fftMag = abs(audioFFT/numSamples);

% take only the magnitude of the coefficients for the positive frequencies
fftMag = fftMag(1:floor(numSamples/2) + 1);

% double the positive frequencies' magnitude, since the negative and
% positive frequencies' are conjugates and have the same magnitude
if numSamples%2==0
    fftMag(2:end-1) = 2*fftMag(2:end-1);
else
    fftMag(2:end) = 2*fftMag(2:end);
end

% Part 3: FFT in decibel scale

% plot the normalized single-sided Frequency spectrum of the audio signal
figure(2)
plot(frequencies, fftMag)
xlabel("Frequency (Hz)")
ylabel("Amplitude")
title("Frequency Spectrum")
% limit the frequency range from 0 to 4000Hz
xlim([0 4000])

% convert the amplitudes to decibels, and plot
fftMagDb = 20*log10(fftMag);
figure(3)
plot(frequencies, fftMagDb)
xlabel("Frequency (Hz)")
ylabel("Magnitude (dB)")
title("Frequency Spectrum in Decibels")
xlim([0 4000])

% Part 4: Spectrogram
window = round(0.03 * Fs); % Number of window of size 30 ms
overlap = round (0.02*Fs); % Number of overlapped windows of 20 ms
fftBins = 2048; % 2048 Frequency bins

figure(4)
spectrogram(originalAudio, hamming(window), overlap, fftBins, Fs, 'yaxis')
ylim([0 4])
clim([-120 -40])
xlabel("Time (s)")
ylabel("Frequency (kHz)")
title("Spectrogram")
colorbar.Label.String = "Power/Frequency (dB/kHz)";