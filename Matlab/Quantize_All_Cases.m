function handoffFile = Quantize_All_Cases()
% Apply the quantizer to 18 REAL sampling routes, with four precision settings.
% The sample rate, time origin, filter method and source provenance are retained.
root=fileparts(fileparts(mfilename('fullpath')));
inputs=Load_Sampling_Inputs();
bitsList=[16 8 4 2]; cases=struct([]); rows=struct([]); number=0;
for k=1:numel(inputs)
    input=inputs(k);
    for bits=bitsList
        number=number+1;
        [expected,~,q]=Uniform_Quantize(input.samples,bits);
        if strcmp(input.platform,'simulink')
            [output,errorSignal]=Quantize_Simulink(input.samples,bits);
            % SAME input: isolate the quantizer arithmetic from sampling differences.
            assert(isequal(output,expected),'MATLAB/Simulink quantizers disagree on identical input.');
        else
            output=expected; errorSignal=input.samples-output;
        end
        c=input;
        c.caseId=sprintf('speechmusic_fs%d_b%02d_%s_%s',input.Fs,bits,input.filterMode,input.platform);
        c.effectiveBits=bits; c.samples=output;
        c.quantizationApplied=(bits<16);
        if bits<16
            c.processingStage='sampling_then_quantization';
            if input.Fs==44100, c.processingStage='native_quantization'; end
        end
        c.quantizerDescription=sprintf(['Signed uniform midtread; delta=2/2^%d; round half away from zero; ' ...
            'index clipped to [%g,%g]; 16-bit setting bypasses; no normalization.'], ...
            bits,q.minimumIndex,q.maximumIndex);
        c.provenance=sprintf('%s Quantizer: %s; input case %s.',input.provenance,input.platform,input.caseId);
        c.quantizer=q; c.quantizationError=errorSignal; c.samplingInputCaseId=input.caseId;
        if number==1, cases=c; else, cases(number)=c; end
        m=jesher.computeMetrics(input.samples,output);
        r=struct('caseId',string(c.caseId),'samplingInputCaseId',string(input.caseId), ...
            'platform',string(input.platform),'Fs',input.Fs,'effectiveBits',bits, ...
            'filterMode',string(input.filterMode),'sampleCount',numel(output), ...
            'step',q.step,'quantizationApplied',q.applied,'distinctOutputLevels',numel(unique(output)), ...
            'saturatedSamples',q.saturatedSamples,'errorMean',mean(errorSignal), ...
            'errorMSE',mean(errorSignal.^2),'errorVariance',var(errorSignal,1), ...
            'idealDeltaSquaredOver12',q.step^2/12,'maxAbsError',max(abs(errorSignal)), ...
            'quantizationOnlyNMSE',m.nmse,'quantizationOnlySNRdB',m.snrDb);
        if bits==16, r.idealDeltaSquaredOver12=NaN; end % No active quantizer.
        if number==1, rows=r; else, rows(number)=r; end
        fprintf('Quantized %2d/72: %s\n',number,c.caseId);
    end
end
folder=fullfile(root,'Results','Khaled'); if ~isfolder(folder), mkdir(folder); end
handoffFile=fullfile(folder,'quantized_cases.mat');
save(handoffFile,'cases','inputs','-v7'); % Local audio arrays and isolated errors.
writetable(struct2table(rows),fullfile(folder,'quantization_summary.csv'));
close_system('Quantization_Khaled',0);
end
