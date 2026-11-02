%% Plot the saved sampling handoff
% Set Current Folder to Matlab. Run Prepare_Sampling_Handoff first.
resultFolder = "../Results/Abdulrahman/Sampling";
saved = load(fullfile(resultFolder, 'sampling_all_rates.mat'));
handoff = saved.samplingHandoff;
reference = handoff.original.samples;
referenceFs = handoff.original.Fs;
referenceTime = (0:length(reference)-1)' / referenceFs;
% Use the same active 10 ms excerpt for every waveform comparison.
[~, loudestIndex] = max(abs(reference));
zoomStart = max(0, min((loudestIndex-1)/referenceFs - 0.005, referenceTime(end)-0.01));
zoomEnd = zoomStart + 0.01;
plotNames = ["Original", "Without AA filter", "With AA filter"];
plotColors = [0.25 0.25 0.25; 0 0.447 0.741; 0.850 0.325 0.098];

for rateIndex = 1:4
    noFilter = handoff.cases(2*rateIndex-1);
    filtered = handoff.cases(2*rateIndex);
    signals = {reference, noFilter.samples, filtered.samples};
    sampleRates = [referenceFs, noFilter.Fs, filtered.Fs];
    amplitudeLimit = 1.05 * max([abs(reference); abs(noFilter.samples); abs(filtered.samples)]);

    %% Full waveforms and a common physical-time excerpt
    waveformFigure = figure('Visible', 'off', 'Theme', 'light', 'Color', 'w', ...
        'Position', [100 100 1400 900]);
    for signalIndex = 1:3
        samples = signals{signalIndex};
        time = (0:length(samples)-1)' / sampleRates(signalIndex);
        subplot(3, 2, 2*signalIndex-1)
        plot(time, samples, 'Color', plotColors(signalIndex,:))
        xlim([0 referenceTime(end)])
        ylim([-amplitudeLimit amplitudeLimit])
        xlabel('Time (s)'); ylabel('Amplitude'); grid on
        title(plotNames(signalIndex) + " - Full Recording")
        subplot(3, 2, 2*signalIndex)
        plot(time, samples, '.-', 'Color', plotColors(signalIndex,:))
        xlim([zoomStart zoomEnd])
        ylim([-amplitudeLimit amplitudeLimit])
        xlabel('Time (s)'); ylabel('Amplitude'); grid on
        title(plotNames(signalIndex) + " - Same 10 ms Interval")
    end
    sgtitle(sprintf('Waveform comparison - output %d Hz', noFilter.Fs));
    set(findall(waveformFigure, 'Type', 'axes'), 'FontSize', 12);
    exportgraphics(waveformFigure, fullfile(resultFolder, ...
        sprintf('waveforms_%d.png', noFilter.Fs)), ...
        'Resolution', 160, 'BackgroundColor', 'white');
    close(waveformFigure)

    %% Whole-record spectra: full bandwidth and a detailed dB comparison
    spectrumFigure = figure('Visible', 'off', 'Theme', 'light', 'Color', 'w', ...
        'Position', [100 100 1400 850]);
    for signalIndex = 1:3
        samples = signals{signalIndex};
        N = length(samples);
        magnitude = abs(fft(samples)) / N;
        magnitude = magnitude(1:floor(N/2)+1);
        if mod(N,2) == 0
            magnitude(2:end-1) = 2*magnitude(2:end-1);
        else
            magnitude(2:end) = 2*magnitude(2:end);
        end
        frequency = (0:floor(N/2))' * sampleRates(signalIndex) / N;
        subplot(2,1,1)
        plot(frequency/1000, magnitude, 'Color', plotColors(signalIndex,:)); hold on
        subplot(2,1,2)
        plot(frequency/1000, 20*log10(max(magnitude,1e-12)), ...
            'Color', plotColors(signalIndex,:)); hold on
    end
    subplot(2,1,1)
    xline(noFilter.Fs/2000, '--', 'New Nyquist', 'HandleVisibility', 'off');
    xlim([0 referenceFs/2000]); xlabel('Frequency (kHz)'); ylabel('Amplitude')
    title('Original Bandwidth and Both Processed Spectra'); legend(plotNames); grid on
    subplot(2,1,2)
    xlim([0 noFilter.Fs/2000]); ylim([-140 -20])
    xlabel('Frequency (kHz)'); ylabel('Magnitude (dB re 1)')
    title('Shared Output Band - Logarithmic View'); legend(plotNames); grid on
    sgtitle(sprintf('FFT comparison - output %d Hz', noFilter.Fs));
    set(findall(spectrumFigure, 'Type', 'axes'), 'FontSize', 12);
    exportgraphics(spectrumFigure, fullfile(resultFolder, ...
        sprintf('spectra_%d.png', noFilter.Fs)), ...
        'Resolution', 160, 'BackgroundColor', 'white');
    close(spectrumFigure)

    %% Spectrograms with equal windows, color limits and shared output band
    spectrogramFigure = figure('Visible', 'off', 'Theme', 'light', 'Color', 'w', ...
        'Position', [100 100 1400 1000]);
    for signalIndex = 1:3
        signalFs = sampleRates(signalIndex);
        window = round(0.03*signalFs);
        overlap = round(0.02*signalFs);
        [~, frequency, time, powerDensity] = spectrogram( ...
            signals{signalIndex}, hamming(window), overlap, 2048, signalFs);
        subplot(3,1,signalIndex)
        imagesc(time, frequency/1000, 10*log10(max(powerDensity,1e-14)))
        axis xy
        xlim([0 referenceTime(end)]); ylim([0 noFilter.Fs/2000])
        clim([-130 -30]); colormap(turbo)
        xlabel('Time (s)'); ylabel('Frequency (kHz)')
        title(plotNames(signalIndex) + " - " + signalFs + " Hz")
        colorScale = colorbar;
        colorScale.Label.String = 'PSD (dB re 1 sample-unit^2/Hz)';
    end
    sgtitle(sprintf('Spectrogram comparison - output %d Hz', noFilter.Fs));
    set(findall(spectrogramFigure, 'Type', 'axes'), 'FontSize', 12);
    exportgraphics(spectrogramFigure, fullfile(resultFolder, ...
        sprintf('spectrograms_%d.png', noFilter.Fs)), ...
        'Resolution', 160, 'BackgroundColor', 'white');
    close(spectrogramFigure)
end
