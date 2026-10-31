function plotCase(reference,referenceFs,c,outputFolder)
%PLOTCASE Same common grid and axes for waveform, FFT and spectrogram views.
aligned = jesher.alignToReference(reference,referenceFs,c);
f = figure('Visible','off','Color','white','Position',[50 50 1200 1000]);
closer = onCleanup(@()close(f)); %#ok<NASGU>
tiledlayout(3,2,'TileSpacing','compact');
t = (0:numel(reference)-1)'/referenceFs;
signals = {reference,aligned};
names = {'Original','Processed, reconstructed to reference grid'};
amplitudeLimit = max([max(abs(reference)),max(abs(aligned)),eps]);
for k = 1:2
    nexttile(k);
    plot(t,signals{k}); ylim([-amplitudeLimit amplitudeLimit]);
    xlim([0 t(end)]); xlabel('Time (s)'); ylabel('Digital amplitude');
    title(names{k}); grid on;
    nexttile(k+2);
    x = signals{k}; n = numel(x);
    mag = abs(fft(x))/n;
    mag = mag(1:floor(n/2)+1);
    if mod(n,2) == 0
        mag(2:end-1) = 2*mag(2:end-1);
    else
        mag(2:end) = 2*mag(2:end);
    end
    hz = (0:floor(n/2))*referenceFs/n;
    plot(hz,20*log10(max(mag,1e-8)));
    xlim([0 referenceFs/2]); ylim([-160 6]);
    xlabel('Frequency (Hz)'); ylabel('Amplitude (dB re digital 1)'); grid on;
    title('Full-record single-sided FFT; display floor -160 dB');
    nexttile(k+4);
    [~,hz,seconds,power] = spectrogram(x,hann(1024,'periodic'),768,2048,referenceFs);
    imagesc(seconds,hz,10*log10(max(power,1e-16))); axis xy;
    clim([-160 0]); ylim([0 referenceFs/2]);
    xlabel('Time (s)'); ylabel('Frequency (Hz)');
    title('PSD (dB re digital amplitude^2/Hz)'); colorbar;
end
sgtitle(string(c.caseId),'Interpreter','none');
exportgraphics(f,fullfile(outputFolder,[char(c.caseId) '.png']),'Resolution',150);
end
