function [result,processed] = run_case(platform,settings,showPlots)
% RUN_CASE: source -> sampling -> quantization -> WAV -> aligned NMSE/SNR.
% Used by the two single-case scripts and RUN_ALL. No old handoff files needed.
if nargin<3, showPlots=true; end
platform = lower(char(platform));
assert(ismember(string(platform),["matlab","simulink"]),'Unknown platform.');
data = prepare_audio(settings);
folder = fileparts(mfilename('fullpath'));

%% 1. Sampling and uniform quantization, on the selected platform.
if strcmp(platform,'matlab')
    if strcmp(data.mode,'native')
        sampled = data.x;
    elseif strcmp(data.mode,'lpf')
        sampled = resample(data.x,data.p,data.q,10,5);
    else
        sampled = data.x(data.directIndices); % No hidden low-pass filtering.
    end
    if settings.bits==16
        processed = sampled;                 % Unchanged source/control precision.
    else
        levelIndex = round(sampled/data.quantStep);
        levelIndex = min(data.quantMax,max(data.quantMin,levelIndex));
        processed = levelIndex*data.quantStep;
    end
    aligned = reconstruct(processed,data,settings.targetFs);
else
    model = 'Audio_Demo';
    if ~isfile(fullfile(folder,[model '.slx'])), build_model(); end
    if ~bdIsLoaded(model), load_system(fullfile(folder,[model '.slx'])); end
    workspace = get_param(model,'ModelWorkspace');
    assignin(workspace,'demoConfig',settings);
    assignin(workspace,'demoOverride',true);
    resetOverride=onCleanup(@()assignin(workspace,'demoOverride',false)); %#ok<NASGU>
    setup_model(model); % Also refresh tunable values during Fast Restart.
    out = sim(model,'StopTime','0','ReturnWorkspaceOutputs','on');
    sampled = out.sampled_samples(:);
    processed = out.processed_samples(:);
    aligned = out.aligned_samples(:);
    [checkNMSE,checkSNR] = quality_metrics(data.x,aligned);
    assert(sameMetric(checkNMSE,out.nmse_model(end),1e-11), ...
        'Simulink NMSE arithmetic differs from the MATLAB definition.');
    assert(sameMetric(checkSNR,out.snr_model(end),1e-8), ...
        'Simulink SNR arithmetic differs from the MATLAB definition.');
    matlabAligned = reconstruct(processed,data,settings.targetFs);
    assert(numel(aligned)==data.N && max(abs(aligned-matlabAligned))<1e-10, ...
        'Simulink reconstruction does not match the original time grid.');
end
processed = processed(:);
assert(numel(processed)==data.outputCount,'Unexpected output sample count.');
if settings.bits<16
    assert(numel(unique(processed))<=2^settings.bits,'Too many quantization levels.');
end
[processingNMSE,processingSNR] = quality_metrics(data.x,aligned);

%% 2. Export at the ACTUAL audio rate in a 16-bit PCM carrier.
% Effective bits describe levels; the WAV carrier remains 16 bits.
if ~isfolder(settings.outputFolder), mkdir(settings.outputFolder); end
[~,sourceName] = fileparts(settings.audioFile);
sourceName = lower(regexprep(sourceName,'[^A-Za-z0-9]',''));
caseId = sprintf('%s_fs%d_b%02d_%s_%s',sourceName,settings.targetFs,settings.bits,data.mode,platform);
wavFile = fullfile(settings.outputFolder,[caseId '.wav']);
clippedSamples = nnz(processed < -1 | processed > 1-1/32768);
pcm = int16(min(32767,max(-32768,round(processed*32768))));
audiowrite(wavFile,pcm,settings.targetFs,'BitsPerSample',16);
[exported,actualRate] = audioread(wavFile);
info = audioinfo(wavFile); file = dir(wavFile);
assert(actualRate==settings.targetFs && numel(exported)==numel(processed));
assert(info.NumChannels==1 && info.BitsPerSample==16);

%% 3. Evaluate the exported WAV against the original at equal physical times.
exportedAligned = reconstruct(exported,data,settings.targetFs);
[nmse,snrDb] = quality_metrics(data.x,exportedAligned);
maximumExportError = max(abs(exported-processed));
if clippedSamples==0
    assert(maximumExportError<=0.5/32768+1e-14,'Unexpected PCM export conversion.');
end
result = struct('CaseID',string(caseId),'Platform',string(platform), ...
    'Source',string(settings.audioFile),'RateHz',settings.targetFs, ...
    'Bits',settings.bits,'Filter',string(data.mode),'Samples',numel(processed), ...
    'DurationSeconds',numel(processed)/settings.targetFs, ...
    'ComparisonSamples',data.N,'ComparisonStartSeconds',0,'ComparisonEndSeconds',(data.N-1)/data.Fs, ...
    'NMSE',nmse,'SNRdB',snrDb,'ProcessingNMSE',processingNMSE, ...
    'ProcessingSNRdB',processingSNR,'WavContainerBits',16,'WavBytes',file.bytes, ...
    'WavMaxSampleError',maximumExportError,'WavClippedSamples',clippedSamples, ...
    'WavFile',string(wavFile));
if showPlots
    make_plots(data.x,exportedAligned,data.Fs,sampled-processed,settings.targetFs, ...
        caseId,settings.outputFolder);
end
end

function aligned = reconstruct(samples,data,rate)
if rate==data.Fs
    aligned=samples;
else
    aligned=resample(samples,data.q,data.p,10,5);
    assert(numel(aligned)>=data.N,'Processed samples do not cover original interval.');
    aligned=aligned(1:data.N); % Only deterministic end-grid rounding is discarded.
end
end
function same = sameMetric(a,b,tolerance)
same = isequaln(a,b) || (isfinite(a) && isfinite(b) && abs(a-b)<=tolerance);
end
