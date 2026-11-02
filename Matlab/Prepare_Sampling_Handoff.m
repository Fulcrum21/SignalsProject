%% Prepare all eight MATLAB sampling cases
% Set Current Folder to Matlab. Run once after changing the sampling code.
% This packages results; it does not run Simulink or apply quantization.
Sampling_OtherRates
firstCase = load("../Results/Abdulrahman/AA02/sampling_22050.mat");
assert(isequal(firstCase.prototype.original.samples, x), ...
    'The AA-02 reference differs from the current recording. Regenerate AA-02 first.');
assert(firstCase.prototype.original.Fs == Fs, 'Source rates differ.');

resultFolder = "../Results/Abdulrahman/Sampling";
if ~isfolder(resultFolder)
    mkdir(resultFolder);
end

%% Combine the existing 22.05 kHz case with the three new rates
rateResults(1).Fs = firstCase.prototype.filtered.Fs;
rateResults(1).unfiltered = firstCase.prototype.unfiltered.samples;
rateResults(1).filtered = firstCase.prototype.filtered.samples;
rateResults(1).unfilteredMethod = "Direct sample selection";
rateResults(1).p = 1;
rateResults(1).q = 2;
rateResults(1).filterCoefficients = firstCase.prototype.filter.coefficients;
rateResults(1).sampleCount = length(rateResults(1).filtered);
rateResults(1).durationSeconds = rateResults(1).sampleCount / rateResults(1).Fs;
rateResults(1).lastSampleTimeSeconds = ...
    (rateResults(1).sampleCount-1) / rateResults(1).Fs;
rateResults(2:4) = otherRates;

samplingHandoff.schemaVersion = 1;
samplingHandoff.sourceFile = 'Audios/SpeechMusic.wav';
samplingHandoff.platform = 'MATLAB';
samplingHandoff.matlabRelease = version('-release');
samplingHandoff.sourceBitsPerSample = 16;
samplingHandoff.processingStage = 'sampling_only';
samplingHandoff.quantizationApplied = false;
samplingHandoff.normalizationApplied = false;
samplingHandoff.original = firstCase.prototype.original;
samplingHandoff.alignment = ...
    'Reconstruct with resample(samples,q,p); retain the full original sample interval. No extra delay shift, normalization, or edge trimming.';

%% Save each rate/filter case and its playback copy
filterModes = ["none", "lpf"];
caseIndex = 0;
for rateIndex = 1:4
    rate = rateResults(rateIndex);
    assert(length(rate.unfiltered) == length(rate.filtered), 'Branch lengths differ.');
    for modeIndex = 1:2
        caseIndex = caseIndex + 1;
        entry.caseId = sprintf('speechmusic_fs%d_b16_%s_matlab', ...
            rate.Fs, filterModes(modeIndex));
        entry.Fs = rate.Fs;
        entry.filterMode = char(filterModes(modeIndex));
        entry.p = rate.p;
        entry.q = rate.q;
        if modeIndex == 1
            entry.samples = rate.unfiltered;
            entry.method = char(rate.unfilteredMethod);
            entry.filterCoefficients = [];
            entry.coefficientFsHz = 0;
            entry.rawFilterDelaySeconds = 0;
        else
            entry.samples = rate.filtered;
            entry.method = 'resample(x,p,q,10,5); retain source time interval';
            entry.filterCoefficients = rate.filterCoefficients;
            % For rational conversion the FIR operates at the upsampled rate.
            entry.coefficientFsHz = Fs * rate.p;
            entry.rawFilterDelaySeconds = ...
                (length(rate.filterCoefficients)-1) / (2*entry.coefficientFsHz);
        end
        entry.filterDesignN = 10 * (modeIndex == 2);
        entry.kaiserBeta = 5 * (modeIndex == 2);
        entry.delayCompensatedByResample = (modeIndex == 2);
        entry.sampleCount = length(entry.samples);
        entry.durationSeconds = entry.sampleCount / entry.Fs;
        entry.firstSampleTimeSeconds = 0;
        entry.lastSampleTimeSeconds = (entry.sampleCount-1) / entry.Fs;
        entry.reconstructionP = rate.q;
        entry.reconstructionQ = rate.p;
        entry.validReferenceSamples = length(x);
        entry.wavFileName = [entry.caseId '.wav'];
        entry.wavBitsPerSample = 16;

        % Keep the double arrays unchanged. WAV is a 16-bit playback carrier.
        assert(iscolumn(entry.samples) && all(isfinite(entry.samples)), ...
            'Samples must be one finite mono column.');
        assert(min(entry.samples) >= -1 && max(entry.samples) <= 1-2^-15, ...
            'WAV export would clip; do not fix this by normalizing cases separately.');
        wavPath = fullfile(resultFolder, entry.wavFileName);
        audiowrite(wavPath, entry.samples, entry.Fs, 'BitsPerSample', 16);
        [readBack, readBackFs] = audioread(wavPath);
        assert(readBackFs == entry.Fs && isequal(size(readBack), size(entry.samples)), ...
            'WAV rate or dimensions changed.');
        entry.wavMaxAbsRoundTripError = max(abs(readBack-entry.samples));
        wavInfo = dir(wavPath);
        entry.wavFileBytes = wavInfo.bytes;
        samplingHandoff.cases(caseIndex) = entry;
    end
end
save(fullfile(resultFolder, 'sampling_all_rates.mat'), 'samplingHandoff', '-v7');

%% Write a compact case manifest without copying sample arrays into the CSV
caseMetadata = rmfield(samplingHandoff.cases, {'samples', 'filterCoefficients'});
caseManifest = struct2table(caseMetadata);
writetable(caseManifest, fullfile(resultFolder, 'case_manifest.csv'));

%% Save the known-tone aliasing demonstration and its measured peaks
Aliasing_Demo
set(gcf, 'Theme', 'light', 'Color', 'w', 'Position', [100 100 1100 900]);
set(findall(gcf, 'Type', 'axes'), 'FontSize', 12);
exportgraphics(gcf, fullfile(resultFolder, 'aliasing_10000_to_1025.png'), ...
    'Resolution', 160, 'BackgroundColor', 'white');
aliasSummary = table(["original"; "none"; "lpf"], demoRates', ...
    peakFrequencies', peakAmplitudes', ...
    'VariableNames', {'Signal', 'FsHz', 'PeakHz', 'PeakAmplitude'});
writetable(aliasSummary, fullfile(resultFolder, 'aliasing_summary.csv'));

%% Produce comparison figures and verify the files just written
Plot_Sampling_Comparisons
Check_Sampling_Handoff
fprintf('MATLAB sampling handoff saved to: %s\n', resultFolder);
