"""Write a short course-results section from the actual completed demo run.
No Python is needed to run the MATLAB/Simulink demonstration itself.
"""
import csv
import hashlib
import json
import math
import re
import html
import sys
from pathlib import Path
import wave
import zipfile

ROOT=Path(__file__).resolve().parents[2]
DEMO=ROOT/'Jesher/Demo'
OUT=DEMO/'Results'

def read(name):
    with (OUT/name).open(encoding='utf-8',newline='') as stream:
        return list(csv.DictReader(stream))

def make_pdf(markdown_text):
    # Reporting only. The actual course scripts do not depend on Python.
    try:
        import reportlab
    except ImportError:
        sys.path.append(str(Path.home()/'.cache/codex-runtimes/codex-primary-runtime/dependencies/python/Lib/site-packages'))
    from reportlab.lib import colors
    from reportlab.lib.pagesizes import A4
    from reportlab.lib.styles import ParagraphStyle
    from reportlab.pdfbase import pdfmetrics
    from reportlab.pdfbase.ttfonts import TTFont
    from reportlab.platypus import SimpleDocTemplate, Paragraph, Spacer, Table, TableStyle, Image, KeepTogether
    pdfmetrics.registerFont(TTFont('DemoArial','C:/Windows/Fonts/arial.ttf'))
    pdfmetrics.registerFont(TTFont('DemoArialBold','C:/Windows/Fonts/arialbd.ttf'))
    pdfmetrics.registerFontFamily('DemoArial',normal='DemoArial',bold='DemoArialBold',italic='DemoArial',boldItalic='DemoArialBold')
    body=ParagraphStyle('body',fontName='DemoArial',fontSize=10,leading=14,spaceAfter=8)
    small=ParagraphStyle('small',parent=body,fontSize=8.5,leading=11,spaceAfter=6)
    head=ParagraphStyle('head',parent=body,fontName='DemoArialBold',fontSize=14,leading=18,spaceBefore=10,spaceAfter=9,textColor=colors.HexColor('#133E56'))
    title=ParagraphStyle('title',parent=head,fontSize=23,leading=27,spaceAfter=14)
    def inline(text):
        text=html.escape(text)
        text=re.sub(r'\*\*(.+?)\*\*',r'<b>\1</b>',text)
        return re.sub(r'`(.+?)`',r'<font name="Courier" size="8.2">\1</font>',text)
    width=A4[0]-84
    story=[]; lines=markdown_text.splitlines(); i=0
    while i<len(lines):
        line=lines[i].strip()
        if not line or line=='<!-- pagebreak -->': i+=1; continue
        if line.startswith('# '):
            story.append(Paragraph(inline(line[2:]),title)); i+=1; continue
        if line.startswith('## '):
            story.append(Paragraph(inline(line[3:]),head)); i+=1; continue
        if line.startswith('|'):
            data=[]
            while i<len(lines) and lines[i].strip().startswith('|'):
                cells=[s.strip() for s in lines[i].strip().strip('|').split('|')]
                if not all(re.fullmatch(r'[-: ]+',s) for s in cells):
                    data.append([Paragraph(inline(s),small) for s in cells])
                i+=1
            widths=[48,27,43,110,110,110] if len(data[0])==6 else [80,100,130,138]
            widths=[width*x/sum(widths) for x in widths]
            table=Table(data,colWidths=widths,repeatRows=1,hAlign='LEFT')
            table.setStyle(TableStyle([('BACKGROUND',(0,0),(-1,0),colors.HexColor('#E6EFF4')),
                ('ROWBACKGROUNDS',(0,1),(-1,-1),[colors.white,colors.HexColor('#F5F7F9')]),
                ('VALIGN',(0,0),(-1,-1),'TOP'),('TOPPADDING',(0,0),(-1,-1),5),
                ('BOTTOMPADDING',(0,0),(-1,-1),4),('LEFTPADDING',(0,0),(-1,-1),6)]))
            story.extend([table,Spacer(1,10)]); continue
        if line.startswith('!['):
            target=re.search(r'\]\((.+)\)',line).group(1)
            path=DEMO/target
            if path.exists():
                image=Image(str(path)); ratio=min(width/image.imageWidth,365/image.imageHeight)
                image.drawWidth=image.imageWidth*ratio; image.drawHeight=image.imageHeight*ratio
                group=[image,Spacer(1,6)]
                j=i+1
                while j<len(lines) and not lines[j].strip(): j+=1
                if j<len(lines) and lines[j].startswith('**Figure'):
                    group.append(Paragraph(inline(lines[j]),small)); i=j
                story.append(KeepTogether(group))
            i+=1; continue
        story.append(Paragraph(inline(line),body)); i+=1
    pdf=ROOT/'Jesher/report/output/pdf/Jesher_Complete_Demo_Results.pdf'
    pdf.parent.mkdir(parents=True,exist_ok=True)
    def footer(canvas,doc):
        canvas.saveState(); canvas.setFont('DemoArial',8); canvas.setFillColor(colors.HexColor('#526777'))
        canvas.drawString(42,20,'CCEN 302 | Jesher | Complete 72-case objective results | 31 October 2026')
        canvas.drawRightString(A4[0]-42,20,str(doc.page)); canvas.restoreState()
    SimpleDocTemplate(str(pdf),pagesize=A4,leftMargin=42,rightMargin=42,topMargin=40,bottomMargin=40,
        title='Jesher - Complete MATLAB and Simulink Results',author='Jesher').build(story,onFirstPage=footer,onLaterPages=footer)
    return pdf

def main():
    rows=read('metrics.csv'); pairs=read('platform_comparison.csv'); manifest=read('audio_manifest.csv')
    assert len(rows)==72 and len(pairs)==36 and len(manifest)==73
    assert len({r['CaseID'] for r in rows})==72
    expected={f'speechmusic_fs{rate}_b{bits:02d}_{mode}_{platform}'
              for platform in ['matlab','simulink'] for rate in [44100,22050,11025,8000,4000]
              for mode in (['native'] if rate==44100 else ['lpf','none']) for bits in [16,8,4,2]}
    assert {r['CaseID'] for r in rows}==expected
    for r in rows:
        path=Path(r['WavFile'])
        with wave.open(str(path),'rb') as audio:
            assert audio.getframerate()==int(r['RateHz'])
            assert audio.getnframes()==int(r['Samples'])
            assert audio.getnchannels()==1 and audio.getsampwidth()==2
        assert path.stat().st_size==int(r['WavBytes'])
        assert path.stat().st_size==44+2*int(r['Samples'])
        assert float(r['WavClippedSamples'])==0
        assert math.isclose(float(r['DurationSeconds']),int(r['Samples'])/int(r['RateHz']),abs_tol=1e-12)
        nmse=float(r['NMSE']); snr=float(r['SNRdB'])
        if nmse>0:
            assert abs(snr+10*math.log10(nmse))<1e-10
        else:
            assert nmse==0 and snr==math.inf
    maximum=max(float(p['MaxSampleDifference']) for p in pairs)
    assert maximum<1e-10
    for p in pairs:
        assert float(p['MatlabNMSE'])==float(p['SimulinkNMSE'])
        assert float(p['MatlabSNRdB'])==float(p['SimulinkSNRdB'])
    archive=OUT/'all_audio.zip'
    expected_members={Path(r['WavFile']).name for r in manifest}|{'audio_manifest.csv'}
    with zipfile.ZipFile(archive) as z:
        assert {n for n in z.namelist() if not n.endswith('/')}==expected_members
        for name in expected_members:
            assert z.read(name)==(OUT/name).read_bytes()
    assert (OUT/'original.wav').read_bytes()==(ROOT/'Audios/SpeechMusic.wav').read_bytes()
    def f(value):
        value=float(value)
        return '+Inf' if value==math.inf else f'{value:.6g}'
    text=[
        '# Completed MATLAB and Simulink results',
        '',
        'CCEN 302 | Jesher | 31 October 2026',
        '',
        'This is the current complete objective-results section. The earlier three-control '
        'report is retained as history. All 36 conditions were generated and run independently '
        'in MATLAB and through the saved Simulink model, giving 72 actual result rows. '
        'No missing teammate output arrays were copied or relabeled as Simulink results.',
        '',
        '## Method',
        '',
        'The source is `Audios/SpeechMusic.wav`: mono, 44,100 Hz, 16-bit PCM, 882,005 '
        'samples (20.000113379 s). The rate set is 44,100, 22,050, 11,025, 8,000 and '
        '4,000 Hz, with effective bits 16, 8, 4 and 2. Native-rate cases have one route; '
        'each lower rate has filtered and unfiltered routes. Both platforms use the same settings.',
        '',
        'The filtered route uses a Kaiser-window FIR with n=10 and beta=5 and rational '
        'conversion p/q. The unfiltered route takes the original sample nearest each '
        'output time, with no low-pass filter. This is exact integer sample selection '
        'at 22,050/11,025 Hz and a documented nearest-source-time approximation at '
        '8,000/4,000 Hz. No independent amplitude normalization is used.',
        '',
        'The uniform signed quantizer uses step Delta=2/2^B, rounds to the nearest '
        'integer level, saturates its index to [-2^(B-1), 2^(B-1)-1], and multiplies '
        'by Delta. The 16-bit cases bypass further quantization as source/control cases. '
        'The visible Simulink implementation uses actual FIR Rate Conversion, Selector, '
        'Gain, Rounding Function and Saturation blocks.',
        '',
        'Every processed array is exported at its actual output rate in a 16-bit PCM '
        'WAV. PCM conversion is explicitly nearest-integer rounding. The WAV is read '
        'back and reconstructed onto the original 44,100 Hz grid before subtracting. '
        'Known FIR/phase delay is compensated. The full original interval is retained: '
        '882,005 samples, t=0 to 20.000090702948 s. Only deterministic end-grid rounding '
        'is discarded; there is no lag optimization, gain fitting or edge trimming.',
        '',
        '`NMSE = sum((x-y).^2)/sum(x.^2)`; '
        '`SNR_dB = 10*log10(sum(x.^2)/sum((x-y).^2))`. The main table scores the '
        '**re-imported WAV**, while the CSV also records processing-array scores. '
        'Simulink displays calculate those processing-array scores inside the model. '
        'Positive-energy zero error gives NMSE=0/SNR=+Inf; silent-reference special '
        'cases are handled explicitly in `quality_metrics.m`.',
        '',
        '## Full condition table',
        '',
        '**Table 1.** Aligned quality scores of all 36 conditions on each platform, '
        'measured after WAV export/re-import. The two platforms have identical exported '
        'WAV scores for all conditions. Full precision is retained in `Results/metrics.csv`.',
        '',
        '| Rate (Hz) | Bits | Filter | MATLAB NMSE | MATLAB SNR (dB) | Simulink SNR (dB) |',
        '| --- | --- | --- | --- | --- | --- |',
    ]
    for p in pairs:
        text.append('| '+' | '.join([p['RateHz'],p['Bits'],p['Filter'],f(p['MatlabNMSE']),
                                      f(p['MatlabSNRdB']),f(p['SimulinkSNRdB'])])+' |')
    text += [
        '',
        f'Maximum MATLAB/Simulink processing-sample difference across all pairs: '
        f'**{maximum:.12g}** (tolerance 1e-10). Numerical accumulation differences '
        'were removed by the PCM conversion in these tested exports; this is a measured '
        'result for the present implementation and source, not universal platform equivalence.',
        '',
        '## Interpretation',
        '',
        'At the native rate, reducing effective bits increases error and reduces SNR. '
        'For example, native 8-bit and 2-bit cases have SNRs of 33.3635 and 1.3266 dB. '
        'Filtering before rate reduction generally improves the high-precision sampling '
        'controls: at 4,000 Hz and 16-bit control precision, filtered/unfiltered SNRs are '
        '9.1154/6.3673 dB. Low-bit quantization can dominate the total error, so the '
        'effect of filtering is smaller and need not be monotonic in every low-bit case. '
        'The approximate 6 dB/bit rule assumes a suitable ideal quantization-noise model; '
        'it is not imposed on this speech/music recording or on saturated low-bit levels.',
        '',
        '## Representative figures',
        '',
        '![Simulink model](Results/model_overview.png)',
        '',
        '**Figure 1.** Saved `Audio_Demo.slx` processing diagram. Sampling, uniform '
        'quantization and reconstruction are explicit subsystems. The reference and '
        'reconstructed processing arrays feed Simulink energy calculations and NMSE/SNR '
        'displays. One frame is the complete recording; model stop time 0 evaluates '
        'that frame once and is not the WAV duration. MATLAB then writes and evaluates the WAV.',
        '',
        '![Combined 22,050 Hz 8-bit filtered case](Results/speechmusic_fs22050_b08_lpf_matlab_comparison.png)',
        '',
        '**Figure 2.** Combined 22,050 Hz, 8-bit filtered case: original (left) and '
        're-imported WAV reconstructed to the original grid (right). Rows show waveform, '
        'full-record single-sided FFT magnitude and one-sided PSD spectrogram. The '
        'envelope and main low-frequency structure remain recognizable while higher '
        'frequencies are attenuated. NMSE=0.00125267620062; SNR=29.02161174 dB.',
        '',
        '![Combined 4,000 Hz 2-bit unfiltered case](Results/speechmusic_fs4000_b02_none_matlab_comparison.png)',
        '',
        '**Figure 3.** Combined 4,000 Hz, 2-bit unfiltered case with the same panel '
        'ordering as Figure 2. The low effective precision coarsens the waveform and '
        'the retained bandwidth is greatly reduced. Reconstruction can suppress images '
        'but cannot undo aliasing that occurred during unfiltered sampling. '
        'NMSE=0.840091506062; SNR=0.75673406 dB. Audible descriptors require actual listening.',
        '',
        '![Quantization error](Results/speechmusic_fs44100_b02_native_matlab_quantization.png)',
        '',
        '**Figure 4.** Native-rate 2-bit quantization error (sampling output minus '
        'quantized output) and its sample histogram. Low-bit saturation can produce '
        'errors larger than half a quantizer step; a uniform-noise distribution is '
        'not assumed. This plot isolates quantization error at the same time base.',
        '',
        'The waveform/FFT display retains extrema in dense display bins for drawing '
        'speed; the full signal is used in every FFT and metric. Spectrogram settings '
        'for this source are periodic Hann 1,024 samples, 768 overlap, 2,048 DFT points, '
        '44,100 Hz analysis rate, and PSD color limits -160 to 0 dB. FFT amplitudes '
        'are divided by the full record length, paired positive-frequency bins are '
        'doubled, and a -160 dB display floor is used. These digital dB values are '
        'not calibrated sound-pressure levels.',
        '',
        '## Audio and storage',
        '',
        'All 72 case WAVs passed actual rate, mono channel count, 16-bit container, '
        'sample-count and file-size checks. No export clipping occurred. There are '
        '73 audio files in `Results/all_audio.zip`: the unchanged original plus '
        '72 platform-labeled outputs. The accompanying 73-row audio manifest and '
        'every ZIP member were checked against the files byte for byte.',
        '',
        '**Table 2.** Actual WAV sizes by rate (the four effective bit depths use the '
        'same 16-bit carrier). Ideal packed payload is `ceil(samples*effective_bits/8)` '
        'bytes for mono audio; it is distinct from these measured container sizes.',
        '',
        '| Rate (Hz) | Samples | Duration (s) | Actual WAV bytes |',
        '| --- | --- | --- | --- |',
    ]
    for rate in [44100,22050,11025,8000,4000]:
        r=next(r for r in rows if r['Platform']=='matlab' and int(r['RateHz'])==rate)
        text.append(f"| {rate} | {r['Samples']} | {float(r['DurationSeconds']):.9f} | {r['WavBytes']} |")
    text += [
        '',
        'Each current WAV has 44 bytes beyond its two-byte-per-mono-sample PCM payload. '
        'Changing effective bits alone does not shrink these WAVs. Rate reduction '
        'changes the actual sample payload. Sample-count rounding accounts for the '
        'tiny differences in N/Fs durations; changing a WAV header alone is not rate conversion.',
        '',
        '## Listening and remaining human work',
        '',
        'Jesher previously reported the original and the two earlier 22,050 Hz '
        'sampling controls as audible and clear. That observation is retained in '
        '`../listening/initial_observation.md`. It does not establish listening to '
        'the new 72 exports, especially the reduced-bit/combined cases. No new '
        'subjective observations, four-person comparison, speaker routing/speed '
        'confirmation, reviewer acceptance or rehearsal are invented here.',
        '',
        'Numerical implementation, the full matrix, export/ZIP generation, plots and '
        'the live-demo entry points are complete with the available resources. '
        'The team still needs to listen to the new outputs, collect each person\'s '
        'notes with a fixed setup, confirm microphone provenance, review the chosen '
        'conventions and rehearse the live presentation. This self-contained demo '
        'was implemented here; it is not claimed as independently produced or '
        'accepted by another teammate.',
    ]
    tone=OUT/'Aliasing/tone_check.csv'
    if tone.exists():
        with tone.open() as stream: t=next(csv.DictReader(stream))
        text += ['', '## Known-tone alias check','',
                 'The optional `DEMONSTRATE_ALIASING.m` uses the existing 10 kHz sine '
                 'recording and an 8 kHz output rate. The expected fold is '
                 '`abs(10000-8000)=2000 Hz`. The measured dominant unfiltered output '
                 f"frequency was **{float(t['measuredPeak']):.3f} Hz**. The peak check "
                 'omits 0.1 s at each edge only for tone-frequency inspection; all '
                 'NMSE/SNR calculations still retain their full comparison intervals.']
    markdown_text='\n'.join(text)+'\n'
    (DEMO/'RESULTS.md').write_text(markdown_text,encoding='utf-8')
    pdf=make_pdf(markdown_text)
    proof={'completed_cases':72,'platform_pairs':36,'manifest_audio_rows':73,
           'all_wav_headers_and_bytes_checked':True,'all_archive_members_byte_verified':True,
           'maximum_platform_sample_difference':maximum,'wav_scores_equal_for_all_pairs':True,
           'export_clipped_samples':0,'source_sha256':hashlib.sha256((OUT/'original.wav').read_bytes()).hexdigest(),
           'listening':'New outputs await actual human listening; previous three-case observation retained separately.'}
    (OUT/'completion_summary.json').write_text(json.dumps(proof,indent=2)+'\n',encoding='utf-8')
    print('Checked 72 actual cases, 36 matching pairs, 73 WAV headers and complete ZIP member bytes.')
    print(pdf)

if __name__=='__main__': main()
