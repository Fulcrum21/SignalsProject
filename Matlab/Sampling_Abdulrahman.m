%% Load the original mono recording
% Locate Audios relative to this script, rather than MATLAB's Current Folder.
scriptFolder = fileparts(mfilename('fullpath'));
audioFile = fullfile(scriptFolder, '..', 'Audios', 'SpeechMusic.wav');
[x, Fs] = audioread(audioFile);

%% Reduce the sampling rate without anti-aliasing filtering
% Keep samples 1, 3, 5, ... . No low-pass filter is applied in this branch.
% Components above the new Nyquist limit (FsNoFilter/2) can alias.
yNoFilter = x(1:2:end);
FsNoFilter = Fs / 2;

% Duration = sample count / sampling rate. These durations are approximately
% equal; an odd input length causes a small sample-count rounding difference.
durationOriginal = length(x) / Fs;
durationNoFilter = length(yNoFilter) / FsNoFilter;

%% Reduce the sampling rate with anti-aliasing filtering
% resample(x, p, q) changes the rate by p/q. It applies an FIR low-pass
% anti-aliasing filter and compensates for the filter's delay.
% Start from the original x so filtering happens before sample reduction.
% Make MATLAB's default design settings explicit and retain the actual FIR
% coefficients so teammates can reproduce this prototype's filter.
filterDesignN = 10;
kaiserBeta = 5;
[yFiltered, filterCoefficients] = resample(x, 1, 2, filterDesignN, kaiserBeta);
FsFiltered = Fs / 2;
durationFiltered = length(yFiltered) / FsFiltered;

%% Build the unfiltered output's single-sided amplitude spectrum
NNoFilter = length(yNoFilter);
fftNoFilter = fft(yNoFilter);

% Divide by the sample count to normalize the FFT, then take magnitudes.
% Keep DC and the positive-frequency bins. Use the output's sampling rate
% for the frequency axis: adjacent bins are FsNoFilter/NNoFilter Hz apart.
magNoFilter = abs(fftNoFilter) / NNoFilter;
magNoFilter = magNoFilter(1:floor(NNoFilter/2) + 1);
fNoFilter = (0:floor(NNoFilter/2)) * FsNoFilter / NNoFilter;

% For real audio, positive/negative frequency bins form conjugate pairs.
% Double paired magnitudes when keeping one side. Never double DC (bin 1).
if mod(NNoFilter, 2) == 0
    % Even length: the last retained bin is Nyquist, which is not doubled.
    magNoFilter(2:end-1) = 2 * magNoFilter(2:end-1);
else
    % Odd length: there is no exact Nyquist bin, so double through the end.
    magNoFilter(2:end) = 2 * magNoFilter(2:end);
end

figure
plot(fNoFilter, magNoFilter)
xlabel("Frequency (Hz)")
ylabel("Amplitude")
title("Downsampled Audio - Without Anti-Aliasing Filter")
grid on

%% Build the filtered output's single-sided amplitude spectrum
% Apply the same normalization and one-sided scaling to the filtered signal.
% Use Filtered consistently: yFiltered, FsFiltered, NFiltered, etc.
NFiltered = length(yFiltered);
fftFiltered = fft(yFiltered);

magFiltered = abs(fftFiltered) / NFiltered;
magFiltered = magFiltered(1:floor(NFiltered/2) + 1);
fFiltered = (0:floor(NFiltered/2)) * FsFiltered / NFiltered;

if mod(NFiltered, 2) == 0
    % Leave DC and Nyquist unchanged for an even-length signal.
    magFiltered(2:end-1) = 2 * magFiltered(2:end-1);
else
    % Leave only DC unchanged for an odd-length signal.
    magFiltered(2:end) = 2 * magFiltered(2:end);
end

figure
plot(fFiltered, magFiltered)
xlabel("Frequency (Hz)")
ylabel("Amplitude")
title("Downsampled Audio - With Anti-Aliasing Filter")
grid on

%% Compare both output spectra using their actual frequency axes
% Both outputs have rate Fs/2; display them together to inspect differences.
% This plot alone does not prove aliasing: compare with the original signal
% and a known-frequency test case when drawing conclusions.
comparisonFigure = figure('Color', 'w');
set(comparisonFigure, 'Position', [100 100 1100 650]);
plot(fNoFilter, magNoFilter)
hold on
plot(fFiltered, magFiltered)
hold off

xlabel("Frequency (Hz)")
ylabel("Amplitude")
legend("Without filter", "With filter", 'TextColor', 'k', 'Color', 'w')
title("Filtered vs Unfiltered Downsampling")
grid on
% Use explicit print-friendly colors so saved labels remain readable even
% when teammates have different MATLAB light/dark theme preferences.
comparisonAxes = gca;
set(comparisonAxes, 'Color', 'w', 'XColor', 'k', 'YColor', 'k');
comparisonAxes.XLabel.Color = 'k';
comparisonAxes.YLabel.Color = 'k';
comparisonAxes.Title.Color = 'k';

%% Save the AA-02 handoff (samples, settings, summary, and spectrum evidence)
% These are sampling-stage outputs stored as double arrays, not quantized
% WAV files. The b16 case label identifies the 16-bit source/control;
% Khaled still owns any explicit re-quantization at the next stage.
resultFolder = fullfile(scriptFolder, '..', 'Results', 'Abdulrahman', 'AA02');
if ~isfolder(resultFolder)
    mkdir(resultFolder);
end

sourceInfo = audioinfo(audioFile);
prototype.schemaVersion = 1;
prototype.platform = 'MATLAB';
prototype.matlabRelease = version('-release');
prototype.sourceFile = 'Audios/SpeechMusic.wav';
prototype.sourceBitsPerSample = sourceInfo.BitsPerSample;
prototype.processingStage = 'sampling_only';
prototype.quantizationApplied = false;
prototype.normalizationApplied = false;
prototype.original = struct('samples', x, 'Fs', Fs, ...
    'sampleCount', length(x), 'durationSeconds', durationOriginal);
prototype.unfiltered = struct( ...
    'caseId', 'speechmusic_fs22050_b16_none_matlab', ...
    'samples', yNoFilter, 'Fs', FsNoFilter, 'filterMode', 'none', ...
    'sampleCount', NNoFilter, 'durationSeconds', durationNoFilter, ...
    'firstSampleTimeSeconds', 0, 'lastSampleTimeSeconds', (NNoFilter-1)/FsNoFilter);
prototype.filtered = struct( ...
    'caseId', 'speechmusic_fs22050_b16_lpf_matlab', ...
    'samples', yFiltered, 'Fs', FsFiltered, 'filterMode', 'lpf', ...
    'sampleCount', NFiltered, 'durationSeconds', durationFiltered, ...
    'firstSampleTimeSeconds', 0, 'lastSampleTimeSeconds', (NFiltered-1)/FsFiltered);
prototype.filter = struct('p', 1, 'q', 2, 'designN', filterDesignN, ...
    'kaiserBeta', kaiserBeta, 'coefficients', filterCoefficients, ...
    'order', length(filterCoefficients)-1, 'nominalCutoffHz', FsFiltered/2, ...
    'rawGroupDelayInputSamples', (length(filterCoefficients)-1)/2, ...
    'delayCompensatedByResample', true);
% Output sample times are firstSampleTimeSeconds + (0:N-1)/Fs.
% resample already compensates its FIR delay; do not apply that shift again.
% Reconstruction onto the original rate and valid comparison-edge handling
% are AA-03 decisions with Jesher, not completed by these timing fields.
prototype.alignmentStatus = 'Common-grid reconstruction and edge policy pending AA-03';
save(fullfile(resultFolder, 'sampling_22050.mat'), 'prototype', '-v7');

summaryTable = table( ...
    string({prototype.unfiltered.caseId; prototype.filtered.caseId}), ...
    ["none"; "lpf"], [FsNoFilter; FsFiltered], [NNoFilter; NFiltered], ...
    [durationNoFilter; durationFiltered], [0; 0], ...
    [(NNoFilter-1)/FsNoFilter; (NFiltered-1)/FsFiltered], ...
    [0; length(filterCoefficients)], [false; true], ...
    'VariableNames', {'CaseId', 'FilterMode', 'FsHz', 'SampleCount', ...
    'DurationSeconds', 'FirstSampleTimeSeconds', 'LastSampleTimeSeconds', ...
    'FIRTaps', 'FIRDelayCompensated'});
writetable(summaryTable, fullfile(resultFolder, 'summary.csv'));
exportgraphics(comparisonFigure, fullfile(resultFolder, 'comparison.png'), ...
    'Resolution', 160, 'BackgroundColor', comparisonFigure.Color);
disp(summaryTable)
fprintf('AA-02 outputs saved to: %s\n', resultFolder);
