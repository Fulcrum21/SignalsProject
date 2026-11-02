%% Load the original mono recording
% Set MATLAB's Current Folder to Matlab before running this script.
% The original 22.05 kHz script and its Simulink variables stay unchanged.
[x, Fs] = audioread("../Audios/SpeechMusic.wav");
originalTime = (0:length(x)-1)' / Fs;
targetRates = [11025, 8000, 4000];

%% Process each remaining sampling rate
for rateIndex = 1:length(targetRates)
    FsOutput = targetRates(rateIndex);

    % Use output sample times within the original recording's time interval.
    lastOutputIndex = floor((length(x)-1) * FsOutput / Fs);
    outputTime = (0:lastOutputIndex)' / FsOutput;

    %% Reduce the rate without an anti-aliasing low-pass filter
    if mod(Fs, FsOutput) == 0
        % Integer conversion: retain every fourth sample for 11.025 kHz.
        downsampleFactor = Fs / FsOutput;
        yNoFilterRate = x(1:downsampleFactor:end);
        unfilteredMethod = "Direct sample selection";
    else
        % 8 and 4 kHz sample times fall between the original sample times.
        % Estimate these values by linear interpolation, without an AA filter.
        % Interpolation changes the response, so this is not exact selection.
        yNoFilterRate = interp1(originalTime, x, outputTime, "linear");
        unfilteredMethod = "Linear interpolation, no anti-aliasing LPF";
    end

    %% Apply anti-aliasing filtering and reduce the sampling rate
    % p/q is 1/4, 80/441, or 40/441 for the three target rates.
    [p, q] = rat(FsOutput / Fs);
    [yFilteredRate, coefficientsRate] = resample(x, p, q, 10, 5);

    % Keep the same physical sample times in both branches.
    % resample may include one final sample beyond the original time interval.
    yFilteredRate = yFilteredRate(1:length(outputTime));

    %% Build the unfiltered single-sided amplitude spectrum
    NNoFilterRate = length(yNoFilterRate);
    fftNoFilterRate = fft(yNoFilterRate);
    magNoFilterRate = abs(fftNoFilterRate) / NNoFilterRate;
    magNoFilterRate = magNoFilterRate(1:floor(NNoFilterRate/2) + 1);
    fNoFilterRate = (0:floor(NNoFilterRate/2)) * FsOutput / NNoFilterRate;

    if mod(NNoFilterRate, 2) == 0
        magNoFilterRate(2:end-1) = 2 * magNoFilterRate(2:end-1);
    else
        magNoFilterRate(2:end) = 2 * magNoFilterRate(2:end);
    end

    %% Build the filtered single-sided amplitude spectrum
    NFilteredRate = length(yFilteredRate);
    fftFilteredRate = fft(yFilteredRate);
    magFilteredRate = abs(fftFilteredRate) / NFilteredRate;
    magFilteredRate = magFilteredRate(1:floor(NFilteredRate/2) + 1);
    fFilteredRate = (0:floor(NFilteredRate/2)) * FsOutput / NFilteredRate;

    if mod(NFilteredRate, 2) == 0
        magFilteredRate(2:end-1) = 2 * magFilteredRate(2:end-1);
    else
        magFilteredRate(2:end) = 2 * magFilteredRate(2:end);
    end

    %% Compare both spectra at this sampling rate
    figure
    plot(fNoFilterRate, magNoFilterRate)
    hold on
    plot(fFilteredRate, magFilteredRate)
    hold off
    xlabel("Frequency (Hz)")
    ylabel("Amplitude")
    legend("Without AA filter", "With AA filter")
    title("Filtered vs Unfiltered Downsampling - " + FsOutput + " Hz")
    grid on

    %% Keep each rate's results in the workspace for the next steps
    % MATLAB array positions 1, 2, and 3 correspond to targetRates above.
    otherRates(rateIndex).Fs = FsOutput;
    otherRates(rateIndex).unfiltered = yNoFilterRate;
    otherRates(rateIndex).filtered = yFilteredRate;
    otherRates(rateIndex).unfilteredMethod = unfilteredMethod;
    otherRates(rateIndex).p = p;
    otherRates(rateIndex).q = q;
    otherRates(rateIndex).filterCoefficients = coefficientsRate;
    otherRates(rateIndex).sampleCount = length(outputTime);
    otherRates(rateIndex).durationSeconds = length(outputTime) / FsOutput;
    otherRates(rateIndex).lastSampleTimeSeconds = outputTime(end);

    fprintf('%g Hz: %d samples per branch, duration %.6f s, ratio %d/%d\n', ...
        FsOutput, length(outputTime), length(outputTime)/FsOutput, p, q);
end
