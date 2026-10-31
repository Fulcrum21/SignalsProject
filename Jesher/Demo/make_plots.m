function make_plots(reference,processed,Fs,quantError,processedFs,caseId,outputFolder)
% Same axes and analysis settings for the two source-rate comparison arrays.
f=figure('Theme','light','Color','white','Name',caseId,'Tag','JesherDemo','Position',[60 60 1250 950]);
tiledlayout(3,2,'TileSpacing','compact');
signals={reference,processed}; n=numel(reference); time=(0:n-1)'/Fs;
amplitude=max([max(abs(reference)),max(abs(processed)),eps])*1.05;
for k=1:2
    nexttile(k); plot_envelope(time,signals{k}); grid on;
    xlim([0 n/Fs]); ylim([-amplitude amplitude]);
    xlabel('Time (s)'); ylabel('Digital amplitude');
    if k==1, title('Original'); else, title('Exported WAV, reconstructed to original rate'); end
    nexttile(k+2);
    spectrum=abs(fft(signals{k}))/n;
    spectrum=spectrum(1:floor(n/2)+1);
    if mod(n,2)==0, spectrum(2:end-1)=2*spectrum(2:end-1);
    else, spectrum(2:end)=2*spectrum(2:end); end
    plot_envelope((0:floor(n/2))*Fs/n/1000,20*log10(max(spectrum,1e-8)));
    grid on; xlim([0 Fs/2000]); ylim([-160 6]);
    xlabel('Frequency (kHz)'); ylabel('Amplitude (dB re digital 1)'); title('Full-record FFT');
    nexttile(k+4);
    windowLength=min(1024,n);
    [~,hz,seconds,power]=spectrogram(signals{k},hann(windowLength,'periodic'), ...
        floor(0.75*windowLength),max(2048,windowLength),Fs);
    imagesc(seconds,hz/1000,10*log10(max(power,1e-16))); axis xy;
    clim([-160 0]); ylim([0 Fs/2000]); colorbar;
    xlabel('Time (s)'); ylabel('Frequency (kHz)'); title('PSD (dB re digital amplitude^2/Hz)');
end
sgtitle(caseId,'Interpreter','none');
exportgraphics(f,fullfile(outputFolder,[caseId '_comparison.png']),'Resolution',160);
q=figure('Theme','light','Color','white','Name',[caseId ' quantization error'], ...
    'Tag','JesherDemo','Position',[100 100 1100 450]);
tiledlayout(1,2);
nexttile; plot_envelope((0:numel(quantError)-1)/processedFs,quantError); grid on;
xlabel('Time (s)'); ylabel('Sampling output minus quantized output'); title('Quantization error');
nexttile; histogram(quantError,64); grid on;
xlabel('Error amplitude'); ylabel('Sample count'); title('Quantization error distribution');
sgtitle(caseId,'Interpreter','none');
exportgraphics(q,fullfile(outputFolder,[caseId '_quantization.png']),'Resolution',160);
end

function plot_envelope(t,y)
% Display at most ~12,000 points while retaining every display-bin extremum.
% Metrics and the full-record FFT always use every sample. This only speeds
% up rendering dense figures for the live demonstration.
n=numel(y); group=ceil(n/6000);
if group<=1, plot(t,y); return; end
count=ceil(n/group);
padded=[y(:); NaN(count*group-n,1)];
blocks=reshape(padded,group,count);
[~,low]=min(blocks,[],1,'omitnan'); [~,high]=max(blocks,[],1,'omitnan');
indices=sort([low+(0:count-1)*group;high+(0:count-1)*group],1);
indices=indices(:); indices=indices(indices<=n);
plot(t(indices),y(indices));
end
