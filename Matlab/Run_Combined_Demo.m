function result = Run_Combined_Demo(settings)
% One selected actual handoff -> quantization -> WAV -> reconstruction -> metrics.
root=fileparts(fileparts(mfilename('fullpath')));
inputs=Load_Sampling_Inputs();
cases=Load_Khaled_Cases();
mode=settings.filterMode; if settings.Fs==44100, mode='native'; end
selected=[inputs.Fs]==settings.Fs & strcmp({inputs.filterMode},mode) & ...
    strcmp({inputs.platform},settings.platform);
assert(nnz(selected)==1,'Choose a valid rate, filter and platform in PROJECT_SETTINGS.');
c=inputs(selected); samplingInput=c.samples;
if strcmp(settings.platform,'simulink')
    [c.samples,errorSignal]=Run_Khaled_Quantizer(samplingInput,c.Fs,settings.bits);
else
    [c.samples,errorSignal]=Khaled_Quantizer(samplingInput,settings.bits);
end
c.caseId=sprintf('speechmusic_fs%d_b%02d_%s_%s',c.Fs,settings.bits,mode,settings.platform);
c.effectiveBits=settings.bits;
c.quantizationApplied=(settings.bits<16);
producerCase=cases(strcmp({cases.caseId},c.caseId));
assert(isscalar(producerCase) && isequal(c.samples,producerCase.samples), ...
    'Live result differs from Khaled''s saved handoff. Regenerate and check the inputs.');
folder=fullfile(root,'Results','Integrated','demo'); if ~isfolder(folder), mkdir(folder); end
wavFile=fullfile(folder,[c.caseId '.wav']);
wav=jesher.exportVerifiedWav(c.samples,c.Fs,wavFile);
original=audioread(fullfile(root,'Audios','SpeechMusic.wav'));
rawMetrics=jesher.computeMetrics(original,jesher.alignToReference(original,44100,c));
c.samples=audioread(wavFile);
aligned=jesher.alignToReference(original,44100,c);
exportedMetrics=jesher.computeMetrics(original,aligned);
addpath(fullfile(root,'Jesher','Demo'));
make_plots(original,aligned,44100,errorSignal,c.Fs,c.caseId,folder);
result=struct('caseId',c.caseId,'wavFile',wavFile,'Fs',c.Fs,'effectiveBits',settings.bits, ...
    'processingNMSE',rawMetrics.nmse,'processingSNRdB',rawMetrics.snrDb, ...
    'exportedNMSE',exportedMetrics.nmse,'exportedSNRdB',exportedMetrics.snrDb, ...
    'wavContainerBits',wav.containerBits,'wavBytes',wav.fileBytes);
end
