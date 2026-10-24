%% Load the original mono recording
% Set MATLAB's Current Folder to Matlab before running this script.
audioFile = "../Audios/SpeechMusic.wav";
[x, Fs] = audioread(audioFile);

%% Reduce the sampling rate without anti-aliasing filtering
% Keep samples 1, 3, 5, ... without filtering; higher frequencies may alias.
yNoFilter = x(1:2:end);
FsNoFilter = Fs / 2;

% Durations are approximately equal; odd sample counts cause rounding.
durationOriginal = length(x) / Fs;
durationNoFilter = length(yNoFilter) / FsNoFilter;

%% Reduce the sampling rate with anti-aliasing filtering
% Filter the original x before reducing its rate. resample compensates delay.
% Keep the filter settings and coefficients for the team handoff.
filterDesignN = 10;
kaiserBeta = 5;
[yFiltered, filterCoefficients] = resample(x, 1, 2, filterDesignN, kaiserBeta);
FsFiltered = Fs / 2;
durationFiltered = length(yFiltered) / FsFiltered;

%% AA-03: Reconstruct onto the original sampling-rate grid
% This restores the sampling rate, not the information lost in downsampling.
yReconstructed = resample(yFiltered, 2, 1);
FsReconstructed = Fs;

% Compare sample counts.
[length(x), length(yFiltered), length(yReconstructed)]

% Match the original recording interval without optional edge trimming.
yAligned = yReconstructed(1:length(x));

% Reconstruct the unfiltered branch onto the original time grid.
yNoFilterReconstructed = resample(yNoFilter, 2, 1);
yNoFilterAligned = yNoFilterReconstructed(1:length(x));

%% Build the unfiltered output's single-sided amplitude spectrum
NNoFilter = length(yNoFilter);
fftNoFilter = fft(yNoFilter);

% Normalize the FFT and keep DC plus the positive-frequency bins.
magNoFilter = abs(fftNoFilter) / NNoFilter;
magNoFilter = magNoFilter(1:floor(NNoFilter/2) + 1);
fNoFilter = (0:floor(NNoFilter/2)) * FsNoFilter / NNoFilter;

% Double paired magnitudes; leave DC and any Nyquist bin unchanged.
if mod(NNoFilter, 2) == 0
    magNoFilter(2:end-1) = 2 * magNoFilter(2:end-1);
else
    magNoFilter(2:end) = 2 * magNoFilter(2:end);
end

figure
plot(fNoFilter, magNoFilter)
xlabel("Frequency (Hz)")
ylabel("Amplitude")
title("Downsampled Audio - Without Anti-Aliasing Filter")
grid on

%% Build the filtered output's single-sided amplitude spectrum
% Use the same FFT normalization and scaling for the filtered signal.
NFiltered = length(yFiltered);
fftFiltered = fft(yFiltered);

magFiltered = abs(fftFiltered) / NFiltered;
magFiltered = magFiltered(1:floor(NFiltered/2) + 1);
fFiltered = (0:floor(NFiltered/2)) * FsFiltered / NFiltered;

if mod(NFiltered, 2) == 0
    magFiltered(2:end-1) = 2 * magFiltered(2:end-1);
else
    magFiltered(2:end) = 2 * magFiltered(2:end);
end

figure
plot(fFiltered, magFiltered)
xlabel("Frequency (Hz)")
ylabel("Amplitude")
title("Downsampled Audio - With Anti-Aliasing Filter")
grid on

%% Compare both output spectra using their actual frequency axes
% Both use Fs/2. A known-tone comparison is still needed to identify aliasing.
comparisonFigure = figure('Theme', 'light');
set(comparisonFigure, 'Position', [100 100 1100 650]);
plot(fNoFilter, magNoFilter)
hold on
plot(fFiltered, magFiltered)
hold off

xlabel("Frequency (Hz)")
ylabel("Amplitude")
legend("Without filter", "With filter")
title("Filtered vs Unfiltered Downsampling")
grid on

%% Save the AA-02 handoff (MAT data, WAV copies, summary, and spectrum)
% MAT keeps double samples; WAV copies use 16-bit PCM. Quantization is Khaled's stage.
resultFolder = "../Results/Abdulrahman/AA02";
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
% Sample times start at zero; resample already compensates FIR delay.
prototype.alignmentStatus = 'AA-03: reconstruct at source Fs; retain the full original sample interval; no edge trimming.';

% Export at each signal's actual rate without changing its amplitude.
wavBitsPerSample = 16;
wavNoFilterName = [prototype.unfiltered.caseId '.wav'];
wavFilteredName = [prototype.filtered.caseId '.wav'];
wavNoFilterPath = fullfile(resultFolder, wavNoFilterName);
wavFilteredPath = fullfile(resultFolder, wavFilteredName);
audiowrite(wavNoFilterPath, yNoFilter, FsNoFilter, ...
    'BitsPerSample', wavBitsPerSample);
audiowrite(wavFilteredPath, yFiltered, FsFiltered, ...
    'BitsPerSample', wavBitsPerSample);

% Record WAV file sizes and the PCM conversion error for storage/quality analysis.
wavNoFilterSamples = audioread(wavNoFilterPath);
wavFilteredSamples = audioread(wavFilteredPath);
wavNoFilterFile = dir(wavNoFilterPath);
wavFilteredFile = dir(wavFilteredPath);
prototype.unfiltered.wav = struct('fileName', wavNoFilterName, ...
    'bitsPerSample', wavBitsPerSample, 'fileBytes', wavNoFilterFile.bytes, ...
    'maxAbsRoundTripError', max(abs(wavNoFilterSamples - yNoFilter)));
prototype.filtered.wav = struct('fileName', wavFilteredName, ...
    'bitsPerSample', wavBitsPerSample, 'fileBytes', wavFilteredFile.bytes, ...
    'maxAbsRoundTripError', max(abs(wavFilteredSamples - yFiltered)));
save(fullfile(resultFolder, 'sampling_22050.mat'), 'prototype', '-v7');

summaryTable = table( ...
    string({prototype.unfiltered.caseId; prototype.filtered.caseId}), ...
    ["none"; "lpf"], [FsNoFilter; FsFiltered], [NNoFilter; NFiltered], ...
    [durationNoFilter; durationFiltered], [0; 0], ...
    [(NNoFilter-1)/FsNoFilter; (NFiltered-1)/FsFiltered], ...
    [0; length(filterCoefficients)], [false; true], ...
    string({wavNoFilterName; wavFilteredName}), ...
    [wavBitsPerSample; wavBitsPerSample], ...
    [wavNoFilterFile.bytes; wavFilteredFile.bytes], ...
    [prototype.unfiltered.wav.maxAbsRoundTripError; ...
    prototype.filtered.wav.maxAbsRoundTripError], ...
    'VariableNames', {'CaseId', 'FilterMode', 'FsHz', 'SampleCount', ...
    'DurationSeconds', 'FirstSampleTimeSeconds', 'LastSampleTimeSeconds', ...
    'FIRTaps', 'FIRDelayCompensated', 'WavFileName', 'WavBitsPerSample', ...
    'WavFileBytes', 'WavMaxAbsRoundTripError'});
writetable(summaryTable, fullfile(resultFolder, 'summary.csv'));
exportgraphics(comparisonFigure, fullfile(resultFolder, 'comparison.png'), ...
    'Resolution', 160, 'BackgroundColor', comparisonFigure.Color);
fprintf('AA-02 outputs saved to: %s\n', resultFolder);
