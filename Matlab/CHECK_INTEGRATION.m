function CHECK_INTEGRATION(folder,handoffFile)
% Check the final outputs against source inputs and actual file metadata.
% In particular, do not mistake tiny input differences at a quantizer decision
% boundary for an incorrect quantizer or claim the final signals are identical.
root=fileparts(fileparts(mfilename('fullpath')));
Check_Quantizer();
data=load(handoffFile,'cases','inputs'); cases=data.cases; inputs=data.inputs;
reference=audioread(fullfile(root,'Audios','SpeechMusic.wav'));
coverage=jesher.validateCases(cases,reference);
assert(all(coverage.status=="available") && numel(cases)==72);
metrics=readtable(fullfile(folder,'metrics.csv'),'TextType','string');
assert(height(metrics)==72 && numel(unique(metrics.caseId))==72);
assert(all(metrics.comparisonSampleCount==numel(reference)) && ...
    all(metrics.comparisonFirstTimeSeconds==0));
for k=1:numel(cases)
    c=cases(k);
    input=inputs(strcmp({inputs.caseId},c.samplingInputCaseId));
    expected=Uniform_Quantize(input.samples,c.effectiveBits);
    assert(isequal(c.samples,expected) && isequal(c.quantizationError,input.samples-c.samples));
    assert(c.Fs==input.Fs && c.firstSampleTimeSeconds==input.firstSampleTimeSeconds && ...
        c.delayCompensated==input.delayCompensated && ~c.normalizationApplied);
    r=metrics(metrics.caseId==string(c.caseId),:);
    path=fullfile(folder,'audio_package',char(r.wavFile));
    info=audioinfo(path); file=dir(path);
    assert(info.TotalSamples==numel(c.samples) && info.SampleRate==c.Fs && ...
        info.NumChannels==1 && info.BitsPerSample==16 && file.bytes==r.wavFileBytes);
    assert(isequal(audioread(path),double(int16(round(c.samples*32768)))/32768));
    if c.effectiveBits<16, assert(r.wavMaxAbsRoundTripError==0); end
end
finite=metrics.nmse>0 & isfinite(metrics.nmse);
assert(all(abs(metrics.snrDb(finite)+10*log10(metrics.nmse(finite)))<1e-10));
native=metrics(metrics.Fs==44100 & metrics.effectiveBits==16,:);
assert(all(native.nmse==0 & native.exportedNmse==0 & isinf(native.snrDb)));

%% Compare all 36 actual platform pairs, including quantizer threshold crossings.
matlabCases=cases(strcmp({cases.platform},'matlab')); rows=struct([]);
for k=1:numel(matlabCases)
    a=matlabCases(k);
    b=cases(strcmp({cases.caseId},strrep(a.caseId,'_matlab','_simulink')));
    ia=inputs(strcmp({inputs.caseId},a.samplingInputCaseId));
    ib=inputs(strcmp({inputs.caseId},b.samplingInputCaseId));
    inputDifference=max(abs(ia.samples-ib.samples));
    tolerance=1e-10; if strcmp(a.filterMode,'lpf'), tolerance=1e-12; end
    assert(inputDifference<=tolerance,'Sampling-stage agreement failed.');
    difference=abs(a.samples-b.samples); changed=difference>0;
    boundaryChanges=0; status="identical";
    if a.effectiveBits==16
        assert(max(difference)<=tolerance);
        if any(changed), status="sampling_roundoff"; end
    elseif any(changed)
        d=a.quantizer.step;
        % A tiny sampling difference can straddle an exact half-step boundary.
        distance=d*abs(ia.samples(changed)/d-(floor(ia.samples(changed)/d)+0.5));
        assert(all(difference(changed)==d) && ...
            all(distance<=inputDifference+16*eps(1)), ...
            'A quantizer difference cannot be explained by input boundary roundoff.');
        boundaryChanges=nnz(changed); status="explained_boundary_roundoff";
    end
    wa=audioread(fullfile(folder,'audio_package','processed',[a.caseId '.wav']));
    wb=audioread(fullfile(folder,'audio_package','processed',[b.caseId '.wav']));
    row=struct('conditionId',string(strrep(a.caseId,'_matlab','')), ...
        'Fs',a.Fs,'effectiveBits',a.effectiveBits,'filterMode',string(a.filterMode), ...
        'samplingMaxAbsDifference',inputDifference,'samplingTolerance',tolerance, ...
        'quantizedMaxAbsDifference',max(difference),'differingSamples',nnz(changed), ...
        'explainedBoundarySamples',boundaryChanges,'wavMaxAbsDifference',max(abs(wa-wb)), ...
        'status',status);
    if k==1, rows=row; else, rows(k)=row; end
end
writetable(struct2table(rows),fullfile(folder,'integration_comparison.csv'));
assert(isfile(fullfile(folder,'audio_all_cases_UNREVIEWED.zip')));
fprintf('PASS: all 72 files, metadata, errors, metrics and 36 actual platform pairs.\n');
fprintf('Listening and team sign-off must be performed by the students.\n');
close_system('Quantization_Khaled',0);
end
