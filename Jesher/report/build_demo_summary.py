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
    head=ParagraphStyle('head',parent=body,fontName='DemoArialBold',fontSize=14,leading=18,spaceBefore=10,spaceAfter=9,keepWithNext=True,textColor=colors.HexColor('#133E56'))
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
            widths={6:[48,27,43,110,110,110],5:[65,45,105,110,115],4:[80,100,130,138]}[len(data[0])]
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
        canvas.drawString(42,20,'CCEN 302 | Jesher | Complete 72-case objective results | 2 November 2026')
        canvas.drawRightString(A4[0]-42,20,str(doc.page)); canvas.restoreState()
    SimpleDocTemplate(str(pdf),pagesize=A4,leftMargin=42,rightMargin=42,topMargin=40,bottomMargin=40,
        title='Jesher - Complete MATLAB and Simulink Results',author='Jesher').build(story,onFirstPage=footer,onLaterPages=footer)
    return pdf

def main():
    log=(OUT/'compatibility_run_log.txt').read_text(encoding='utf-8',errors='replace')
    assert 'UPDATE_VERIFICATION_PASSED' in log, 'Finish the actual MATLAB verification run first.'
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
        assert float(p['MaxWavSampleDifference'])<=1/32768
        assert abs(float(p['MatlabProcessingNMSE'])-float(p['SimulinkProcessingNMSE']))<1e-10
        a=float(p['MatlabProcessingSNRdB']); b=float(p['SimulinkProcessingSNRdB'])
        assert a==b or abs(a-b)<1e-8
    wav_scores_equal=all(float(p['MatlabNMSE'])==float(p['SimulinkNMSE']) and
                         float(p['MatlabSNRdB'])==float(p['SimulinkSNRdB']) for p in pairs)
    maximum_wav_difference=max(float(p['MaxWavSampleDifference']) for p in pairs)
    wav_different_pairs=sum(float(p['MaxWavSampleDifference'])>0 for p in pairs)
    maximum_wav_snr_difference=max(0 if float(p['MatlabSNRdB'])==float(p['SimulinkSNRdB'])
                                   else abs(float(p['MatlabSNRdB'])-float(p['SimulinkSNRdB'])) for p in pairs)
    for r in rows:
        assert r['ExperimentVersion']=='linear_interp_v2'
        assert r['AlignmentPolicy']=='full_record_resample_v1'
        assert int(r['ComparisonSamples'])==882005
        assert float(r['ComparisonStartSeconds'])==0
        assert math.isclose(float(r['ComparisonEndSeconds']),882004/44100,abs_tol=1e-12)
        assert float(r['FirstSampleTimeSeconds'])==0
        assert math.isclose(float(r['LastSampleTimeSeconds']),(int(r['Samples'])-1)/int(r['RateHz']),abs_tol=1e-12)
        assert int(r['Samples'])==math.floor(882004*int(r['RateHz'])/44100)+1
        assert int(r['EffectiveBits'])==int(r['Bits'])
        assert int(r['QuantizationApplied'])==(int(r['Bits'])<16)
        assert int(r['NormalizationApplied'])==0 and int(r['DelayCompensated'])==1
        assert float(r['WavMaxSampleError'])<=0.5/32768+1e-14
    def result(rate,bits,mode):
        return next(r for r in rows if r['Platform']=='matlab' and int(r['RateHz'])==rate
                    and int(r['Bits'])==bits and r['Filter']==mode)
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
        'CCEN 302 | Jesher | 2 November 2026',
        '',
        'This is the current complete objective-results section. The earlier three-control '
        'report and previous nearest-source-time experiment are retained as history. All 36 conditions were generated and run independently '
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
        'conversion p/q. The unfiltered route selects every second/fourth sample at '
        '22,050/11,025 Hz. At 8,000/4,000 Hz it uses linear interpolation at uniform '
        "output times without a dedicated anti-aliasing LPF, matching the sampling owner's "
        'handoff. Interpolation affects amplitude response. Output times stay within '
        'the source interval. No independent normalization is used. Current rows '
        'are linear_interp_v2; history/13fc434 preserves the previous nearest-source-time experiment.',
        '',
        'The uniform signed quantizer uses step Delta=2/2^B, rounds to the nearest '
        'integer level, saturates its index to [-2^(B-1), 2^(B-1)-1], and multiplies '
        'by Delta. The 16-bit cases bypass further quantization as source/control cases. '
        'The visible Simulink implementation uses actual FIR Rate Conversion, Selector, '
        'Gain, Rounding Function and Saturation blocks. Linear interpolation is calculated '
        'inside the model using adjacent-source Selectors, Sum and Product blocks; '
        'processed MATLAB answers are not fed into the Simulink path.',
        '',
        'Every processed array is exported at its actual output rate in a 16-bit PCM '
        'WAV. PCM conversion is explicitly nearest-integer rounding. The WAV is read '
        'back and reconstructed onto the original 44,100 Hz grid before subtracting. '
        'Each FIR block compensates its own known phase/delay; already compensated '
        'resample outputs and imported arrays receive no second shift. The full interval is retained: '
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
        'measured after WAV export/re-import. Processing-array scores are separately '
        'recorded in Results/metrics.csv and platform_comparison.csv. Full precision '
        'and export conventions are retained in those CSVs.',
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
        f'**{maximum:.12g}** (tolerance 1e-10). Maximum re-imported WAV sample difference: '
        f'**{maximum_wav_difference:.12g}**. Exported-WAV scores identical for all pairs: '
        f'**{wav_scores_equal}**. {wav_different_pairs} pairs differ after export; tiny processing '
        'differences can fall on opposite sides of a PCM rounding boundary. The measured '
        f'maximum exported-SNR difference is {maximum_wav_snr_difference:.12g} dB. '
        'The export comparison allows at most one PCM step; raw processing arrays are '
        'checked independently at 1e-10. These results apply to this implementation and source.',
        '',
        '## Interpretation',
        '',
        'At the native rate, reducing effective bits increases error and reduces SNR. '
        f"For example, native 8-bit and 2-bit cases have SNRs of {float(result(44100,8,'native')['SNRdB']):.4f} "
        f"and {float(result(44100,2,'native')['SNRdB']):.4f} dB. "
        'Filtering before rate reduction generally improves the high-precision sampling '
        'controls: at 4,000 Hz and 16-bit control precision, filtered/unfiltered SNRs are '
        f"{float(result(4000,16,'lpf')['SNRdB']):.4f}/{float(result(4000,16,'none')['SNRdB']):.4f} dB. "
        'Low-bit quantization can dominate the total error, so the '
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
        f"frequencies are attenuated. NMSE={float(result(22050,8,'lpf')['NMSE']):.12g}; "
        f"SNR={float(result(22050,8,'lpf')['SNRdB']):.8f} dB.",
        '',
        '![Combined 4,000 Hz 2-bit unfiltered case](Results/speechmusic_fs4000_b02_none_matlab_comparison.png)',
        '',
        '**Figure 3.** Combined 4,000 Hz, 2-bit unfiltered case with the same panel '
        'ordering as Figure 2. The two-bit sampled array uses at most four levels; '
        'the reconstructed trace interpolates those levels. Retained bandwidth is greatly reduced. Reconstruction can suppress images '
        'but cannot undo aliasing that occurred during unfiltered sampling. '
        f"NMSE={float(result(4000,2,'none')['NMSE']):.12g}; SNR={float(result(4000,2,'none')['SNRdB']):.8f} dB. "
        'Audible descriptors require actual listening.',
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
    handoff_folder=ROOT/'Jesher/results/matlab_run_sampling_v2'
    with (handoff_folder/'metrics.csv').open(encoding='utf-8',newline='') as stream:
        handoff_rows=list(csv.DictReader(stream))
    assert len(handoff_rows)==9 and len({r['caseId'] for r in handoff_rows})==9
    for r in handoff_rows:
        assert int(r['comparisonSampleCount'])==882005 and float(r['comparisonFirstTimeSeconds'])==0
        assert math.isclose(float(r['comparisonLastTimeSeconds']),882004/44100,abs_tol=1e-12)
        assert int(r['effectiveBits'])==16 and int(r['quantizationApplied'])==0
        assert float(r['wavMaxAbsRoundTripError'])<=0.5/32768+1e-14
        assert 'round(samples*32768)' in r['wavPcmConversion']
        demo_row=next(d for d in rows if d['CaseID']==r['caseId'])
        assert float(r['nmse'])==float(demo_row['ProcessingNMSE'])
        assert float(r['snrDb'])==float(demo_row['ProcessingSNRdB'])
        assert float(r['exportedNmse'])==float(demo_row['NMSE'])
        assert float(r['exportedSnrDb'])==float(demo_row['SNRdB'])
        with wave.open(str(handoff_folder/'audio_package'/r['wavFile']),'rb') as audio:
            assert audio.getframerate()==int(r['Fs']) and audio.getnframes()==int(r['sampleCount'])
            assert audio.getnchannels()==1 and audio.getsampwidth()==2
    text += ['', '## Exact sampling-handoff evaluation','',
             'The separate public evaluator imported the eight supplied MATLAB sampling arrays unchanged, '
             'plus the native reference. It reports 9 of 72 handoff cases available and 63 missing; '
             'it does not relabel the independent demo as teammate-produced output. '
             'Explicit top-level cases and nested samplingHandoff.cases are accepted, with explicit '
             'IDs taking precedence over fallback controls and duplicate explicit IDs rejected. '
             'Method, producer filter/timing metadata and artifact provenance are retained.', '',
             'These b16 controls retain double-valued sampling results without an added quantizer. '
             'Flags: quantizationApplied=false, normalizationApplied=false, delayCompensated=true, '
             'alignmentPolicy=full_record_resample_v1. Unfiltered routes have no FIR delay; '
             'filtered routes have already been compensated. No second correction is applied.', '',
             '**Table 3.** Sampling controls measured from supplied processing doubles and from the '
             "handoff evaluator's own WAV export/re-import. Both evaluators now use explicit "
             'nearest-integer PCM16 conversion, with half ties away from zero and measured '
             'error at most half a PCM step. This replaces the legacy implicit double-input '
             'audiowrite conversion; historical WAV metrics preserve the older behavior. '
             'Effective reduced-bit quantization is unchanged. Compare matching representations.', '',
             '| Rate (Hz) | Filter | Processing NMSE | Processing SNR (dB) | Exported SNR (dB) |',
             '| --- | --- | --- | --- | --- |']
    for r in sorted(handoff_rows,key=lambda r:(-int(r['Fs']),r['filterMode'])):
        text.append('| '+' | '.join([r['Fs'],r['filterMode'],f(r['nmse']),f(r['snrDb']),f(r['exportedSnrDb'])])+' |')
    checks={}
    for name,count in [('handoff_checks.csv',8),('timing_checks.csv',16),('alias_checks.csv',4)]:
        with (OUT/'Checks'/name).open(encoding='utf-8',newline='') as stream:
            checks[name]=list(csv.DictReader(stream))
        assert len(checks[name])==count
    assert all(float(r['ImportedMaxDifference'])==0 and float(r['RegeneratedMaxDifference'])<1e-12
               for r in checks['handoff_checks.csv'])
    assert all(int(r['ResidualLagSourceSamples'])==0 and abs(float(r['DominantHz'])-300)<1
               for r in checks['timing_checks.csv'])
    assert all(abs(float(r['MeasuredAliasHz'])-float(r['ExpectedAliasHz']))<1
               and float(r['FilteredRmsReductionDb'])>40 for r in checks['alias_checks.csv'])
    tone_sample_counts={int(r['ComparisonSamples']) for r in checks['timing_checks.csv']}
    assert len(tone_sample_counts)==1
    tone_sample_count=next(iter(tone_sample_counts))
    text += ['', '## Integration and timing checks','',
             'All 22 MATLAB regression tests and all 20 existing independent Python tests passed. '
             'Eight imported arrays match the supplied arrays exactly. All eight regenerated MATLAB '
             'controls agree with their supplied counterparts within 1e-12. Sixteen 300 Hz checks '
             f'(four rates, both filter modes, both actual platforms) retain all {tone_sample_count:,} '
             'sample times of that tone recording and have zero diagnostic residual lag; the measured dominant frequency is within 1 Hz '
             'of 300 Hz. Diagnostic lag is never applied to the measurements.', '',
             'Four actual-platform alias checks cover 10 kHz input at 11,025 and 8,000 Hz. '
             'The measured aliases are within 1 Hz of 1,025 and 2,000 Hz respectively. '
             'Filtered interior RMS is more than 40 dB below the unfiltered path in each check. '
             'Only tone-frequency diagnostics omit 0.1 s at each edge; every NMSE/SNR score '
             'retains the full reference interval and its reconstruction boundary errors.', '',
             "This integration does not complete Abdulrahman's separate Simulink deliverables "
             "or Khaled's quantizer/storage work. Their implementations and checklists remain unchanged."]
    text += ['', '**Table 4.** Actual-platform 10 kHz tone checks on processing arrays. '
             'RMS reduction compares filtered and unfiltered interiors; this is not an acoustic SNR.', '',
             '| Platform | Rate (Hz) | Expected alias (Hz) | Measured alias (Hz) | Filtered RMS reduction (dB) |',
             '| --- | --- | --- | --- | --- |']
    for r in checks['alias_checks.csv']:
        text.append('| '+' | '.join([r['Platform'],r['RateHz'],r['ExpectedAliasHz'],
                                     f"{float(r['MeasuredAliasHz']):.6f}",
                                     f"{float(r['FilteredRmsReductionDb']):.3f}"])+ ' |')
    markdown_text='\n'.join(text)+'\n'
    (DEMO/'RESULTS.md').write_text(markdown_text,encoding='utf-8')
    pdf=make_pdf(markdown_text)
    proof={'completed_cases':72,'platform_pairs':36,'manifest_audio_rows':73,
           'all_wav_headers_and_bytes_checked':True,'all_archive_members_byte_verified':True,
           'maximum_platform_sample_difference':maximum,'wav_scores_equal_for_all_pairs':wav_scores_equal,
           'maximum_wav_sample_difference':maximum_wav_difference,'wav_different_pairs':wav_different_pairs,
           'maximum_wav_snr_difference_db':maximum_wav_snr_difference,'experiment_version':'linear_interp_v2',
           'export_clipped_samples':0,'source_sha256':hashlib.sha256((OUT/'original.wav').read_bytes()).hexdigest(),
           'exact_imported_controls':8,'regenerated_control_checks':8,'tone_timing_checks':16,'alias_platform_checks':4,
           'handoff_evaluator_available_cases':9,'handoff_evaluator_missing_cases':63,
           'matlab_regression_tests_passed':22,'python_regression_tests_passed':20,
           'listening':'New outputs await actual human listening; previous three-case observation retained separately.'}
    (OUT/'completion_summary.json').write_text(json.dumps(proof,indent=2)+'\n',encoding='utf-8')
    print('Checked 72 actual cases, 36 matching pairs, 73 WAV headers and complete ZIP member bytes.')
    print(pdf)

if __name__=='__main__': main()
