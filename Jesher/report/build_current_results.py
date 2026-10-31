"""Build the current three-case report from verified MATLAB artifacts.

Run with Python and ReportLab, NumPy, SciPy and Markdown available.
Regenerate figures first using Prepare_Current_Report_Figures in MATLAB.
This replaces metrics_playback_draft.md with the current measured section.
"""
from __future__ import annotations

import csv
import hashlib
import html
import json
import math
import re
import wave
import zipfile
from datetime import datetime, timezone
from pathlib import Path

import markdown
import numpy as np
from scipy.io import loadmat
from scipy.signal import resample_poly
from reportlab.lib import colors
from reportlab.lib.enums import TA_LEFT
from reportlab.lib.pagesizes import A4
from reportlab.lib.styles import ParagraphStyle, getSampleStyleSheet
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.ttfonts import TTFont
from reportlab.platypus import (
    SimpleDocTemplate, Paragraph, Spacer, Table, TableStyle, Image, PageBreak,
)

ROOT = Path(__file__).resolve().parents[2]
REPORT = Path(__file__).resolve().parent
RUN = ROOT / 'Jesher/results/matlab_run_20261030_170138_859'
PDF = REPORT / 'output/pdf/Jesher_Current_MATLAB_Results.pdf'
IDS = [
    'speechmusic_fs44100_b16_native_matlab',
    'speechmusic_fs22050_b16_lpf_matlab',
    'speechmusic_fs22050_b16_none_matlab',
]
LABELS = ['Native reference', 'Filtered (lpf)', 'Unfiltered (none)']


def rows(path):
    with path.open(encoding='utf-8', newline='') as stream:
        return list(csv.DictReader(stream))


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def pcm(path):
    with wave.open(str(path), 'rb') as stream:
        assert stream.getnchannels() == 1 and stream.getsampwidth() == 2
        assert stream.getcomptype() == 'NONE'
        rate = stream.getframerate()
        count = stream.getnframes()
        values = np.frombuffer(stream.readframes(count), dtype='<i2').astype(float)/32768
    assert len(values) == count
    return rate, values


def verify():
    metrics = rows(RUN/'metrics.csv')
    assert len(metrics) == 3 and {r['caseId'] for r in metrics} == set(IDS)
    metrics = [next(r for r in metrics if r['caseId'] == case) for case in IDS]
    manifest = rows(RUN/'audio_package/manifest.csv')
    summary = json.loads((RUN/'run_summary.json').read_text())
    assert summary['availableCases'] == 3 and not summary['matrixComplete']
    assert summary['archiveBytesVerified']
    coverage = rows(RUN/'case_coverage.csv')
    assert len(coverage) == 72 and len({r['caseId'] for r in coverage}) == 72
    assert sum(r['status'] == 'missing_handoff' for r in coverage) == 69
    saved = loadmat(RUN/'evaluation.mat', simplify_cells=True,
                    variable_names=['cases','reference','referenceFs'])
    x = saved['reference']
    assert saved['referenceFs'] == 44100 and len(x) == 882005
    prototype = loadmat(RUN/'input_snapshot/001_sampling_22050.mat',
                        simplify_cells=True)['prototype']
    h = prototype['filter']['coefficients']
    original_rate, original = pcm(RUN/'audio_package/original/SpeechMusic.wav')
    assert original_rate == 44100 and np.array_equal(x, original)
    assert sha(ROOT/'Audios/SpeechMusic.wav') == sha(RUN/'audio_package/original/SpeechMusic.wav')
    checks = []
    for row in metrics:
        c = next(c for c in saved['cases'] if c['caseId'] == row['caseId'])
        y = c['samples']
        rate = int(row['Fs'])
        assert len(y) == int(row['sampleCount'])
        assert c['Fs'] == rate and not c['quantizationApplied']
        assert not c['normalizationApplied'] and c['firstSampleTimeSeconds'] == 0
        assert c['delayCompensated'] and row['alignmentPolicy'] == 'aa03_full_record_v1'
        assert int(row['comparisonSampleCount']) == len(x)
        assert math.isclose(float(row['durationSeconds']), len(y)/rate, abs_tol=1e-12)
        assert math.isclose(float(row['comparisonLastTimeSeconds']), (len(x)-1)/44100, abs_tol=1e-12)
        aligned = y if rate == 44100 else resample_poly(y,2,1,window=h)[:len(x)]
        ex = float(np.sum(x*x))
        ee = float(np.sum((x-aligned)**2))
        nmse = ee/ex
        snr = math.inf if ee == 0 else 10*math.log10(ex/ee)
        assert math.isclose(nmse, float(row['nmse']), rel_tol=1e-11, abs_tol=1e-15)
        assert math.isclose(snr, float(row['snrDb']), abs_tol=1e-10)
        assert math.isclose(ex, float(row['referenceEnergy']), rel_tol=1e-12)
        assert math.isclose(ee, float(row['errorEnergy']), rel_tol=1e-11, abs_tol=1e-14)
        wav_path = RUN/'audio_package'/row['wavFile']
        wav_rate, exported = pcm(wav_path)
        assert wav_rate == rate and len(exported) == len(y)
        assert wav_path.stat().st_size == int(row['wavFileBytes'])
        maximum = float(np.max(np.abs(exported-y)))
        rms = float(np.sqrt(np.mean((exported-y)**2)))
        assert math.isclose(maximum, float(row['wavMaxAbsRoundTripError']), rel_tol=1e-10, abs_tol=1e-15)
        assert math.isclose(rms, float(row['wavRmsRoundTripError']), rel_tol=1e-10, abs_tol=1e-15)
        aligned_export = exported if rate == 44100 else resample_poly(exported,2,1,window=h)[:len(x)]
        exported_error = float(np.sum((x-aligned_export)**2))
        export_nmse = exported_error/ex
        export_snr = math.inf if exported_error == 0 else 10*math.log10(ex/exported_error)
        assert math.isclose(export_nmse, float(row['exportedNmse']), rel_tol=1e-11, abs_tol=1e-15)
        assert math.isclose(export_snr, float(row['exportedSnrDb']), abs_tol=1e-10)
        mr = next(r for r in manifest if r['caseId'] == row['caseId'])
        assert int(mr['Fs']) == rate and int(mr['fileBytes']) == wav_path.stat().st_size
        assert int(mr['containerBits']) == 16 and int(mr['clippedSamples']) == 0
        checks.append({'case_id':row['caseId'],'metrics_recomputed':True,
                       'export_metadata_and_error_verified':True,'wav_sha256':sha(wav_path)})
    assert len(manifest) == 4
    for item in manifest:
        path = RUN/'audio_package'/item['wavFile']
        actual_rate, actual_samples = pcm(path)
        assert actual_rate == int(item['Fs']) and len(actual_samples) == int(item['sampleCount'])
        assert path.stat().st_size == int(item['fileBytes'])
        assert path.stat().st_size - 2*len(actual_samples) == 44
        assert int(item['channels']) == 1 and int(item['containerBits']) == 16
    expected_files = {r['wavFile'] for r in manifest} | {'manifest.csv','case_coverage.csv'}
    with zipfile.ZipFile(RUN/summary['archiveFile']) as archive:
        assert {n for n in archive.namelist() if not n.endswith('/')} == expected_files
        for name in expected_files:
            assert archive.read(name) == (RUN/'audio_package'/name).read_bytes()
    diary = (ROOT/'Jesher/results/matlab_session_20261030_170012.txt').read_text(encoding='utf-8')
    diary = re.sub('<[^>]+>','',diary)
    passed = re.findall(r"\{'TestJesher[^']+'\s*\}\s+true\s+false\s+false",diary)
    assert len(passed) == 19
    for figure in ['figure_01_native.png','figure_02_filtered.png','figure_03_unfiltered.png']:
        assert (REPORT/'figures'/figure).is_file()
    return metrics, manifest, summary, checks


def main():
    metrics, manifest, summary, checks = verify()
    PDF.parent.mkdir(parents=True,exist_ok=True)
    pdfmetrics.registerFont(TTFont('Arial','C:/Windows/Fonts/arial.ttf'))
    pdfmetrics.registerFont(TTFont('Arial-Bold','C:/Windows/Fonts/arialbd.ttf'))
    pdfmetrics.registerFont(TTFont('Arial-Italic','C:/Windows/Fonts/ariali.ttf'))
    pdfmetrics.registerFontFamily('Arial',normal='Arial',bold='Arial-Bold',italic='Arial-Italic',boldItalic='Arial-Bold')
    styles = getSampleStyleSheet()
    for style in styles.byName.values():
        style.fontName = 'Arial'
    body = ParagraphStyle('BodyReport',fontName='Arial',fontSize=10.2,leading=14.4,
                          textColor=colors.HexColor('#1E293B'),spaceAfter=8)
    heading = ParagraphStyle('HeadingReport',parent=body,fontName='Arial-Bold',fontSize=16,leading=20,
                             textColor=colors.HexColor('#123B54'),spaceAfter=11)
    subheading = ParagraphStyle('SubheadingReport',parent=heading,fontSize=11.5,leading=15,spaceBefore=5,spaceAfter=7)
    title_style = ParagraphStyle('ReportTitle',parent=heading,fontSize=25,leading=29,spaceAfter=14)
    caption_style = ParagraphStyle('ReportCaption',parent=body,fontSize=9,leading=12,spaceAfter=10)
    table_style = ParagraphStyle('TableCellReport',parent=body,fontSize=9,leading=12,spaceAfter=0)
    width = A4[0]-88
    story = []
    md = []
    def text(value,style=body):
        story.append(Paragraph(value,style))
        md.append(re.sub(r'<b>(.*?)</b>',r'**\1**',value).replace('<i>','*').replace('</i>','*'))
        md.append('')
    def head(value,level=1):
        story.append(Paragraph(value,heading if level==1 else subheading))
        md.extend([('#'*(level+1))+' '+value,''])
    def page():
        story.append(PageBreak()); md.extend(['<!-- pagebreak -->',''])
    def table(caption,headers,data,widths):
        text('<b>'+caption+'</b>',caption_style)
        cells = [[Paragraph('<b>'+html.escape(str(c))+'</b>',table_style) for c in headers]]
        cells += [[Paragraph(html.escape(str(c)),table_style) for c in row] for row in data]
        t = Table(cells,colWidths=[width*w/sum(widths) for w in widths],repeatRows=1,hAlign='LEFT')
        t.setStyle(TableStyle([
            ('BACKGROUND',(0,0),(-1,0),colors.HexColor('#E7EFF4')),
            ('ROWBACKGROUNDS',(0,1),(-1,-1),[colors.white,colors.HexColor('#F6F8FA')]),
            ('VALIGN',(0,0),(-1,-1),'TOP'),('LINEBELOW',(0,0),(-1,0),.7,colors.HexColor('#9BB3C4')),
            ('BOTTOMPADDING',(0,0),(-1,-1),7),('TOPPADDING',(0,0),(-1,-1),7),
            ('LEFTPADDING',(0,0),(-1,-1),7),('RIGHTPADDING',(0,0),(-1,-1),7),
        ]))
        story.extend([t,Spacer(1,10)])
        md.extend(['| '+' | '.join(headers)+' |','| '+' | '.join(['---']*len(headers))+' |'])
        md.extend('| '+' | '.join(map(str,row))+' |' for row in data); md.append('')
    def figure(filename,caption):
        path = REPORT/'figures'/filename
        im = Image(str(path)); im.drawHeight = width*im.imageHeight/im.imageWidth; im.drawWidth = width
        story.extend([im,Spacer(1,6)])
        md.extend(['![Comparison figure](figures/'+filename+')',''])
        text(caption,caption_style)

    md.extend(['# MATLAB quality metrics, audio output and listening results',''])
    story.append(Paragraph('MATLAB audio quality<br/>Results with current resources',title_style))
    text('<b>CCEN 302 - Jesher | Report section prepared 31 October 2026</b>')
    text('Measured run: 30 October 2026, 17:02:11 Asia/Dubai. MATLAB R2026b Update 1. '
         'This section completes the presentation of the three currently available MATLAB controls; '
         'the full MATLAB/Simulink experiment remains incomplete.')
    table('Table 1. Evaluated mono signals and actual sample counts.',
          ['Condition','Rate (Hz)','Samples','Duration N/Fs (s)'],
          [[label,f"{int(r['Fs']):,}",f"{int(r['sampleCount']):,}",f"{float(r['durationSeconds']):.9f}"]
           for label,r in zip(LABELS,metrics)],[38,18,20,30])
    text('Input: Audios/SpeechMusic.wav, mono 44,100 Hz, 16-bit PCM. The lower-rate arrays are '
         'sampling-only double-precision outputs. Their b16 identifiers refer to source/control '
         'precision; no additional quantizer was applied.')
    table('Table 2. Total processing error before WAV conversion, on the aligned original grid.',
          ['Condition','NMSE','SNR (dB)','Metric status'],
          [[label,f"{float(r['nmse']):.12g}",'+Inf' if math.isinf(float(r['snrDb'])) else f"{float(r['snrDb']):.8f}",r['metricStatus']]
           for label,r in zip(LABELS,metrics)],[32,27,22,23])
    improvement = float(metrics[1]['snrDb'])-float(metrics[2]['snrDb'])
    reduction = 100*(1-float(metrics[1]['nmse'])/float(metrics[2]['nmse']))
    text(f'The filtered case has {improvement:.4f} dB higher SNR and {reduction:.2f}% lower '
         'NMSE than the unfiltered case for this recording and comparison policy. These are '
         'objective error comparisons, not a measured listening preference. The unchanged '
         'control has zero error and therefore +Inf SNR by definition.')
    text('Coverage: <b>3/36 MATLAB cases and 0/36 Simulink cases</b> evaluated by this run. '
         'The remaining 69 entries are explicitly missing, rather than assigned estimated scores.')

    page(); head('Comparison and analysis method')
    head('Alignment and metric definitions',2)
    text('Let E_reference = sum(x[n]^2), and E_error = sum((x[n] - y_aligned[n])^2), '
         'where both arrays represent the same physical times. The implemented measures are:')
    text('<b>NMSE = E_error / E_reference</b><br/><b>SNR_dB = 10 log10(E_reference / E_error)</b>')
    text('For positive reference and error energies, SNR_dB = -10 log10(NMSE). Unchanged '
         'nonzero input gives NMSE = 0 and SNR = +Inf. Zero reference and zero error give '
         'NaN/NaN; zero reference with positive error gives +Inf/-Inf. Explicit statuses '
         'distinguish these cases; no epsilon is inserted to manufacture a finite score.')
    text('AA03 alignment reconstructs each 22,050 Hz array using resample(y,2,1,10,5). '
         'This yields 882,006 samples; only the final unmatched endpoint is discarded. '
         'All 882,005 original samples are compared, from t = 0 to '
         '20.000090702948 s. No extra edge trimming, lag search, fitted gain or independent '
         'normalization is used. Existing MATLAB FIR delay compensation is not repeated.')
    text('The filtered producer uses resample(x,1,2,10,5), a 41-tap FIR (order 40), Kaiser '
         'beta = 5, with its delay compensated. The unfiltered producer selects x(1:2:end) '
         'directly. Reference and processing arrays are retained in evaluation.mat and the '
         'producer handoff is copied into input_snapshot/.')
    table('Table 3. Matched figure settings applied to original and reconstructed signals.',
          ['Analysis','Settings'],[
              ['Waveform','Full comparison interval; common amplitude limits within each figure.'],
              ['FFT','Full-record N = 882,005; divide magnitude by N; double paired positive-frequency bins; no extra taper.'],
              ['FFT scale','20 log10(amplitude); reference digital amplitude 1; display floor -160 dB.'],
              ['Spectrogram','Periodic Hann window: 1,024 samples; overlap: 768 (75%); hop: 256; DFT: 2,048; analysis rate: 44,100 Hz.'],
              ['PSD scale','One-sided PSD; 10 log10(PSD), digital amplitude squared per Hz; color limits -160 to 0 dB.'],
          ],[24,76])
    text('The spectrogram window spans approximately 23.22 ms and its hop is 5.805 ms; '
         'the DFT-bin spacing is 21.5332 Hz. Bin spacing is not a claim of independent '
         'frequency resolution. All displayed dB levels are digital measures, not calibrated sound-pressure levels.',caption_style)

    page(); head('Native reference: unchanged 44,100 Hz control')
    figure('figure_01_native.png',
           '<b>Figure 1.</b> Native reference control, speechmusic_fs44100_b16_native_matlab. '
           'Panels (a,c,e) show the original; (b,d,f) show the unchanged control. Rows show '
           'waveform, single-sided FFT magnitude and PSD spectrogram. Both columns use the '
           '44,100 Hz grid and the matched settings in Table 3. No rate conversion or additional quantization is applied.')
    text('<b>Waveform.</b> Both columns preserve the same approximately 20-second envelope, '
         'early transients and later sustained sections. They coincide because the samples '
         'are identical, not merely because the plot appears similar.')
    text('<b>FFT and spectrogram.</b> The spectra and time-frequency patterns coincide. '
         'The strongest plotted components are concentrated toward lower frequencies, '
         'with weaker upper-frequency content. Later horizontal bands indicate sustained '
         'harmonic structure. This control produces NMSE = 0 and SNR = +Inf; neither '
         'value establishes the acoustic noise level of the original recording.')

    page(); head('Filtered sampling: 44,100 to 22,050 Hz')
    figure('figure_02_filtered.png',
           '<b>Figure 2.</b> Filtered sampling control, speechmusic_fs22050_b16_lpf_matlab. '
           'Original panels (a,c,e) are compared with processed panels (b,d,f) after '
           'reconstruction to 44,100 Hz. Dashed lines mark the reduced-rate Nyquist '
           'frequency, 11.025 kHz. The 22,050 Hz processing array contains 441,003 samples; '
           'the plotted comparison retains all 882,005 original sample times.')
    text('<b>Waveform.</b> The principal envelope, transient timing and quieter intervals '
         'remain visually similar at the full-record scale. This appearance does not '
         'establish sample identity; the nonzero metric error quantifies the difference.')
    text('<b>FFT and spectrogram.</b> Dominant lower-frequency structure is retained, '
         'while the spectrum rolls off near the reduced-rate Nyquist region and upper-band '
         'spectrogram power is strongly attenuated. The finite filter transition means '
         'this is not an ideal brick-wall cutoff. The displayed spectrum includes both '
         'the producer anti-aliasing filter and the subsequent reconstruction filter. '
         'Weak residual upper-band features do not demonstrate recovery of lost source content.')
    text('Before WAV conversion: <b>NMSE = 0.000807222473989; SNR = 30.93006755 dB.</b>')

    page(); head('Unfiltered sampling: 44,100 to 22,050 Hz')
    figure('figure_03_unfiltered.png',
           '<b>Figure 3.</b> Unfiltered sampling control, speechmusic_fs22050_b16_none_matlab. '
           'The producer selects every second original sample without prefiltering. '
           'Processed panels (b,d,f) are nevertheless reconstructed using a low-pass '
           'interpolation filter for comparison. Dashed lines mark 11.025 kHz; settings '
           'and panel ordering match Figure 2.')
    text('<b>Waveform.</b> The overall envelope and major events remain close to the '
         'original at this scale. Frequency-content changes can be present even when '
         'a full-record waveform comparison appears similar.')
    text('<b>FFT and spectrogram.</b> Upper-frequency attenuation is visible in the '
         'reconstructed result. It does not prove that anti-aliasing filtering preceded '
         'downsampling: the reconstruction itself suppresses high-frequency images. '
         'Original components above 11.025 kHz can fold into the retained band during '
         'unfiltered downsampling; reconstruction cannot reverse that folding. These '
         'broadband plots do not isolate a particular folded tone, so no specific alias '
         'frequency is claimed. Clear tone-based folding evidence remains separate work.')
    text('Before WAV conversion: <b>NMSE = 0.00122019794119; SNR = 29.13569712 dB.</b>')

    page(); head('Audio export, measured file sizes and listening')
    text('Each processed array was written at its actual rate into a mono 16-bit PCM WAV '
         'without independent normalization. Re-import checks recorded zero clipped samples, '
         'matching rates/counts and conversion errors no larger than one PCM16 step '
         '(1/32768). The source file is retained unchanged as original/SpeechMusic.wav.')
    table('Table 4. WAV conversion error and quality measured after re-import.',
          ['Condition','Max. sample error','RMS sample error','WAV NMSE','WAV SNR (dB)'],
          [[label,f"{float(r['wavMaxAbsRoundTripError']):.8g}",f"{float(r['wavRmsRoundTripError']):.8g}",
            f"{float(r['exportedNmse']):.10g}",'+Inf' if math.isinf(float(r['exportedSnrDb'])) else f"{float(r['exportedSnrDb']):.8f}"]
           for label,r in zip(LABELS,metrics)],[23,22,22,25,25])
    text('The filtered double array incurs a small additional PCM conversion error. '
         'The native and direct-selection arrays are already representable on the PCM16 '
         'grid and round-trip without sample error. Table 2 and Table 4 therefore '
         'describe distinct signal representations.')
    table('Table 5. Actual exported sizes; every WAV uses a 16-bit mono container.',
          ['File role','Rate (Hz)','Samples','File bytes'],
          [[('Retained original' if r['caseId']=='original_recording' else LABELS[IDS.index(r['caseId'])]),
            f"{int(r['Fs']):,}",f"{int(r['sampleCount']):,}",f"{int(r['fileBytes']):,}"]
           for r in manifest],[39,18,22,23])
    text('Each listed WAV has 44 bytes beyond its PCM sample payload (2 bytes per mono '
         'sample). The reduced-rate WAVs are approximately half the original file size. '
         'These are measured container sizes, not evidence of a reduced-bit quantizer.')
    head('Initial listening observation',2)
    text('Jesher reported that the original and both 22,050 Hz recordings were '
         '<b>audible and clear</b>. No specific hiss, harshness, muffling or perceptual '
         'ranking was reported. This one-listener observation is compatible with '
         'measurable processing error; it does not establish perceptual identity or '
         'a preference for either reduced-rate case.')
    text('The exact session time, device/routing, volume, playback gain, excerpt and '
         'intended-speed confirmation were not explicitly reported. Other teammates\' '
         'listening observations are not available. These details remain unconfirmed '
         'rather than being inferred from the playback instructions.')

    page(); head('Evidence, boundaries and remaining work')
    text('<b>Supported conclusion.</b> For the present recording, the filtered sampling '
         'control has lower aligned error than direct unfiltered downsampling, while '
         'both retain a recognizable waveform envelope and were reported audible and '
         'clear by Jesher. The unchanged control behaves as expected. The current '
         'evidence supports these three cases only.')
    table('Table 6. Current evaluation coverage.', ['Platform','Evaluated','Still missing'],
          [['MATLAB','3 of 36','33'],['Simulink','0 of 36','36'],['Total','3 of 72','69']],[45,27,28])
    text('Reduced-bit and combined cases, remaining sample rates and matching Simulink '
         'arrays are not evaluated here. No platform-parity result or 6 dB/bit finding '
         'is inferred from these controls. Microphone acquisition provenance remains '
         'the baseline owner\'s outstanding confirmation. Full listening coverage, '
         'technical review and final package sign-off remain open.')
    text('All 19 MATLAB test methods passed with no failed or incomplete cases in the '
         'saved session diary. This is numerical and integration-test evidence. The '
         'run summary\'s automated playback/listening flags remain false; the user\'s '
         'later audible/clear observation is recorded separately. The archive '
         'audio_partial_NOT_FINAL.zip contains the retained original, three processed '
         'WAVs, manifest and coverage CSV. Its exact file set and member bytes were '
         'rechecked for this report; the ZIP is not a full-project submission package.')
    head('Traceability',2)
    text('Run folder: Jesher/results/matlab_run_20261030_170138_859/. Numerical source: '
         'metrics.csv. WAV source: audio_package/manifest.csv. Metadata: run_summary.json. '
         'Exact arrays: evaluation.mat. Producer snapshot: '
         'input_snapshot/001_sampling_22050.mat. Test evidence: '
         'Jesher/results/matlab_session_20261030_170012.txt. Listening evidence: '
         'Jesher/listening/initial_observation.md.',caption_style)
    for label,case in zip(LABELS,IDS):
        text(label+': '+case+'. Export: processed/'+case+'.wav.',caption_style)
    text('Source checkout: be17af9179ecc91a2e8c2a50f606d82070afe503. The local Jesher '
         'implementation was uncommitted when this run was made; the checkout ID '
         'is not a commit identifier for the new evaluation code. Report figures '
         'were regenerated from the saved arrays with readable labels; original '
         'run figures and numeric results were not overwritten.',caption_style)
    head('Method references',2)
    text('MathWorks, resample: https://www.mathworks.com/help/signal/ref/resample.html. '
         'MathWorks, spectrogram: https://www.mathworks.com/help/signal/ref/spectrogram.html. '
         'Checked 31 October 2026. These references explain API behavior; the numeric '
         'results above come from the saved MATLAB run.',caption_style)

    doc = SimpleDocTemplate(str(PDF),pagesize=A4,rightMargin=44,leftMargin=44,
                            topMargin=43,bottomMargin=42,title='Jesher - Current MATLAB Results',
                            author='Jesher',subject='Three available MATLAB controls, verified metrics and captioned figures')
    def decoration(canvas,document):
        canvas.saveState()
        canvas.setStrokeColor(colors.HexColor('#C7D7E2')); canvas.setLineWidth(.5)
        canvas.line(44,30,A4[0]-44,30)
        canvas.setFont('Arial',8); canvas.setFillColor(colors.HexColor('#566678'))
        canvas.drawString(44,18,'CCEN 302 | Jesher | Current resources: 3 of 72 cases')
        canvas.drawRightString(A4[0]-44,18,str(document.page))
        canvas.restoreState()
    doc.build(story,onFirstPage=decoration,onLaterPages=decoration)
    markdown_text = '\n'.join(md)
    (REPORT/'metrics_playback_draft.md').write_text(markdown_text,encoding='utf-8')
    html_body = markdown.markdown(markdown_text,extensions=['tables'])
    html_page = '''<!doctype html><html lang="en"><meta charset="utf-8"><title>Jesher - Current MATLAB Results</title>
<style>body{font:16px/1.65 Arial,sans-serif;color:#1e293b;max-width:1050px;margin:40px auto;padding:0 24px}h1,h2,h3{color:#123b54}table{width:100%;border-collapse:collapse;margin:16px 0 26px}th,td{padding:10px;border:1px solid #d7e1e8;text-align:left}th{background:#e7eff4}img{width:100%;height:auto}p{overflow-wrap:anywhere}@media print{body{max-width:none;margin:0}h2{break-after:avoid}table,img{break-inside:avoid}}</style>'''+html_body+'</html>'
    (REPORT/'current_matlab_results.html').write_text(html_page,encoding='utf-8')
    inputs = [RUN/'metrics.csv',RUN/'audio_package/manifest.csv',RUN/'run_summary.json',
              RUN/'evaluation.mat',ROOT/'Jesher/results/matlab_session_20261030_170012.txt',
              ROOT/'Jesher/listening/initial_observation.md']
    evidence = {'report_prepared_date':'2026-10-31','verified_at_utc':datetime.now(timezone.utc).isoformat(),
                'matlab_run':RUN.name,'checks':checks,'matlab_tests_passed':19,
                'archive_exact_file_set_and_bytes_verified':True,'input_sha256':{str(p.relative_to(ROOT)):sha(p) for p in inputs},
                'output_sha256':{str(p.relative_to(ROOT)):sha(p) for p in [PDF,REPORT/'metrics_playback_draft.md',REPORT/'current_matlab_results.html',*sorted((REPORT/'figures').glob('figure_*.png'))]},
                'scope':'Three available MATLAB controls; not the full experiment',
                'listening':'User reports audible and clear; setup and other listeners unconfirmed'}
    (REPORT/'report_verification.json').write_text(json.dumps(evidence,indent=2)+'\n',encoding='utf-8')
    print('Verified all three processing/export metric rows, 19 tests and archive bytes.')
    print(PDF)


if __name__ == '__main__':
    main()
