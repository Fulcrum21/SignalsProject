%% Verify the saved MATLAB handoff without changing the sampling arrays
% Set Current Folder to Matlab. Run after Prepare_Sampling_Handoff.
resultFolder = "../Results/Abdulrahman/Sampling";
saved = load(fullfile(resultFolder, 'sampling_all_rates.mat'));
handoff = saved.samplingHandoff;
[source, sourceFs] = audioread("../Audios/SpeechMusic.wav");
assert(isequal(source, handoff.original.samples) && sourceFs == handoff.original.Fs, ...
    'Handoff does not match the current reference.');
assert(length(handoff.cases) == 8, 'Expected eight MATLAB sampling cases.');
manifest = readtable(fullfile(resultFolder, 'case_manifest.csv'), 'TextType', 'string');
assert(height(manifest) == 8 && length(unique(manifest.caseId)) == 8, ...
    'The manifest has missing or duplicate cases.');
expectedRates = [22050 22050 11025 11025 8000 8000 4000 4000];
expectedCounts = [441003 441003 220502 220502 160001 160001 80001 80001];
assert(~handoff.quantizationApplied && ~handoff.normalizationApplied);

for caseIndex = 1:8
    entry = handoff.cases(caseIndex);
    assert(entry.Fs == expectedRates(caseIndex));
    assert(entry.sampleCount == expectedCounts(caseIndex));
    assert(isequal(size(entry.samples), [entry.sampleCount 1]));
    assert(all(isfinite(entry.samples)));
    assert(abs(sourceFs*entry.p/entry.q-entry.Fs) < 1e-9);
    assert(abs(entry.durationSeconds-length(source)/sourceFs) < 1/entry.Fs);
    assert(entry.firstSampleTimeSeconds == 0);
    assert(entry.lastSampleTimeSeconds <= (length(source)-1)/sourceFs + eps);

    % Independently check the declared processing method.
    if strcmp(entry.filterMode, 'lpf')
        expected = resample(source, entry.p, entry.q, 10, 5);
        expected = expected(1:entry.sampleCount);
        assert(entry.delayCompensatedByResample);
        assert(length(entry.filterCoefficients) == 2*10*max(entry.p,entry.q)+1);
        assert(entry.coefficientFsHz == sourceFs*entry.p);
    elseif mod(sourceFs,entry.Fs) == 0
        expected = source(1:sourceFs/entry.Fs:end);
        assert(isempty(entry.filterCoefficients));
    else
        sourceTime = (0:length(source)-1)'/sourceFs;
        outputTime = (0:entry.sampleCount-1)'/entry.Fs;
        expected = interp1(sourceTime, source, outputTime, 'linear');
        assert(isempty(entry.filterCoefficients));
    end
    assert(isequal(entry.samples, expected), 'Stored processing result differs.');

    % The inverse ratio restores the source grid; retain the original interval.
    reconstructed = resample(entry.samples, entry.q, entry.p);
    assert(length(reconstructed) >= length(source), 'Reference interval is not covered.');
    aligned = reconstructed(1:length(source));
    assert(all(isfinite(aligned)) && length(aligned) == entry.validReferenceSamples);

    wavPath = fullfile(resultFolder, entry.wavFileName);
    info = audioinfo(wavPath);
    [readBack, readBackFs] = audioread(wavPath);
    assert(info.BitsPerSample == 16 && info.NumChannels == 1);
    assert(readBackFs == entry.Fs && isequal(size(readBack), size(entry.samples)));
    error = max(abs(readBack-entry.samples));
    assert(error <= 2^-15 + 1e-12, 'Unexpected PCM conversion error.');
    assert(abs(error-entry.wavMaxAbsRoundTripError) < 1e-15);
    fileInfo = dir(wavPath);
    assert(fileInfo.bytes == entry.wavFileBytes);
    assert(string(entry.caseId) == manifest.caseId(caseIndex));
    assert(entry.sampleCount == manifest.sampleCount(caseIndex));
    assert(entry.Fs == manifest.Fs(caseIndex));
end

%% Check the common-grid timing with the existing 300 Hz tone
% This diagnoses lag; it never shifts a signal to improve agreement.
[knownTone, knownFs] = audioread("../Audios/300Hz_Sine.wav");
assert(knownFs == sourceFs);
for caseIndex = 1:8
    entry = handoff.cases(caseIndex);
    if strcmp(entry.filterMode, 'lpf')
        testOutput = resample(knownTone, entry.p, entry.q, 10, 5);
    elseif mod(knownFs,entry.Fs) == 0
        testOutput = knownTone(1:knownFs/entry.Fs:end);
    else
        knownTime = (0:length(knownTone)-1)'/knownFs;
        testTime = (0:floor(knownTime(end)*entry.Fs))'/entry.Fs;
        testOutput = interp1(knownTime, knownTone, testTime, 'linear');
    end
    testReconstructed = resample(testOutput, entry.q, entry.p);
    testAligned = testReconstructed(1:length(knownTone));
    [correlation, lags] = xcorr(testAligned, knownTone, 20);
    [~, bestIndex] = max(correlation);
    lagSamples(caseIndex,1) = lags(bestIndex);
    testMagnitude = abs(fft(testAligned));
    [~, toneIndex] = max(testMagnitude(1:floor(length(knownTone)/2)+1));
    dominantHz(caseIndex,1) = (toneIndex-1)*knownFs/length(knownTone);
    assert(lagSamples(caseIndex) == 0 && abs(dominantHz(caseIndex)-300) < 1);
end
timingChecks = table(string({handoff.cases.caseId})', dominantHz, lagSamples, ...
    'VariableNames', {'CaseId', 'KnownToneDominantHz', 'ResidualLagSourceSamples'});
writetable(timingChecks, fullfile(resultFolder, 'alignment_checks.csv'));

aliasTable = readtable(fullfile(resultFolder, 'aliasing_summary.csv'));
assert(abs(aliasTable.PeakHz(1)-10000) < 1);
assert(abs(aliasTable.PeakHz(2)-1025) < 1);
assert(aliasTable.PeakAmplitude(3) < aliasTable.PeakAmplitude(2)/100);
for rate = [22050 11025 8000 4000]
    for prefix = ["waveforms", "spectra", "spectrograms"]
        assert(isfile(fullfile(resultFolder, prefix + "_" + rate + ".png")));
    end
end
fprintf('PASS: eight cases, source/rates/counts, processing methods, reconstruction coverage, 300 Hz timing, WAV round trips, manifest and aliasing checks.\n');
