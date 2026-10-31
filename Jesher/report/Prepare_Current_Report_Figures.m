function Prepare_Current_Report_Figures()
%PREPARE_CURRENT_REPORT_FIGURES Replot the exact saved run for the report.
% Presentation-only copies. Original run artifacts are not overwritten.
reportRoot = fileparts(mfilename('fullpath'));
ownerRoot = fileparts(reportRoot);
runRoot = fullfile(ownerRoot,'results','matlab_run_20261030_170138_859');
addpath(fullfile(ownerRoot,'matlab'));
data = load(fullfile(runRoot,'evaluation.mat'),'cases','reference','referenceFs');
metrics = readtable(fullfile(runRoot,'metrics.csv'),'TextType','string');
figureRoot = fullfile(reportRoot,'figures');
if ~isfolder(figureRoot), mkdir(figureRoot); end
ids = ["speechmusic_fs44100_b16_native_matlab", ...
    "speechmusic_fs22050_b16_lpf_matlab", ...
    "speechmusic_fs22050_b16_none_matlab"];
names = {'Native reference control','Filtered sampling control','Unfiltered sampling control'};
files = {'figure_01_native.png','figure_02_filtered.png','figure_03_unfiltered.png'};
for index = 1:3
    c = data.cases(string({data.cases.caseId}) == ids(index));
    assert(isscalar(c),'jesher:ReportCase','Expected exactly one saved case.');
    aligned = jesher.alignToReference(data.reference,data.referenceFs,c);
    m = jesher.computeMetrics(data.reference,aligned);
    row = metrics(metrics.caseId == ids(index),:);
    assert(abs(m.nmse-row.nmse) < 1e-14,'jesher:ReportMetric','Saved NMSE differs.');
    assert(isequal(m.snrDb,row.snrDb) || abs(m.snrDb-row.snrDb) < 1e-10, ...
        'jesher:ReportMetric','Saved SNR differs.');
    drawFigure(data.reference,aligned,data.referenceFs,c,names{index}, ...
        fullfile(figureRoot,files{index}));
end
fprintf('Three report figures regenerated from saved evaluation arrays.\n');
end

function drawFigure(reference,aligned,Fs,c,name,path)
f = figure('Visible','off','Theme','light','Color','white', ...
    'Position',[50 50 1380 1120]);
closer = onCleanup(@()close(f)); %#ok<NASGU>
layout = tiledlayout(f,3,2,'TileSpacing','compact','Padding','compact');
title(layout,{name,char(c.caseId)},'Interpreter','none','Color',[.08 .13 .20], ...
    'FontSize',14,'FontWeight','bold');
signals = {reference,aligned};
t = (0:numel(reference)-1)'/Fs;
duration = numel(reference)/Fs;
limit = max([max(abs(reference)),max(abs(aligned)),eps])*1.05;
for column = 1:2
    ax = nexttile(layout,column);
    plot(ax,t,signals{column},'Color',[.04 .36 .64],'LineWidth',.55);
    xlim(ax,[0 duration]); ylim(ax,[-limit limit]); grid(ax,'on');
    xlabel(ax,'Time (s)'); ylabel(ax,'Digital amplitude');
    if column == 1
        title(ax,'(a) Original waveform');
    else
        title(ax,'(b) Processed waveform on reference grid');
    end
    styleAxes(ax);
    ax = nexttile(layout,column+2);
    x = signals{column}; n = numel(x);
    mag = abs(fft(x))/n;
    mag = mag(1:floor(n/2)+1);
    if mod(n,2) == 0
        mag(2:end-1) = 2*mag(2:end-1);
    else
        mag(2:end) = 2*mag(2:end);
    end
    hz = (0:floor(n/2))*Fs/n;
    plot(ax,hz/1000,20*log10(max(mag,1e-8)),'Color',[.04 .36 .64],'LineWidth',.55);
    xlim(ax,[0 Fs/2000]); ylim(ax,[-160 6]); grid(ax,'on');
    xlabel(ax,'Frequency (kHz)'); ylabel(ax,'Amplitude (dB re digital 1)');
    if column == 1, panel='(c)'; else, panel='(d)'; end
    title(ax,[panel ' Full-record single-sided FFT']);
    if c.Fs < Fs
        xline(ax,c.Fs/2000,'--','11.025 kHz','Color',[.4 .15 .15], ...
            'LabelHorizontalAlignment','left','FontSize',9);
    end
    styleAxes(ax);
    ax = nexttile(layout,column+4);
    [~,frequency,seconds,power] = spectrogram(x,hann(1024,'periodic'),768,2048,Fs);
    imagesc(ax,seconds,frequency/1000,10*log10(max(power,1e-16)));
    axis(ax,'xy'); xlim(ax,[0 duration]); ylim(ax,[0 Fs/2000]); clim(ax,[-160 0]);
    xlabel(ax,'Time (s)'); ylabel(ax,'Frequency (kHz)');
    if column == 1, panel='(e)'; else, panel='(f)'; end
    title(ax,[panel ' PSD spectrogram']);
    cb = colorbar(ax); cb.Color = [.12 .12 .12]; cb.FontSize = 10;
    cb.Label.String = 'dB re digital amplitude^2/Hz'; cb.Label.FontSize = 10;
    if c.Fs < Fs
        yline(ax,c.Fs/2000,'--','Color',[1 1 1],'LineWidth',.8);
    end
    styleAxes(ax);
end
exportgraphics(f,path,'Resolution',220,'BackgroundColor','white');
end

function styleAxes(ax)
set(ax,'Color','white','XColor',[.12 .12 .12],'YColor',[.12 .12 .12], ...
    'FontName','Arial','FontSize',11,'GridColor',[.75 .75 .75], ...
    'GridAlpha',.45,'Box','on');
ax.Title.Color = [.08 .13 .20]; ax.Title.FontSize = 12;
ax.XLabel.Color = [.12 .12 .12]; ax.YLabel.Color = [.12 .12 .12];
end
