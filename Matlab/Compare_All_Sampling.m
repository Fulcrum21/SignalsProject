%% Verify all four saved Simulink sampling models
% Set Current Folder to the repository root, then run:
% addpath("Matlab"); Compare_All_Sampling
% Requires Signal Processing Toolbox, Simulink and DSP System Toolbox.
saved = load("Results/Abdulrahman/Sampling/sampling_all_rates.mat");
handoff = saved.samplingHandoff;
filterCoefficients = handoff.cases(2).filterCoefficients;
filterCoefficients11025 = handoff.cases(4).filterCoefficients;
filterCoefficients8000 = handoff.cases(6).filterCoefficients;
filterCoefficients4000 = handoff.cases(8).filterCoefficients;
models = ["SamplingModel_Abdulrahman", "SamplingModel_11025_Abdulrahman", ...
    "SamplingModel_8000_Abdulrahman", "SamplingModel_4000_Abdulrahman"];
filterModes = ["none", "lpf"];
caseIndex = 0;

for rateIndex = 1:4
    load_system(fullfile("Simulink", models(rateIndex) + ".slx"));
    assert(strcmp(get_param(models(rateIndex),'Dirty'),'off'), ...
        'Save your model edits before running this saved-model comparison.');
    % Bypass only the visual spectrogram during automated comparison.
    % This avoids a scope-UI callback error; sampling/logging remain active.
    viewer = models(rateIndex) + "/Spectrogram";
    set_param(viewer, 'Commented', 'on');
    % Use the complete recording even if a display-only run used 19.9 s.
    out = sim(models(rateIndex), 'StopTime', '20');
    outputs = {out.simNoFilter.Data(:), out.simFiltered.Data(:)};
    for modeIndex = 1:2
        caseIndex = caseIndex + 1;
        referenceCase = handoff.cases(caseIndex);
        delay = 0;
        if modeIndex == 2
            delay = (length(referenceCase.filterCoefficients)-1)/(2*referenceCase.q);
        end
        raw = outputs{modeIndex};
        N = referenceCase.sampleCount;
        assert(delay == fix(delay) && length(raw) >= delay+N, ...
            'Missing recording coverage or unexpected fractional delay.');
        aligned = raw(delay+1:delay+N);
        difference(caseIndex,1) = max(abs(aligned-referenceCase.samples));
        tolerance = 1e-10;
        if modeIndex == 2, tolerance = 1e-12; end
        assert(difference(caseIndex) <= tolerance, 'MATLAB/Simulink comparison failed.');
        rates(caseIndex,1) = referenceCase.Fs;
        modes(caseIndex,1) = filterModes(modeIndex);
        counts(caseIndex,1) = N;
        delays(caseIndex,1) = delay;
        tolerances(caseIndex,1) = tolerance;
        modelNames(caseIndex,1) = models(rateIndex);

        % Exact aligned Simulink outputs, compatible with Jesher's cases schema.
        c.caseId = strrep(referenceCase.caseId, '_matlab', '_simulink');
        c.platform = 'simulink';
        c.sourceFile = handoff.sourceFile;
        c.samples = aligned;
        c.Fs = referenceCase.Fs;
        c.effectiveBits = 16;
        c.filterMode = referenceCase.filterMode;
        c.firstSampleTimeSeconds = 0;
        c.delayCompensated = true;
        c.processingStage = 'sampling_only_control';
        c.quantizationApplied = false;
        c.normalizationApplied = false;
        c.quantizerDescription = 'b16 source/control; double sampling array, no additional quantizer.';
        c.samplingDescription = sprintf('%s; actual model output; removed %d known output-delay samples; retained %d samples.', ...
            models(rateIndex), delay, N);
        c.provenance = sprintf('Compare_All_Sampling; saved model %s; MATLAB %s; run %s.', ...
            models(rateIndex), version('-release'), datestr(now,30));
        c.alignmentPolicy = 'full_record_resample_v1';
        cases(caseIndex) = c;
    end
    % Discard the viewer-only bypass; the saved model is never overwritten.
    close_system(models(rateIndex), 0);
end
comparison = table(rates, modes, counts, delays, difference, tolerances, modelNames, ...
    'VariableNames', {'FsHz','FilterMode','SampleCount','RemovedDelayOutputSamples', ...
    'MaxAbsDifference','Tolerance','ModelName'});
folder = "Results/Abdulrahman/Sampling";
writetable(comparison, fullfile(folder, 'simulink_comparison.csv'));
save(fullfile(folder, 'simulink_cases.mat'), 'cases', '-v7');
disp(comparison)
fprintf('PASS: eight actual Simulink outputs match their MATLAB references.\n');
