function Make_Integrated_Results(folder,handoffFile)
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
data=load(handoffFile,'cases'); cases=data.cases;
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
    y=Uniform_Quantize(tone,B); m=jesher.computeMetrics(tone,y);
    row=struct('bits',B,'sinePeak',0.5,'frequencyHz',997, ...
        'measuredSNRdB',m.snrDb,'highResolutionPrediction',6.0206*B+1.7609+20*log10(0.5));
    if k==1, theory=row; else, theory(k)=row; end
end
writetable(struct2table(theory),fullfile(folder,'sine_quantization_check.csv'));

%% Actual saved quantization model, for report/code documentation.
load_system(fullfile(root,'Simulink','Quantization_Khaled.slx'));
print('-sQuantization_Khaled','-dpng','-r180',fullfile(figureFolder,'quantization_model.png'));
close_system('Quantization_Khaled',0);
end
