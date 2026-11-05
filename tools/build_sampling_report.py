"""Build the PDF and editable sampling section from verified MATLAB outputs.
Run from the repository root after Matlab/Prepare_Sampling_Handoff.m.
Requires reportlab, Pillow and pypdf. No experiment values are invented here.
"""
from pathlib import Path
import csv, hashlib, html, json, math, re, wave
from PIL import Image as PILImage
from pypdf import PdfReader
from reportlab.lib import colors
from reportlab.lib.pagesizes import A4
from reportlab.lib.styles import ParagraphStyle
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.ttfonts import TTFont
from reportlab.pdfgen import canvas
from reportlab.platypus import Frame, Image, Paragraph, Spacer, Table, TableStyle, XPreformatted

ROOT = Path(__file__).resolve().parents[1]
RESULTS = ROOT/'Results/Abdulrahman/Sampling'
PDF = ROOT/'output/pdf/Abdulrahman_Sampling_Report_Draft.pdf'
MD = ROOT/'Reports/Abdulrahman_Sampling.md'
with (RESULTS/'case_manifest.csv').open(newline='',encoding='utf-8-sig') as f:
    cases = list(csv.DictReader(f))
with (RESULTS/'aliasing_summary.csv').open(newline='',encoding='utf-8-sig') as f:
    alias = list(csv.DictReader(f))
assert 'PASS: eight cases' in (ROOT/'Results/Abdulrahman/sampling_run_log.txt').read_text(encoding='utf-8')
assert len(cases)==8 and len({r['caseId'] for r in cases})==8
with (RESULTS/'alignment_checks.csv').open(newline='',encoding='utf-8-sig') as f:
    timing=list(csv.DictReader(f))
assert len(timing)==8 and all(float(r['KnownToneDominantHz'])==300 and float(r['ResidualLagSourceSamples'])==0 for r in timing)
for r in cases:
    with wave.open(str(RESULTS/r['wavFileName']),'rb') as w:
        assert (w.getnchannels(),w.getsampwidth(),w.getframerate(),w.getnframes()) == (1,2,int(r['Fs']),int(r['sampleCount']))
suppression = 20*math.log10(float(alias[1]['PeakAmplitude'])/float(alias[2]['PeakAmplitude']))
max_error = max(float(r['wavMaxAbsRoundTripError']) for r in cases)
with (RESULTS/'simulink_comparison.csv').open(newline='',encoding='utf-8-sig') as f:
    simulink_rows=list(csv.DictReader(f))
assert len(simulink_rows)==8 and all(float(r['MaxAbsDifference'])<=float(r['Tolerance']) for r in simulink_rows)
pages = []
def add(title,body): pages.append((title,body.strip()))
def tab(headers,rows):
    return '\n'.join(['| '+' | '.join(headers)+' |','| '+' | '.join('---' for h in headers)+' |']+['| '+' | '.join(map(str,r))+' |' for r in rows])
def image(name): return f'![{name}](../Results/Abdulrahman/Sampling/{name})'

add('Sampling and aliasing',f'''
**Abdulrahman | Sampling report section draft | Updated 3 November 2026**

The same mono speech/music recording was converted from 44.1 kHz to four lower rates, with and without anti-aliasing low-pass filtering. Eight MATLAB sampling cases are supplied. A known 10 kHz tone folds to 1,025 Hz after unfiltered conversion to 11.025 kHz, matching the sampling-theory prediction. Filtering reduces the measured largest residual by {suppression:.2f} dB relative to the unfiltered alias.

### Reference recording

The source WAV contains 882,005 mono samples at 44,100 Hz, stored as 16-bit PCM. Its sample-count duration is 20.000113379 s. Yazan's baseline waveform, FFT and spectrogram analysis supplies the original reference [1, 2]. The WAV header establishes its digital format; microphone-acquisition provenance belongs to Yazan's acquisition record.

{tab(['Output Hz','Nyquist Hz','Ratio p/q','Samples per path','Duration s'], [[f"{int(r['Fs']):,}",f"{int(r['Fs'])/2:,.1f}",r['p']+'/'+r['q'],f"{int(r['sampleCount']):,}",f"{float(r['durationSeconds']):.9f}"] for r in cases[::2]])}

### Scope of this section

These are sampling-only results. The MAT arrays retain double-valued samples without reduced-bit quantization or independent normalization. The b16 label identifies the source/control; WAV playback copies use a 16-bit PCM carrier. Quantization, complete NMSE/SNR tables and listening results belong to the integrated team evaluation.

All four saved sampling models have now been run and compared against the exact MATLAB arrays. Eight aligned Simulink sampling controls are supplied separately, with no further quantization. The platform comparison table documents tolerances and measured differences. This remains a draft section for the integrated team report, not a completed submission report.
''')

add('Sampling methods','''
### Integer conversions

```matlab
yNoFilter = x(1:2:end);       % 22,050 Hz
yNoFilterRate = x(1:4:end);   % 11,025 Hz
```

Index 1 retains t=0; the step retains every second or fourth measurement. No anti-aliasing low-pass filter is applied. The resulting arrays must be associated with their actual lower rates. Changing a sampling-rate label alone would change playback speed.

### Non-integer conversions

```matlab
[p, q] = rat(FsOutput / Fs);
outputTime = (0:lastOutputIndex)' / FsOutput;
yNoFilterRate = interp1(originalTime, x, outputTime, "linear");
```

The exact ratios are 80/441 for 8 kHz and 40/441 for 4 kHz. A constant integer indexing step cannot give either exact rate. Linear interpolation estimates values at uniform target times between surrounding source samples. It changes the frequency response, but supplies no dedicated anti-aliasing low-pass filter at the new Nyquist limit. Differences from the filtered path therefore include interpolation-method effects as well as anti-aliasing effects.

### Filtered conversion

```matlab
[yFilteredRate, coefficientsRate] = resample(x, p, q, 10, 5);
```

resample uses a Kaiser-window FIR design with n=10 and beta=5, and compensates its designed delay. Every branch starts from the original x. Filtering after unfiltered downsampling cannot undo folding. A finite filter has a transition band rather than a perfect frequency wall [3, 4].

| Output Hz | FIR taps | Coefficient rate Hz | Nominal cutoff Hz |
| --- | --- | --- | --- |
| 22,050 | 41 | 44,100 | 11,025 |
| 11,025 | 81 | 44,100 | 5,512.5 |
| 8,000 | 8,821 | 3,528,000 | 4,000 |
| 4,000 | 8,821 | 1,764,000 | 2,000 |

For p greater than 1, coefficients describe the intermediate upsampled grid at p times the source rate. They are not ordinary source-rate FIR Decimation coefficients. Polyphase processing avoids explicitly allocating a zero-inserted audio array.
''')

add('Alignment and analysis settings','''
### Match physical times

All cases start at t=0. The 8 and 4 kHz grids end at 20.000000000 s, slightly before the original final timestamp of 20.000090703 s. The filtered arrays are retained on the same grids as their unfiltered counterparts. Sample-count duration N/Fs differs from last sample time (N-1)/Fs by one sample interval.

```matlab
reconstructed = resample(entry.samples, entry.q, entry.p);
aligned = reconstructed(1:length(reference));
```

The inverse ratio restores the 44.1 kHz comparison grid, not lost or aliased information. Every current case was checked to reconstruct to at least 882,005 samples, then the full original interval is retained. Do not shift again after resample's delay compensation. No independent normalization, optimized lag shift or error-based edge trimming is applied. Reconstruction boundary effects remain in later quality measurements, including the short tail beyond the final lower-rate sample.

### Waveforms and FFTs

Full waveforms use actual sample times and common amplitude limits. The same 10 ms interval centered on the source's largest sample is enlarged in all comparisons. Full-record FFT magnitudes are divided by N. Paired positive-frequency magnitudes are doubled, leaving DC and any exact Nyquist bin unchanged. Frequency labels use each array's actual rate. The dB view is 20 log10 of amplitude relative to 1. A plotting floor of 1e-12 prevents log10(0), without changing stored samples.

### Spectrograms

Hamming windows last approximately 30 ms with approximately 20 ms overlap; sample counts are rounded at each rate. Every FFT has 2,048 points. Fixed color limits are -130 to -30 dB relative to 1 numeric sample-unit squared per Hz. All three rows show the shared output band from zero to the new Nyquist limit; the full-band FFT shows original content above that limit. Padding adds grid points, not physical resolving power. The kHz axis does not change density units from per Hz to per kHz.

### Existing platform validation

At 22.05 kHz, the known causal FIR delay is 10 output samples. Recorded speech/music MATLAB-versus-Simulink differences were 0 without filtering and 3.33066907388e-16 with filtering. The earlier 300 Hz tone had zero residual reconstruction lag. These are implementation-agreement checks, not NMSE/SNR against the original [7].
''')

add('Known frequency aliasing',f'''
{image('aliasing_10000_to_1025.png')}

**Figure 1.** Existing 10 kHz sine recording and factor-four conversion to 11.025 kHz, using the same amplitude scale. The new Nyquist limit is 5,512.5 Hz.

{tab(['Signal','Largest peak Hz','Peak amplitude'],[[r['Signal'],f"{float(r['PeakHz']):,.2f}",f"{float(r['PeakAmplitude']):.9f}"] for r in alias])}

Without filtering, 10,000 Hz folds to |11,025 - 10,000| = 1,025 Hz. These cosine frequencies are indistinguishable at the retained sampling times. The anti-aliasing path reduces the largest residual by {suppression:.2f} dB; a practical filter leaves a small residual rather than exact zero. Measurements come from Aliasing_Demo.m and the existing tone [5, 6].
''')

interpretations = {
22050:'The strong low-frequency peaks are close between paths. Weak-component differences are easier to inspect in the logarithmic panel. Much of the dominant visible content lies below the new limit. Close linear spectra alone do not establish that no aliasing occurred.',
11025:'Dominant low-frequency peaks remain close. Differences in the weaker upper output band are consistent with the changed anti-aliasing treatment. The separate 10 kHz tone experiment identifies an exact 1,025 Hz folding example at this rate.',
8000:'The output bandwidth is limited to 4 kHz. Many low-frequency peaks remain close while differences appear in weaker components. Linear interpolation in the unfiltered route changes amplitudes too, so not every difference can be attributed only to folded energy.',
4000:'This case retains the narrowest bandwidth. Curves differ in parts of the remaining band, while several strong low-frequency components remain. Components originally above 2 kHz can fold into the unfiltered output. Interpolation also affects amplitudes; a particular real-audio peak cannot be identified as an alias without a traceable source-frequency test.'}
number=2
for rate in [22050,11025,8000,4000]:
    row=next(r for r in cases if int(r['Fs'])==rate and r['filterMode']=='none')
    add(f'{rate:,} Hz waveform comparison',f'''
{image(f'waveforms_{rate}.png')}

**Figure {number}.** Full recording at left and a common active 10 ms interval at right. Each row uses its actual sampling rate and equal amplitude limits. The lower-rate plotted samples are farther apart in time. Lines join points for readability.

Both processed paths contain {int(row['sampleCount']):,} samples at {rate:,} Hz, with duration N/Fs = {float(row['durationSeconds']):.9f} s. Fewer samples do not imply faster or slower intended playback.

### Interpreting the waveform

A similar overall envelope locates events at similar times, but does not establish equal frequency content or identical samples. The common excerpt reveals local shape changes. Later error measurements must reconstruct to the agreed reference grid before subtracting arrays.
'''); number+=1
    add(f'{rate:,} Hz spectrum comparison',f'''
{image(f'spectra_{rate}.png')}

**Figure {number}.** The upper panel shows the original bandwidth and marks the new Nyquist boundary at {rate/2:,.1f} Hz. Processed spectra stop at their own representable limits. The lower panel compares the shared output band in dB relative to amplitude 1.

{interpretations[rate]}

### Interpreting the overlap

An aliased component appears inside the remaining band, not at its original out-of-band frequency. Filtering before rate reduction suppresses the high-frequency contribution. Original spectral content and the finite filter transition determine the observed differences. Magnitude overlap alone does not establish phase or waveform agreement.
'''); number+=1
    add(f'{rate:,} Hz spectrogram comparison',f'''
{image(f'spectrograms_{rate}.png')}

**Figure {number}.** All rows use 30 ms Hamming windows, 20 ms overlap and 2,048 FFT points. The output Nyquist limit is {rate/2:,.1f} Hz. The unchanged original is displayed over the same output band as both processed rows, with equal color limits. Original frequencies above that limit remain visible in the full-band FFT figure.

Horizontal bands indicate sustained components. Changes over time indicate changing spectral content. Compare matching time-frequency locations within the output band. These views complement the FFT comparisons, but cannot independently identify the source frequency of every output feature.

Color values are numeric power spectral density, not calibrated acoustic dB SPL. Smaller rate means fewer samples in a 30 ms window; window durations, rather than sample counts, are matched across cases.
'''); number+=1

add('Handoff and verification',f'''
| Artifact | Contents |
| --- | --- |
| sampling_all_rates.mat | Original and eight exact double-valued sampling cases with timing, methods and FIR coefficients. |
| case_manifest.csv | Eight unique IDs with rates, ratios, counts, durations and WAV metadata. |
| Eight named WAV files | Mono playback copies at their actual rates in 16-bit PCM carriers. |
| Thirteen PNG figures | Four waveform, four FFT and four spectrogram comparisons, plus the aliasing demonstration. |
| aliasing_summary.csv | Measured peak frequencies and amplitudes. |
| sha256_manifest.csv | Reference, source-code and result checksums. |

### Load one case from the repository root

```matlab
data = load("Results/Abdulrahman/Sampling/sampling_all_rates.mat");
entry = data.samplingHandoff.cases(6); % 8 kHz, filtered
samples = entry.samples;
Fs = entry.Fs;
```

Cases 1/2 are 22.05 kHz none/lpf; 3/4 are 11.025 kHz; 5/6 are 8 kHz; 7/8 are 4 kHz. Khaled should quantize the MAT arrays while preserving their timing/rates. Jesher should use the saved inverse ratio to reconstruct before quality comparisons. The handoff README contains run instructions.

### Checks performed

MATLAB verified the reference, case inventory, actual rates, expected counts, finite mono-column samples, declared processing results, duration bounds, reconstruction coverage, WAV rate/length/PCM width/bytes and conversion error. The existing 300 Hz tone retained its 300 Hz dominant frequency and zero diagnostic residual lag in all eight reconstructed paths; no lag correction was applied. Python independently checked eight WAV headers and the inventory. The largest WAV round-trip error was {max_error:.9g}, below one 16-bit PCM step (1/32,768).

No independent amplitude normalization or clipping was applied. WAV conversion error measures export rounding, not total downsampling degradation. Speaker playback and listening impressions require the team's actual listening session.
''')

add('Simulink verification',f'''
The four saved sampling models were run in MATLAB/Simulink R2026a for the full 20-second simulation interval. Logged frames were joined into columns, the known FIR delay was removed from filtered outputs, and only surplus final-frame coverage was discarded. Each case retains its exact MATLAB reference sample count.

{tab(['Rate Hz','Filter','Samples','Delay removed','Max difference'], [[r['FsHz'],r['FilterMode'],r['SampleCount'],r['RemovedDelayOutputSamples'],f"{float(r['MaxAbsDifference']):.6g}"] for r in simulink_rows])}

Unfiltered outputs use a maximum-absolute-difference tolerance of 1e-10; filtered outputs use 1e-12. These are numerical agreement bounds, far below one PCM16 sample step. The 8/4 kHz unfiltered models interpolate within each 4,410-sample frame; the MATLAB reference interpolates using full-record times. Their slightly different floating-point calculations explain small nonzero discrepancies. The filtered differences are at floating-point rounding scale.

### Reproduce the comparison

From the repository root:

```matlab
addpath("Matlab")
Compare_All_Sampling
```

The script prepares the four coefficient variables, loads the saved models and explicitly simulates to 20 s. It saves simulink_comparison.csv and simulink_cases.mat. The latter contains eight top-level cases structures with actual aligned Simulink samples, platform IDs, processing-stage and alignment metadata compatible with Jesher's external handoff contract. No MATLAB answer is relabeled as a Simulink result.

The FFT and spectrogram branches attached to the source still display the original recording. With 4,410-sample frames the final frame contains only five original samples, then padding; its broad, tiny FFT is not the whole-record spectrum. The sample-array comparison above is independent of that display artifact.
''')

add('Conclusion and remaining integration',f'''
All four lower rates are implemented in MATLAB with explicit filtered and unfiltered methods. The known 10 kHz recording folds to 1,025 Hz at 11.025 kHz sampling. Filtering reduces its measured largest residual by {suppression:.2f} dB. Comparable real-recording waveforms, FFTs and spectrograms show retained bandwidth and processing differences.

The 8 and 4 kHz unfiltered paths use linear interpolation, with a frequency-response effect of its own. A matching Simulink implementation must reproduce that method or explain a different interpolation choice. Integer FIR Decimation alone cannot supply the non-integer conversions.

### Remaining integration

The sampling-only MATLAB/Simulink comparisons now pass at all four lower rates. The new Simulink handoff still needs receiver acceptance and integration with the agreed reduced-bit cases. The team must reconcile final metrics, audio/listening evidence and report sections, including Jesher's separately developed demo. Sampling agreement does not by itself establish that the full combined case matrix, review and submission are complete.

### Sources and references

[1] CCEN 302 Project-3.pdf, sampling/aliasing requirements and report deliverables.

[2] Matlab/FirstPart_AudioFreqAnalysis.m, Yazan's original analysis.

[3] Matlab/Sampling_Abdulrahman.m and Results/Abdulrahman/AA02.

[4] Matlab/Sampling_OtherRates.m, all three remaining MATLAB rates.

[5] Matlab/Aliasing_Demo.m and Audios/10kHz_Sine.wav.

[6] Results/Abdulrahman/Sampling, case_manifest.csv, aliasing_summary.csv and reproducible packaging/plot/check scripts in Matlab.

[7] Results/Abdulrahman/AA03/known_tone_validation.csv; Matlab/Compare_Sampling.m; dated verification in team/Abdulrahman.md.

Official API descriptions: [resample](https://www.mathworks.com/help/signal/ref/resample.html), [interp1](https://www.mathworks.com/help/matlab/ref/interp1.html), [fft](https://www.mathworks.com/help/matlab/ref/fft.html), [spectrogram](https://www.mathworks.com/help/signal/ref/spectrogram.html). Numeric results use local MATLAB R2026a. Full file hashes are in sha256_manifest.csv.
''')

W,H=A4; CW=W-88
NAVY=colors.HexColor('#16324B'); TEAL=colors.HexColor('#087E8B'); GRAY=colors.HexColor('#607284')
for name,file in [('Body','arial.ttf'),('Bold','arialbd.ttf'),('Mono','consola.ttf')]:
    pdfmetrics.registerFont(TTFont(name,str(Path('C:/Windows/Fonts')/file)))
pdfmetrics.registerFontFamily('Body',normal='Body',bold='Bold',italic='Body',boldItalic='Bold')
styles={
'title':ParagraphStyle('title',fontName='Bold',fontSize=22,leading=26,textColor=NAVY,spaceAfter=15),
'body':ParagraphStyle('body',fontName='Body',fontSize=10.4,leading=14.6,textColor=NAVY,spaceAfter=9),
'heading':ParagraphStyle('heading',fontName='Bold',fontSize=12,leading=16,textColor=TEAL,spaceBefore=7,spaceAfter=7),
'cell':ParagraphStyle('cell',fontName='Body',fontSize=8.9,leading=12,textColor=NAVY),
'head':ParagraphStyle('head',fontName='Bold',fontSize=8.9,leading=12,textColor=colors.white),
'code':ParagraphStyle('code',fontName='Mono',fontSize=8.4,leading=11.4,textColor=NAVY)}
def markup(text):
    text=html.escape(text)
    text=re.sub(r'\*\*(.*?)\*\*',r'<b>\1</b>',text)
    return re.sub(r'\[([^\]]+)\]\((https?://[^)]+)\)',r'<link href="\2" color="#087E8B">\1</link>',text)
def P(text,style='body'): return Paragraph(markup(text),styles[style])
def render(body):
    lines=body.splitlines(); story=[]; i=0
    while i<len(lines):
        line=lines[i].strip()
        if not line: i+=1; continue
        if line.startswith('```'):
            code=[]; i+=1
            while not lines[i].startswith('```'): code.append(lines[i]); i+=1
            block=Table([[XPreformatted(html.escape('\n'.join(code)),styles['code'])]],colWidths=[CW])
            block.setStyle(TableStyle([('BACKGROUND',(0,0),(-1,-1),colors.HexColor('#F0F4F8')),('TOPPADDING',(0,0),(-1,-1),8),('BOTTOMPADDING',(0,0),(-1,-1),8),('LEFTPADDING',(0,0),(-1,-1),9)]))
            story += [block,Spacer(1,9)]; i+=1; continue
        if line.startswith('!['):
            relative=re.search(r'\]\((.*?)\)',line).group(1)
            path=(ROOT/'Reports'/relative).resolve()
            with PILImage.open(path) as im: w,h=im.size
            scale=min(CW/w,440/h)
            story += [Image(str(path),width=w*scale,height=h*scale),Spacer(1,9)]; i+=1; continue
        if line.startswith('|'):
            rows=[]
            while i<len(lines) and lines[i].startswith('|'):
                cells=[s.strip() for s in lines[i].strip('|').split('|')]
                if not all(re.fullmatch(r'[-: ]+',s) for s in cells): rows.append(cells)
                i+=1
            data=[[P(v,'head' if j==0 else 'cell') for v in row] for j,row in enumerate(rows)]
            widths=[CW/len(rows[0])]*len(rows[0])
            if len(rows[0])==2: widths=[150,CW-150]
            t=Table(data,colWidths=widths)
            commands=[('BACKGROUND',(0,0),(-1,0),NAVY),('VALIGN',(0,0),(-1,-1),'TOP'),('LEFTPADDING',(0,0),(-1,-1),7),('RIGHTPADDING',(0,0),(-1,-1),7),('TOPPADDING',(0,0),(-1,-1),7),('BOTTOMPADDING',(0,0),(-1,-1),7)]
            for j in range(1,len(rows)): commands.append(('BACKGROUND',(0,j),(-1,j),colors.HexColor('#F1F5F8') if j%2 else colors.white))
            t.setStyle(TableStyle(commands)); story += [t,Spacer(1,9)]; continue
        if line.startswith('### '): story.append(P(line[4:],'heading')); i+=1; continue
        paragraph=[line]; i+=1
        while i<len(lines) and lines[i].strip(): paragraph.append(lines[i].strip()); i+=1
        story.append(P(' '.join(paragraph)))
    return story

pdf=canvas.Canvas(str(PDF),pagesize=A4)
pdf.setTitle('Sampling and aliasing - Abdulrahman - verified platform comparisons')
pdf.setAuthor('Signals Project team - Abdulrahman sampling section')
for n,(title,body) in enumerate(pages,1):
    pdf.setFillColor(TEAL); pdf.rect(0,H-9,W,9,fill=1,stroke=0)
    pdf.setFillColor(GRAY); pdf.setFont('Bold',8)
    pdf.drawString(44,H-33,'CCEN 302 / SAMPLING AND ALIASING')
    pdf.drawRightString(W-44,H-33,'SAMPLING DRAFT / 3 NOV 2026')
    pdf.bookmarkPage(str(n)); pdf.addOutlineEntry(title,str(n),0)
    story=[P(title,'title')]+render(body)
    frame=Frame(44,52,CW,H-102,leftPadding=0,rightPadding=0,topPadding=0,bottomPadding=0)
    frame.addFromList(story,pdf)
    assert not story, f'Page {n} overflows: {title}'
    pdf.setStrokeColor(colors.HexColor('#D4DFE7')); pdf.line(44,38,W-44,38)
    pdf.setFillColor(GRAY); pdf.setFont('Body',8)
    pdf.drawString(44,24,'Eight sampling comparisons verified / final team integration pending')
    pdf.drawRightString(W-44,24,f'{n:02} / {len(pages):02}'); pdf.showPage()
pdf.save()
MD.write_text('# Sampling and aliasing report draft\n\n'+'\n\n'.join('## '+title+'\n\n'+body for title,body in pages)+'\n',encoding='utf-8')
reader=PdfReader(str(PDF))
assert len(reader.pages)==len(pages)==19
for i,p in enumerate(reader.pages): assert len(p.extract_text())>500,(i+1,'Sparse page')
inputs=[ROOT/'Audios/SpeechMusic.wav',ROOT/'Audios/10kHz_Sine.wav']
inputs += [ROOT/'Matlab'/name for name in ['Sampling_Abdulrahman.m','Sampling_OtherRates.m','Aliasing_Demo.m','Prepare_Sampling_Handoff.m','Plot_Sampling_Comparisons.m','Check_Sampling_Handoff.m']]
inputs += [ROOT/'Matlab/Compare_All_Sampling.m'] + list((ROOT/'Simulink').glob('SamplingModel*.slx'))
inputs += [p for p in RESULTS.iterdir() if p.suffix in ('.mat','.csv','.wav','.png') and p.name!='sha256_manifest.csv']
with (RESULTS/'sha256_manifest.csv').open('w',newline='',encoding='utf-8') as f:
    writer=csv.writer(f); writer.writerow(['RelativePath','HashedBytes','HashMode','SHA256'])
    for p in sorted(inputs):
        content=p.read_bytes()
        # Git on Windows may convert text line endings on checkout.
        mode='text-lf' if p.suffix in ('.m','.csv','.py','.json','.md','.txt') else 'raw'
        if mode=='text-lf': content=content.replace(b'\r\n',b'\n')
        writer.writerow([p.relative_to(ROOT).as_posix(),len(content),mode,hashlib.sha256(content).hexdigest()])
verification=dict(date='2026-11-03',matlabResultsDate='2026-11-01',platform='MATLAB and Simulink R2026a',caseCount=8,simulinkCaseCount=8,wavCount=8,comparisonFigures=13,pdfPages=19,aliasOriginalHz=float(alias[0]['PeakHz']),aliasUnfilteredHz=float(alias[1]['PeakHz']),aliasSuppressionDb=suppression,maxWavRoundTripError=max_error,remainingSimulink='Sampling comparisons complete; combined-case integration and final review pending',listeningPerformed=False,fullCombinedMatrixComplete=False)
(RESULTS/'verification.json').write_text(json.dumps(verification,indent=2)+'\n',encoding='utf-8')
print(f'CREATED {PDF} ({len(pages)} pages)'); print(f'CREATED {MD}'); print(json.dumps(verification,indent=2))
