function Make_Integrated_Results(folder,handoffFiles)
% Tables and figures from this run only. Never insert old demo metrics here.
root=fileparts(fileparts(mfilename('fullpath')));
metrics=readtable(fullfile(folder,'metrics.csv'),'TextType','string');
storage=metrics(:,{'caseId','platform','Fs','effectiveBits','filterMode', ...
    'sampleCount','durationSeconds','nmse','snrDb','exportedNmse','exportedSnrDb', ...
    'wavContainerBits','wavFileBytes'});
storage.idealPackedPayloadBits=storage.sampleCount.*storage.effectiveBits;
storage.idealPackedPayloadBytes=ceil(storage.idealPackedPayloadBits/8);
storage.wavPcmPayloadBytes=2*storage.sampleCount;
storage.wavHeaderBytes=storage.wavFileBytes-storage.wavPcmPayloadBytes;
storage.idealBitRate=storage.Fs.*storage.effectiveBits;
storage.wavPcmBitRate=16*storage.Fs;
writetable(storage,fullfile(folder,'storage_quality.csv'));
listening=metrics(:,{'caseId','exportedNmse','exportedSnrDb'});
listening.listener=strings(height(metrics),1);
listening.deviceAndVolume=strings(height(metrics),1);
listening.observations=strings(height(metrics),1);
listening.heard=false(height(metrics),1);
writetable(listening,fullfile(folder,'listening_template.csv'));

%% Baseline and selected processed signals, with identical plot conventions.
cases=Load_Khaled_Cases(handoffFiles);
inputs=Load_Sampling_Inputs();
quantizationRows=struct([]);
for k=1:numel(cases)
    c=cases(k);
    input=inputs([inputs.Fs]==c.Fs & strcmp({inputs.filterMode},c.filterMode) & ...
        strcmp({inputs.platform},c.platform));
    assert(isscalar(input));
    errorSignal=c.quantizationError; d=c.quantizationStep;
    m=jesher.computeMetrics(input.samples,c.samples);
    saturated=0;
    if c.effectiveBits<16
        index=round(input.samples/d);
        saturated=nnz(index < -2^(c.effectiveBits-1) | index > 2^(c.effectiveBits-1)-1);
    end
    row=struct('caseId',string(c.caseId),'platform',string(c.platform), ...
        'Fs',c.Fs,'effectiveBits',c.effectiveBits,'filterMode',string(c.filterMode), ...
        'distinctOutputLevels',numel(unique(c.samples)),'saturatedSamples',saturated, ...
        'errorMSE',mean(errorSignal.^2),'errorMean',mean(errorSignal), ...
        'maxAbsError',max(abs(errorSignal)),'quantizationOnlyNMSE',m.nmse, ...
        'quantizationOnlySNRdB',m.snrDb);
    if k==1, quantizationRows=row; else, quantizationRows(k)=row; end
end
writetable(struct2table(quantizationRows),fullfile(folder,'quantization_summary.csv'));

%% Preserve the nine listening observations supplied on Khaled's branch.
% They concern his listening session/exports, not a new Jesher speaker check.
notes=readtable(fullfile(root,'Results','Khaled','Storage','KH06_Listening_Notes.csv'), ...
    'TextType','string');
[found,order]=ismember(metrics.caseId,notes.CaseID);
assert(all(found) && height(notes)==72 && numel(unique(notes.CaseID))==72);
notes=notes(order,:);
notes.JesherExportedNMSE=metrics.exportedNmse;
notes.JesherExportedSNRdB=metrics.exportedSnrDb;
notes.NotesSource=repmat("Khaled branch fa2fc06: KH06_Listening_Notes.csv",height(notes),1);
notes.JesherPlaybackVerified=false(height(notes),1);
writetable(notes,fullfile(folder,'listening_results.csv'));

%% Khaled's published quality table used a different reconstruction method.
% Compare processing-array metrics only, so WAV conversion is not mixed in.
prior=readtable(fullfile(root,'Results','Khaled','Storage', ...
    'KH06_Storage_Quality_Shareable_72.csv'),'TextType','string');
[found,order]=ismember(metrics.caseId,prior.CaseID); assert(all(found));
comparison=metrics(:,{'caseId','nmse','snrDb'});
comparison.JesherReconstruction=repmat("resample_10_5_full_record",height(metrics),1);
comparison.KhaledReconstruction=prior.ReconstructionMethod(order);
comparison.KhaledProcessingNMSE=prior.ProcessingNMSE(order);
comparison.KhaledProcessingSNRdB=prior.ProcessingSNRdB(order);
writetable(comparison,fullfile(folder,'reconstruction_comparison.csv'));
reference=audioread(fullfile(root,'Audios','SpeechMusic.wav'));
figureFolder=fullfile(folder,'figures'); if ~isfolder(figureFolder), mkdir(figureFolder); end
addpath(fullfile(root,'Jesher','Demo'));
selected={'speechmusic_fs44100_b08_native_matlab','speechmusic_fs44100_b04_native_matlab', ...
    'speechmusic_fs44100_b02_native_matlab','speechmusic_fs22050_b08_lpf_matlab', ...
    'speechmusic_fs4000_b02_lpf_matlab','speechmusic_fs4000_b02_none_matlab'};
for k=1:numel(selected)
    c=cases(strcmp({cases.caseId},selected{k}));
    r=metrics(metrics.caseId==string(c.caseId),:);
    c.samples=audioread(fullfile(folder,'audio_package',char(r.wavFile)));
    aligned=jesher.alignToReference(reference,44100,c);
    make_plots(reference,aligned,44100,c.quantizationError,c.Fs,c.caseId,figureFolder);
    close(findall(0,'Type','figure','Tag','JesherDemo'));
end

%% Show native-rate quantization and storage without sampling as a confounder.
native=storage(storage.platform=="matlab" & storage.Fs==44100 & storage.effectiveBits<16,:);
native=sortrows(native,'effectiveBits');
f=figure('Visible','off','Theme','light','Color','white','Position',[80 80 1100 440]);
tiledlayout(1,2);
nexttile; plot(native.effectiveBits,native.exportedSnrDb,'o-','LineWidth',1.5); grid on;
xlabel('Effective quantizer bits'); ylabel('SNR (dB)'); xticks([2 4 8]);
title('Original-rate quantization only');
nexttile; bar(native.effectiveBits,[native.idealPackedPayloadBytes native.wavFileBytes]/1024);
grid on; xlabel('Effective quantizer bits'); ylabel('Storage (KiB)'); xticks([2 4 8]);
legend('Theoretical packed payload','Actual PCM16 WAV','Location','northwest');
title('Same 44.1 kHz recording and sample count');
exportgraphics(f,fullfile(figureFolder,'native_quality_storage.png'),'Resolution',160); close(f);

%% Known moderate-level sine: illustrate, rather than assume, the 6 dB/bit rule.
t=(0:88199)'/44100; tone=0.5*sin(2*pi*997*t); theory=struct([]);
for k=1:3
    bits=[8 4 2]; B=bits(k);
    y=Khaled_Quantizer(tone,B); m=jesher.computeMetrics(tone,y);
    row=struct('bits',B,'sinePeak',0.5,'frequencyHz',997, ...
        'measuredSNRdB',m.snrDb,'highResolutionPrediction',6.0206*B+1.7609+20*log10(0.5));
    if k==1, theory=row; else, theory(k)=row; end
end
writetable(struct2table(theory),fullfile(folder,'sine_quantization_check.csv'));

%% Actual saved quantization model, for report/code documentation.
load_system(fullfile(root,'Simulink','Khaled_Quantizer_Model.slx'));
print('-sKhaled_Quantizer_Model','-dpng','-r180',fullfile(figureFolder,'quantization_model.png'));
close_system('Khaled_Quantizer_Model',0);
end
