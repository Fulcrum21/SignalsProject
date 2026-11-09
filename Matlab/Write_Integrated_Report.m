function Write_Integrated_Report(folder)
% Jesher's report section, computed from Khaled's exact producer handoffs.
root=fileparts(fileparts(mfilename('fullpath')));
metrics=readtable(fullfile(folder,'metrics.csv'),'Delimiter',',','TextType','string');
storage=readtable(fullfile(folder,'storage_quality.csv'),'Delimiter',',','TextType','string');
pairs=readtable(fullfile(folder,'integration_comparison.csv'),'Delimiter',',','TextType','string');
notes=readtable(fullfile(folder,'listening_results.csv'),'Delimiter',',','TextType','string');
methods=readtable(fullfile(folder,'reconstruction_comparison.csv'),'Delimiter',',','TextType','string');
[~,runName]=fileparts(folder); relative=['../Results/Integrated/' runName '/'];
path=fullfile(root,'Reports','Jesher_Khaled_Handoff_Results.md');
fid=fopen(path,'w'); assert(fid>=0,'Cannot write the report section.');
closer=onCleanup(@()fclose(fid));
fprintf(fid,'# Task 4: Quality evaluation of Khaled''s processed audio\n\n');
fprintf(fid,'Measured run: `%s`; MATLAB %s. Insert Sections 4.1-4.7 after Khaled''s quantization section. Table 4.1 may be moved to Appendix B.\n\n',runName,version('-release'));
fprintf(fid,'## 4.1 Processed signals and responsibility\n\n');
fprintf(fid,['Abdulrahman supplies the sampling-stage arrays. Khaled''s published Khaled_KH04_All_Cases script applies his MATLAB quantizer and his saved Khaled_Quantizer_Model Simulink design to those arrays. ' ...
    'Jesher evaluates the resulting KH04_MATLAB_Cases.mat and KH04_Simulink_Cases.mat handoffs without replacing their samples. ' ...
    'The producer code is from branch khaled-quantization-storage, commit fa2fc06. There are 36 cases per platform, with five rates, four precision settings and filtered/unfiltered lower-rate paths.\n\n']);
fprintf(fid,['The native 44,100 Hz, 16-bit control retains all 882,005 original samples. Lower-rate cases use 22,050, 11,025, 8,000 or 4,000 Hz. ' ...
    'Khaled uses uniform signed midtread levels with step 2/2^B for B = 8, 4 and 2, nearest-integer rounding with half ties away from zero, and saturation to the signed index range. ' ...
    'The 16-bit setting bypasses additional quantization. Effective bits identify the producer setting and verified levels; they are not inferred from a WAV header.\n\n']);
fprintf(fid,'## 4.2 Alignment and objective metrics\n\n');
fprintf(fid,['Each lower-rate output is reconstructed at 44,100 Hz using resample(samples,p,q,10,5), with the inverse sampling ratio. ' ...
    'The first 882,005 reconstructed samples are compared with the original times from 0 through 882004/44100 seconds. Known sampling-filter delay is already compensated. ' ...
    'There is no additional delay correction, independent amplitude normalization, optimized lag search or error-based edge trimming. Reconstruction restores the comparison grid, not lost bandwidth.\n\n']);
fprintf(fid,['For error e[n] = x[n] - xhat[n], NMSE = sum(e.^2)/sum(x.^2), and SNR in dB = 10 log10(sum(x.^2)/sum(e.^2)). ' ...
    'For positive finite energies, SNR = -10 log10(NMSE). The unchanged control has NMSE zero and infinite SNR. A silent reference with zero error has undefined normalized metrics, reported as NaN. ' ...
    'Khaled''s isolated quantization error compares the quantizer input/output at the processed rate; total NMSE/SNR additionally includes sampling and reconstruction errors.\n\n']);
fprintf(fid,['The metrics CSV retains two representations: nmse/snrDb score Khaled''s exact processing arrays, and exportedNmse/exportedSnrDb score the WAV after export, re-import and reconstruction. ' ...
    'The following table uses exported-WAV scores throughout.\n\n']);
fprintf(fid,'**Table 4.1. Total quality of Khaled''s 72 outputs after Jesher''s PCM16 WAV export and re-import.**\n\n');
fprintf(fid,'| Rate (Hz) | Bits | Filter | MATLAB NMSE | MATLAB SNR (dB) | Simulink NMSE | Simulink SNR (dB) |\n| --- | --- | --- | --- | --- | --- | --- |\n');
a=sortrows(metrics(metrics.platform=="matlab",:),{'Fs','filterMode','effectiveBits'},{'descend','ascend','descend'});
for k=1:height(a)
    b=metrics(metrics.caseId==replace(a.caseId(k),'_matlab','_simulink'),:);
    fprintf(fid,'| %d | %d | %s | %.8g | %.4f | %.8g | %.4f |\n',a.Fs(k),a.effectiveBits(k),a.filterMode(k),a.exportedNmse(k),a.exportedSnrDb(k),b.exportedNmse,b.exportedSnrDb);
end
fprintf(fid,'\nAt 8/4 kHz, `none` uses linear interpolation without a dedicated anti-aliasing LPF. At 22.05/11.025 kHz, it uses direct sample selection. `lpf` denotes Abdulrahman''s filtered rate conversion.\n\n');
fprintf(fid,'## 4.3 Waveform, FFT and spectrogram results\n\n');
fprintf(fid,['Each comparison shows the original at left and the exported processed WAV reconstructed to the original grid at right. Rows show waveform, normalized full-record single-sided FFT and PSD spectrogram. ' ...
    'FFT scaling retains DC and treats odd/even sample counts correctly. Spectrograms use a periodic 1,024-sample Hann window, 768-sample overlap and 2,048-point FFT. ' ...
    'The frequency axis is in kHz; PSD remains per Hz. Display floors are -160 dB.\n\n']);
ids={'speechmusic_fs44100_b04_native_matlab','speechmusic_fs22050_b08_lpf_matlab','speechmusic_fs4000_b02_none_matlab'};
for k=1:numel(ids)
    row=metrics(metrics.caseId==string(ids{k}),:);
    caption=sprintf('Figure 4.%d. Khaled''s %d Hz, %d-bit, %s output after WAV export and reconstruction. NMSE %.8g; SNR %.4f dB.',k,row.Fs,row.effectiveBits,row.filterMode,row.exportedNmse,row.exportedSnrDb);
    fprintf(fid,'![%s](%sfigures/%s_comparison.png)\n\n%s\n\n',caption,relative,ids{k},caption);
end
fprintf(fid,['Coarse quantization can map quiet samples to zero and remove small waveform variations. Unfiltered sampling reduction may fold higher-frequency content into the retained band. ' ...
    'A narrow reconstructed spectrum alone does not establish that aliasing was prevented; interpret it with the processing method and Task 2''s known-tone evidence.\n\n']);
fprintf(fid,'## 4.4 Handoff acceptance and platform comparison\n\n');
fprintf(fid,['All 72 imported arrays were checked for exact equality with Khaled''s saved handoffs. Rates, effective bits, platform, filter mode, timing, provenance and quantization-error identities were verified. ' ...
    'Boundary fixtures independently check expected outputs at zero, half-step ties, range endpoints and out-of-range inputs in his MATLAB function and Simulink model. ' ...
    'For identical inputs, the quantizers agree exactly.\n\n']);
fprintf(fid,['The maximum upstream sampling difference is %.12g. There are %d reduced-bit pairs with decision-boundary differences, involving %d samples across those pairs. ' ...
    'Each differing sample is exactly one quantization step apart and lies within upstream rounding distance of a half-step threshold. ' ...
    'The integration comparison documents these explained differences. The evaluator''s strict generic comparison remains available alongside this resolution.\n\n'], ...
    max(pairs.samplingMaxAbsDifference),nnz(pairs.explainedBoundarySamples>0),sum(pairs.explainedBoundarySamples));
fprintf(fid,'### Why Khaled''s published quality scores differ\n\n');
fprintf(fid,['Khaled''s separate KH06 quality script uses linear interpolation with held endpoints. Jesher uses the documented resample-based full-record reconstruction. ' ...
    'The same processed array can therefore give different total error energy. The next table compares processing-array scores only, avoiding WAV-conversion differences.\n\n']);
fprintf(fid,'**Table 4.2. Reconstruction-method comparison for MATLAB sampling controls.**\n\n');
fprintf(fid,'| Rate (Hz) | Filter | Jesher resample NMSE | Jesher SNR (dB) | Khaled linear-hold NMSE | Khaled SNR (dB) |\n| --- | --- | --- | --- | --- | --- |\n');
for rate=[22050 8000 4000]
    id=sprintf('speechmusic_fs%d_b16_lpf_matlab',rate); row=methods(methods.caseId==string(id),:);
    fprintf(fid,'| %d | lpf | %.8g | %.4f | %.8g | %.4f |\n',rate,row.nmse,row.snrDb,row.KhaledProcessingNMSE,row.KhaledProcessingSNRdB);
end
fprintf(fid,'\nThe complete [method comparison](%sreconstruction_comparison.csv) identifies both methods. Keep reconstruction methods labeled when copying report results.\n\n',relative);
fprintf(fid,'## 4.5 Verified exports and storage\n\n');
fprintf(fid,['Each signal is exported as mono PCM16 at its actual rate, then read back. Conversion explicitly rounds samples times 32768 to signed 16-bit integers; no case normalization or silent clipping is applied. ' ...
    'Rate, channels, sample count, file bytes and re-imported values are checked. The ZIP contains the unchanged original plus 72 processed WAVs and manifests. Archived bytes are verified against exported files.\n\n']);
fprintf(fid,['Effective precision remains separate from file width. A 2-bit quantized signal has four amplitude levels, but its WAV uses a 16-bit carrier. ' ...
    'Theoretical packed payload is ceil(N times B / 8) bytes for one channel. Actual PCM16 sample payload is 2N bytes, plus measured overhead. ' ...
    'Reducing effective precision alone does not shrink this WAV container; reducing sample rate reduces its sample count.\n\n']);
example=storage(storage.caseId=="speechmusic_fs22050_b08_lpf_matlab",:);
fprintf(fid,'For example, the filtered 22,050 Hz, 8-bit case occupies %d WAV bytes and has exported SNR %.4f dB. The [full storage table](%sstorage_quality.csv) links every case to measured file size and theoretical payload.\n\n',example.wavFileBytes,example.exportedSnrDb,relative);
fprintf(fid,'## 4.6 Reported listening observations\n\n');
heard=notes(notes.PlaybackStatus=="tested",:);
fprintf(fid,['Khaled''s published worksheet records %d tested cases on laptop speakers, with listener recorded as self; %d cases remain not_tested. ' ...
    'These observations concern his supplied worksheet and earlier exports, rather than a new Jesher playback session. Listening date and volume are not supplied. ' ...
    'The table pairs the reported observations with Jesher''s current exported-WAV scores.\n\n'],height(heard),height(notes)-height(heard));
fprintf(fid,'**Table 4.3. Existing observations reported in Khaled''s worksheet.**\n\n');
fprintf(fid,'| Case ID | Jesher exported SNR (dB) | Reported observation |\n| --- | --- | --- |\n');
for k=1:height(heard)
    fprintf(fid,'| %s | %.4f | %s |\n',heard.CaseID(k),heard.JesherExportedSNRdB(k),heard.ListeningNotes(k));
end
fprintf(fid,['\nNative 8-bit speech is reported clear, native 4-bit speech less intelligible and native 2-bit speech not audible/understandable in that session. ' ...
    'These reports accompany falling objective fidelity, but SNR does not set a universal audibility threshold. A reported inaudible clip does not establish that its digital samples are all zero. ' ...
    'The [joined listening results](%slistening_results.csv) preserve the original observations and attribution. Additional notes require actual listening with the setup recorded.\n\n'],relative);
fprintf(fid,'## 4.7 Reproduction and report placement\n\n');
fprintf(fid,['Run RUN_PROJECT for sampling, Khaled''s actual producer and Jesher''s evaluation. Run RUN_JESHER to evaluate existing KH04 handoffs. ' ...
    'For a single live case, edit PROJECT_SETTINGS, run RUN_DEMO and then PLAY_PROJECT_AUDIO. The demo checks that its output exactly matches Khaled''s saved case. ' ...
    'Use Figures 4.1-4.3 in this section; put full Table 4.1 in Appendix B if needed. A code appendix is optional. ' ...
    'The shared Word report still needs assembly; this file supplies the evaluation text and captions. See [QUICK_START](../QUICK_START.md) for the file map.\n']);
fprintf('Jesher report section written: %s\n',path);
end
