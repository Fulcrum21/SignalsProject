"""Concise report section from existing verified evidence; no experiments rerun."""
from pathlib import Path
import csv, math, html, re, json
from PIL import Image as PIL
from reportlab.pdfgen import canvas
from reportlab.lib.pagesizes import A4
from reportlab.lib import colors
from reportlab.lib.styles import ParagraphStyle
from reportlab.platypus import Paragraph, Table, TableStyle, Image, Spacer, Frame, Preformatted
from pypdf import PdfReader

ROOT=Path(__file__).resolve().parents[1]
R=ROOT/'Results/Abdulrahman/Sampling'
OUT=ROOT/'output/pdf'
ASSET=OUT/'sampling_section_assets'
ASSET.mkdir(exist_ok=True)
def read(name):
    with (R/name).open(encoding='utf-8-sig',newline='') as f: return list(csv.DictReader(f))
cases=read('case_manifest.csv'); checks=read('simulink_comparison.csv'); alias=read('aliasing_summary.csv')
assert len(cases)==len(checks)==8
assert all(float(x['MaxAbsDifference'])<=float(x['Tolerance']) for x in checks)
suppression=20*math.log10(float(alias[1]['PeakAmplitude'])/float(alias[2]['PeakAmplitude']))
W,H=A4; CW=W-84
styles={
 'body':ParagraphStyle('body',fontName='Helvetica',fontSize=10.2,leading=14,spaceAfter=8),
 'title':ParagraphStyle('title',fontName='Helvetica-Bold',fontSize=19,leading=23,spaceAfter=13,textColor=colors.HexColor('#14364a')),
 'head':ParagraphStyle('head',fontName='Helvetica-Bold',fontSize=11,leading=15,spaceBefore=7,spaceAfter=6),
 'caption':ParagraphStyle('caption',fontName='Helvetica',fontSize=9,leading=12,spaceAfter=10),
 'cell':ParagraphStyle('cell',fontName='Helvetica',fontSize=9,leading=12),
}
pages=[]; md=[]; story=[]
def text(s,kind='body'):
    story.append(Paragraph(html.escape(s),styles[kind])); md.append(s+'\n')
def head(s): text(s,'head')
def code(s):
    story.extend([Preformatted(s,ParagraphStyle('code',fontName='Courier',fontSize=8.6,leading=12)),Spacer(1,8)])
    md.append('```matlab\n'+s+'\n```\n')
def table(headers,rows):
    cells=[[Paragraph(html.escape(str(v)),styles['cell']) for v in row] for row in [headers]+rows]
    t=Table(cells,colWidths=[CW/len(headers)]*len(headers))
    t.setStyle(TableStyle([('BACKGROUND',(0,0),(-1,0),colors.HexColor('#e0edf2')),('VALIGN',(0,0),(-1,-1),'TOP'),('BOTTOMPADDING',(0,0),(-1,-1),7),('TOPPADDING',(0,0),(-1,-1),6),('LINEBELOW',(0,0),(-1,0),.6,colors.HexColor('#7594a4'))]))
    story.extend([t,Spacer(1,10)])
    md.extend(['| '+' | '.join(headers)+' |','| '+' | '.join(['---']*len(headers))+' |']+['| '+' | '.join(map(str,row))+' |' for row in rows]+[''])
def picture(name,caption,maxh=245,crop=False):
    p=R/name
    if crop:
        im=PIL.open(p); im.crop((0,0,im.width,int(im.height*.50))).save(ASSET/name)
        p=ASSET/name
    with PIL.open(p) as im: w,h=im.size
    scale=min(CW/w,maxh/h)
    story.append(Image(str(p),width=w*scale,height=h*scale))
    text(caption,'caption')
    md.append(f'![{caption}](../{p.relative_to(ROOT).as_posix()})\n')
def page(title):
    global story
    story=[]; pages.append((title,story)); story.append(Paragraph(html.escape(title),styles['title'])); md.append('## '+title+'\n')

page('Task 2: Downsampling and aliasing')
text('Abdulrahman Junaid | CCEN 302 | 5 November 2026','caption')
text('The objective was to reduce the sampling rate of the same speech/music recording and compare conversion with and without an anti-aliasing (AA) low-pass filter. The original recording contains 882,005 mono samples at 44.1 kHz in a 16-bit PCM WAV file, approximately 20 seconds long. Acquisition and baseline analysis are described in Task 1.')
head('Why aliasing occurs')
text('Sampling rate is the number of measurements taken each second. The Nyquist limit is half that rate: fN = Fs/2. To avoid aliasing, the signal must be sufficiently band-limited below this limit. Otherwise, different continuous frequencies can produce the same samples, and high-frequency energy appears at a lower frequency. This false lower-frequency content is called aliasing.')
text('An AA low-pass filter suppresses frequencies above the new usable band before samples are removed. Filtering after downsampling cannot separate an alias from genuine content at the same frequency. Practical filters have a transition band and finite attenuation, rather than a perfect cutoff.')
table(['Output rate (Hz)','Nyquist (Hz)','Ratio p/q','Samples/path'],[[r['Fs'],f"{int(r['Fs'])/2:g}",r['p']+'/'+r['q'],r['sampleCount']] for r in cases[::2]])
head('Controlled comparison')
text('Every branch starts from the unchanged original recording. There is no independent amplitude normalization or reduced-bit quantizer in these sampling tests. The MAT files retain double-valued processing samples; the 16-bit label identifies the source/control, and exported WAVs use a 16-bit PCM container. Export rounding is separate from the sampling effect.')
text('The evidence combines real-audio waveform, FFT and spectrogram comparisons with an existing known-frequency tone. The tone makes frequency folding identifiable; the real recording demonstrates the effect on a complex signal.')

page('2.1 MATLAB methods and analysis')
head('Integer and non-integer conversion')
code('yNoFilter = x(1:2:end);       % 22.05 kHz\nyNoFilter11025 = x(1:4:end);  % 11.025 kHz')
text('Starting at index 1 keeps the first sample at t = 0. These branches retain every second or fourth sample without a dedicated AA filter. They are played and plotted using their actual lower sampling rates; changing only a rate label would change playback speed.')
code('[p, q] = rat(FsOutput / Fs);\nyNoFilterRate = interp1(originalTime, x, outputTime, "linear");')
text('For 8 and 4 kHz, the ratios are 80/441 and 40/441. A constant integer indexing step cannot produce those exact rates. The code estimates samples at uniform target times by linear interpolation between adjacent source samples. Linear interpolation has a frequency response of its own; it is not an ideal transparent operation. Differences from the filtered path therefore include interpolation effects as well as AA filtering.')
code('[yFilteredRate, coefficientsRate] = resample(x, p, q, 10, 5);')
text('The filtered branch uses a Kaiser-window FIR design with n = 10 and beta = 5. MATLAB resample compensates its filter delay. The filters have 41, 81, 8,821 and 8,821 taps at the four respective rates. For rational conversion, the coefficients apply at the intermediate rate p times the input rate; polyphase processing avoids explicitly constructing a large zero-inserted signal.')
head('Fair plots and time alignment')
text('Waveforms use actual sample times and common amplitude limits. FFT magnitudes are divided by sample count; positive-frequency pairs are doubled, except DC and an exact Nyquist bin. Amplitude dB means 20 log10(A/1). A display floor of 1e-12 avoids log10(0), without modifying audio samples.')
text('Spectrograms use approximately 30 ms Hamming windows, 20 ms overlap and 2,048 FFT points at every rate. Color limits are shared: -130 to -30 dB relative to 1 sample-unit squared/Hz. A kHz horizontal or vertical frequency label does not change PSD units from per Hz to per kHz. Zero-padding increases plotted grid density, not true frequency resolution.')
text('For later quality evaluation, resampling back to 44.1 kHz restores a common time grid, not lost information. The full original sample interval is retained, without optimized time shifts or error-based edge trimming. Boundary effects remain in the comparison.')

page('2.2 Real-audio frequency comparisons')
for i,rate in enumerate([22050,11025,8000,4000],1):
    picture(f'spectra_{rate}.png',f'Figure 2.{i}. {rate:,} Hz output: original and both processing paths; dashed line marks the new Nyquist limit. Amplitude scale is linear.',maxh=116,crop=True)
text('The largest original components lie at low frequencies, so the strongest peaks often overlap after filtering. This does not mean filtering is unnecessary: weaker high-frequency content can still fold into the retained band. At 4 kHz, only the band below 2 kHz remains available, making bandwidth loss and method differences more consequential.')
text('These full-band views locate the removed bandwidth. Full-resolution shared-band dB views are supplied in the results folder for inspecting smaller differences. Individual peaks in speech/music cannot reliably be assigned an alias origin without a known-frequency reference.')

page('2.3 Reading the time-frequency evidence')
picture('waveforms_4000.png','Figure 2.5. At 4 kHz, the full waveform preserves the broad time envelope while the common short-time zoom reveals local differences.',maxh=177)
picture('spectrograms_4000.png','Figure 2.6. Original, unfiltered and filtered signals shown over the same 0-2 kHz band with common PSD color limits.',maxh=228)
text('The envelope describes when the recording is loud or quiet; it does not establish that fine detail is preserved. Horizontal spectrogram bands represent sustained components, while short vertical changes indicate time-local activity. Shared axes and color limits prevent a rescaled display from hiding processing differences.')
text('Above-band original content is visible in Figure 2.4, not in this deliberately shared-band spectrogram. The 4 kHz output cannot retain that original high-frequency information faithfully. Appendix A supplies corresponding waveform and spectrogram views for the other three rates.')

page('2.4 A directly identifiable alias')
picture('aliasing_10000_to_1025.png','Figure 2.7. Existing 10 kHz sine: original, unfiltered reduction to 11.025 kHz, and filtered reduction on comparable amplitude scales.',maxh=305)
text('The new Nyquist limit is 5,512.5 Hz, so the 10 kHz tone lies above it. Sampling at 11,025 Hz makes it indistinguishable from a 1,025 Hz tone:')
text('Predicted alias = |10,000 - 11,025| = 1,025 Hz.','head')
table(['Path','Measured peak (Hz)','Peak amplitude'],[[r['Signal'],r['PeakHz'],f"{float(r['PeakAmplitude']):.8g}"] for r in alias])
text(f'The unfiltered peak agrees with the prediction and retains approximately the original amplitude. With filtering, the largest measured residual is much smaller. The suppression is 20 log10(Aunfiltered/Afiltered) = {suppression:.2f} dB. This is measured residual suppression for this tone, not a general SNR improvement or a claim of perfect rejection.')
text('The known tone establishes frequency folding unambiguously. Together with the real recording, it supports both the theoretical explanation and the practical comparison required by the project.')

page('2.5 Simulink implementation and agreement')
head('Equivalent sampling branches')
code('44.1 kHz source -> Downsample (2 or 4) -> unfiltered log\n               -> FIR Decimation     -> filtered log\n\n44.1 kHz source -> Linear interpolation -> unfiltered log\n               -> FIR Rate Conversion -> filtered log\n                  L/M = 80/441 or 40/441')
text('The integer models use the same selection offset and FIR coefficients as MATLAB. The 8/4 kHz models use 4,410-sample input frames: interpolation produces 800/400 samples, and FIR Rate Conversion uses the matching rational ratio. These saved models were run in R2026a for 20 seconds.')
text('Logged frames were flattened into sample columns. The known FIR delay of 10 output samples was removed from each filtered branch, and surplus final-frame samples were discarded to match the exact reference interval. This corrects implementation timing; it does not optimize the result to conceal signal degradation.')
table(['Rate (Hz)','Filter','Delay removed','Max abs difference'],[[r['FsHz'],r['FilterMode'],r['RemovedDelayOutputSamples'],f"{float(r['MaxAbsDifference']):.3g}"] for r in checks])
text('All eight cases pass: tolerance 1e-10 without filtering and 1e-12 with filtering. At 8/4 kHz, frame-relative and whole-record interpolation use slightly different floating-point arithmetic. Filtered differences are at rounding scale. These results establish MATLAB/Simulink agreement; they are not NMSE or SNR against the original recording.')
text('The source-connected FFT/spectrogram displays show the original signal, not the logged processed branches. Frame FFTs also differ from a full-record FFT. With 4,410-sample frames, the final frame contains only five real samples followed by padding, so its small broad spectrum is not representative of the whole recording.')
code('% From repository root, reproduce the saved-model comparison:\naddpath("Matlab")\nCompare_All_Sampling')

page('2.6 Discussion and conclusion')
head('What the experiment establishes')
text('Reducing the rate lowers the maximum usable bandwidth. Anti-aliasing filtering deliberately removes above-band content before conversion so it does not reappear as false lower-frequency content. The 10 kHz test provides the clearest evidence: the predicted and measured alias are both 1,025 Hz, and filtering strongly suppresses the residual.')
text('The real-audio comparisons show why a waveform alone is insufficient. A similar overall envelope can coexist with lost bandwidth and changed spectral detail. At higher output rates, filtered and unfiltered curves can nearly overlap because the recording has relatively little energy in the affected band. At 4 kHz, preserving only frequencies below 2 kHz imposes a stronger limitation.')
head('Limitations and handoff')
text('The unfiltered rational-rate branches use linear interpolation, so their differences cannot be attributed exclusively to filtering. FIR filters also have finite transition bands and attenuation. Reconstructing to the original rate supports a valid time-grid comparison but cannot reverse aliasing or restore removed frequencies. No independent normalization was used.')
text('The sampling handoff contains eight MATLAB controls and eight aligned Simulink controls with actual rates and timing metadata. Reduced-bit quantization, total NMSE/SNR, storage and case-specific listening interpretations are reported in the corresponding team sections. Abdulrahman reports that listening checks were completed; no unsupplied subjective observations are asserted here.')
head('Conclusion')
text(f'All four requested lower rates were implemented with both filter modes, and all eight platform comparisons passed their declared tolerances. The known-tone result confirms frequency folding predicted by sampling theory, with {suppression:.2f} dB measured suppression of the largest residual after filtering. The evidence demonstrates the need to filter before reduction while preserving the distinction between bandwidth loss, aliasing and numerical implementation error.')
head('References and reproducibility')
text('[1] CCEN 302 Project-3.pdf, sampling/aliasing requirements and grading criteria. [2] Project source: Sampling_Abdulrahman.m, Sampling_OtherRates.m, Aliasing_Demo.m and Compare_All_Sampling.m. [3] Saved evidence: case_manifest.csv, aliasing_summary.csv, alignment_checks.csv and simulink_comparison.csv in Results/Abdulrahman/Sampling. Measurements were produced in MATLAB/Simulink R2026a; this report revision reuses those results.')
text('[4] MathWorks documentation: resample (mathworks.com/help/signal/ref/resample.html), interp1 (mathworks.com/help/matlab/ref/interp1.html), fft (mathworks.com/help/matlab/ref/fft.html), and spectrogram (mathworks.com/help/signal/ref/spectrogram.html).')

for rate in [22050,11025,8000]:
    page(f'Appendix A: {rate:,} Hz comparisons')
    picture(f'waveforms_{rate}.png',f'Figure A{rate}-1. Full waveform and common short-time zoom. Original and both processing paths use matching amplitude/time conventions.',maxh=260)
    picture(f'spectrograms_{rate}.png',f'Figure A{rate}-2. Original, unfiltered and filtered PSD on the shared 0-{rate/2000:g} kHz band, with the settings stated in Section 2.1.',maxh=300)
    text('These supporting plots complete the time-domain and time-frequency evidence across all four requested output rates. Full-resolution FFT plots, including shared-band dB views, remain in the reproducible results folder.','caption')

pdfpath=OUT/'Abdulrahman_Sampling_Report_Draft.pdf'
c=canvas.Canvas(str(pdfpath),pagesize=A4)
c.setTitle('Task 2 - Downsampling and Aliasing'); c.setAuthor('Abdulrahman Junaid')
for n,(title,flow) in enumerate(pages,1):
    c.setFillColor(colors.HexColor('#14364a'));c.setFont('Helvetica',8)
    c.drawString(42,H-28,'CCEN 302 | ABDULRAHMAN | SAMPLING AND ALIASING')
    c.drawRightString(W-42,26,f'{n} / {len(pages)}')
    c.drawString(42,26,'Main section: pages 1-7 | Supporting comparisons: Appendix A')
    c.bookmarkPage(str(n));c.addOutlineEntry(title,str(n),0)
    remaining=list(flow)
    Frame(42,48,CW,H-96,leftPadding=0,rightPadding=0,topPadding=0,bottomPadding=0).addFromList(remaining,c)
    assert not remaining,f'Page {n} overflows: {title}'
    c.showPage()
c.save()
assert len(PdfReader(pdfpath).pages)==10
verification_path=R/'verification.json'
verification=json.loads(verification_path.read_text(encoding='utf-8'))
verification.update(pdfPages=10,reportRevisionDate='2026-11-05',reportMainPages=7,reportAppendixPages=3,listeningReportedByOwner=True)
verification_path.write_text(json.dumps(verification,indent=2)+'\n',encoding='utf-8')
(ROOT/'Reports/Abdulrahman_Sampling.md').write_text('# Task 2: Sampling Rate Reduction and Aliasing\n\n'+'\n'.join(md),encoding='utf-8')
qa='''# Sampling and aliasing: short Q&A preparation

1. **What does AA mean?** Anti-aliasing: a low-pass filter used before reducing the sampling rate.
2. **Why half the sampling rate?** Frequencies separated by sampling-frequency multiples can produce the same samples. For real signals, frequencies above half the rate fold into the positive baseband.
3. **Why does 10 kHz become 1,025 Hz?** At 11,025 samples/s, its samples match a tone at |10,000 - 11,025| = 1,025 Hz (up to phase/sign).
4. **Why not filter afterward?** The alias already overlaps genuine low-frequency content; a later filter cannot tell them apart.
5. **Why interpolate at 8/4 kHz?** Neither rate is an integer divisor of 44.1 kHz. We evaluate the original signal on exact new sample times using linear interpolation for the unfiltered comparison.
6. **Does interpolation prevent aliasing?** It affects frequency response but is not the dedicated new-Nyquist AA filter used by the filtered branch.
7. **What do p and q mean?** Interpolation and decimation factors: new Fs = old Fs × p/q. They are 80/441 for 8 kHz and 40/441 for 4 kHz.
8. **What is Kaiser?** The window family used to design the FIR filter; beta controls its shape. Our settings are n = 10 and beta = 5.
9. **Why remove 10 output samples in Simulink?** The causal FIR introduces a known delay. MATLAB resample compensates its designed delay, so that delay must be handled before comparing matching physical times.
10. **Why trim the final frame?** Frame processing pads beyond the original recording. We retain the actual reference sample count, not extra padding.
11. **Do near-zero platform differences mean perfect audio?** No. They show the two implementations agree. Degradation against the original is a separate NMSE/SNR measurement.
12. **Does upsampling recover lost information?** No. It reconstructs a comparison time grid; it cannot recover discarded bandwidth or undo aliasing.
13. **Why do filtered and unfiltered graphs overlap?** Much of the recording's energy is already in the retained band. Small differences may be clearer on dB axes.
14. **Is 68.74 dB the output SNR?** No. It is the measured amplitude suppression of the largest residual relative to the unfiltered alias in the known-tone test.
15. **How do FFT dB and spectrogram dB differ?** FFT amplitude uses 20 log10; spectrogram PSD uses a power-density reference and 10 log10. A frequency axis in kHz does not itself change per-Hz density units.

Practice: explain questions 3, 5, 9 and 11 aloud while pointing to the matching report figure or table. Read the code before answering follow-up questions about implementation.
'''
(ROOT/'Reports/Abdulrahman_Sampling_QA.md').write_text(qa,encoding='utf-8')
print(f'Created {pdfpath}: 7 main pages + 3 appendix pages; editable section and Q&A sheet.')
