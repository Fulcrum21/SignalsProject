%% Compare Simulink with MATLAB
% Run Sampling_Abdulrahman.m, then SamplingModel_Abdulrahman.slx first.
% Keep their workspace variables; run this script after Simulink creates out.
simNoFilterSamples = out.simNoFilter.Data(:);
simFilteredSamples = out.simFiltered.Data(:);

% Express the FIR filter delay in downsampled output samples.
delayInputSamples = (length(filterCoefficients) - 1) / 2;
delayOutputSamples = delayInputSamples / 2;

% Keep the original recording interval and compensate the known FIR delay.
simNoFilterAligned = simNoFilterSamples(1:length(yNoFilter));
simFilteredAligned = simFilteredSamples( ...
    delayOutputSamples + 1 : delayOutputSamples + length(yFiltered));

% These compare implementations, not degradation relative to original audio.
maxDifferenceNoFilter = max(abs(simNoFilterAligned - yNoFilter))
maxDifferenceFiltered = max(abs(simFilteredAligned - yFiltered))
