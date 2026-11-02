function CHECK_COMPATIBILITY()
%% Read the exact handoff and verify regenerated sampling methods.
demoFolder=fileparts(mfilename('fullpath'));
projectFolder=fileparts(fileparts(demoFolder));
addpath(fullfile(projectFolder,'Jesher','matlab'));
handoffPath=fullfile(projectFolder,'Results','Abdulrahman','Sampling','sampling_all_rates.mat');
saved=load(handoffPath);
[cases,reference,sourceFs]=jesher.loadAvailableCases(projectFolder,{handoffPath});
assert(numel(cases)==9 && numel(unique(string({cases.caseId})))==9);
settings=SETTINGS();
settings.bits=16;
settings.outputFolder=fullfile(demoFolder,'Results','Checks');
samplingRows=struct([]);
for j=1:numel(saved.samplingHandoff.cases)
    entry=saved.samplingHandoff.cases(j);
    imported=cases(strcmp({cases.caseId},entry.caseId));
    assert(isequal(imported.samples,entry.samples),'Import changed the supplied array.');
    assert(imported.delayCompensated && ~imported.quantizationApplied && ...
        ~imported.normalizationApplied && imported.effectiveBits==16);
    settings.targetFs=entry.Fs; settings.filterMode=entry.filterMode;
    [matlabResult,regenerated]=run_case('matlab',settings,false);
    difference=max(abs(regenerated-entry.samples));
    assert(difference<1e-12,'Regenerated MATLAB method differs from the producer.');
    aligned=resample(entry.samples,entry.q,entry.p,10,5);
    [nmse,snrDb]=quality_metrics(reference,aligned(1:numel(reference)));
    assert(abs(nmse-matlabResult.ProcessingNMSE)<1e-12);
    assert(abs(snrDb-matlabResult.ProcessingSNRdB)<1e-9);
    samplingRows=[samplingRows;struct('CaseID',string(entry.caseId),'Samples',numel(entry.samples), ...
        'RateHz',entry.Fs,'ImportedMaxDifference',0,'RegeneratedMaxDifference',difference, ...
        'ProcessingNMSE',nmse,'ProcessingSNRdB',snrDb)]; %#ok<AGROW>
end
writetable(struct2table(samplingRows),fullfile(settings.outputFolder,'handoff_checks.csv'));

%% Diagnose 300 Hz timing on both platforms; never apply the measured lag.
settings.audioFile=fullfile(projectFolder,'Audios','300Hz_Sine.wav');
[tone,toneFs]=audioread(settings.audioFile);
assert(toneFs==sourceFs);
timingRows=struct([]);
for rate=[22050 11025 8000 4000]
    settings.targetFs=rate;
    for mode={'none','lpf'}
        settings.filterMode=mode{1};
        for platform={'matlab','simulink'}
            [result,processed]=run_case(platform{1},settings,false);
            divisor=gcd(toneFs,rate);
            aligned=resample(processed,toneFs/divisor,rate/divisor,10,5);
            aligned=aligned(1:numel(tone));
            [correlation,lags]=xcorr(aligned,tone,20);
            [~,peak]=max(correlation); residualLag=lags(peak);
            magnitude=abs(fft(aligned));
            [~,peak]=max(magnitude(1:floor(numel(aligned)/2)+1));
            dominantHz=(peak-1)*toneFs/numel(aligned);
            assert(residualLag==0 && abs(dominantHz-300)<1);
            assert(result.ComparisonSamples==numel(tone) && result.ComparisonStartSeconds==0);
            timingRows=[timingRows;struct('Platform',string(platform{1}),'RateHz',rate, ...
                'Filter',string(mode{1}),'DominantHz',dominantHz, ...
                'ResidualLagSourceSamples',residualLag,'ComparisonSamples',numel(tone))]; %#ok<AGROW>
        end
    end
end
writetable(struct2table(timingRows),fullfile(settings.outputFolder,'timing_checks.csv'));

%% Check 10 kHz aliasing for integer and noninteger conversion routes.
settings.audioFile=fullfile(projectFolder,'Audios','10kHz_Sine.wav');
aliasRows=struct([]);
for rate=[11025 8000]
    settings.targetFs=rate;
    expectedAlias=abs(10000-rate);
    for platform={'matlab','simulink'}
        settings.filterMode='none';
        [~,unfiltered]=run_case(platform{1},settings,false);
        settings.filterMode='lpf';
        [~,filtered]=run_case(platform{1},settings,false);
        % Edges omitted ONLY for this frequency diagnostic, never quality scoring.
        keep=round(0.1*rate)+1:numel(unfiltered)-round(0.1*rate);
        magnitude=abs(fft(unfiltered(keep)));
        [~,peak]=max(magnitude(1:floor(numel(keep)/2)+1));
        dominantHz=(peak-1)*rate/numel(keep);
        suppressionDb=20*log10(norm(unfiltered(keep))/norm(filtered(keep)));
        assert(abs(dominantHz-expectedAlias)<1 && suppressionDb>40);
        aliasRows=[aliasRows;struct('Platform',string(platform{1}),'RateHz',rate, ...
            'ExpectedAliasHz',expectedAlias,'MeasuredAliasHz',dominantHz, ...
            'FilteredRmsReductionDb',suppressionDb)]; %#ok<AGROW>
    end
end
writetable(struct2table(aliasRows),fullfile(settings.outputFolder,'alias_checks.csv'));
%% A direct Run must reload SETTINGS rather than reuse a previous matrix case.
workspace=get_param('Audio_Demo','ModelWorkspace');
assignin(workspace,'demoConfig',settings); % Deliberately stale tone settings.
assignin(workspace,'demoOverride',false);
directRun=sim('Audio_Demo','StopTime','0','ReturnWorkspaceOutputs','on');
defaults=SETTINGS();
[~,expected]=run_case('matlab',defaults,false);
assert(isequal(directRun.processed_samples(:),expected), ...
    'Direct model Run did not reload SETTINGS.');
fprintf('PASS: 8 exact imported arrays, 8 matching regenerated controls, 16 timing checks, 4 alias checks and direct model Run.\n');
end
