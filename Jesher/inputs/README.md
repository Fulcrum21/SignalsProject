# Processed-array handoff

Place MAT files here containing a nonempty struct vector named `cases`.
Files are ignored by Git by default so unreviewed/large signal arrays are not
published accidentally. Pass explicit paths using `HandoffFiles` if preferred.
The evaluator reads them; it never runs the processing owner or fabricates cases.

Every case needs the following fields. Unknown extra fields can stay in the
producer's original MAT artifact; retain its filename in `provenance`.

| Field | Required value or meaning |
| --- | --- |
| `caseId` | `speechmusic_fs22050_b08_lpf_matlab` style; must match the contract |
| `platform` | Lowercase `matlab` or `simulink`, identifying actual signal origin |
| `sourceFile` | `Audios/SpeechMusic.wav`; same unchanged source samples |
| `samples` | Exact finite real N-by-1 double array after sampling then quantization |
| `Fs` | Actual rate, not a relabeled playback rate |
| `effectiveBits` | 16, 8, 4, or 2, independently of the WAV carrier |
| `filterMode` | `native` at 44,100 Hz; `lpf` or `none` below it |
| `firstSampleTimeSeconds` | 0 for the current full-record comparison |
| `delayCompensated` | Scalar logical true only after actual documented compensation |
| `processingStage` | E.g. `combined_quantized`, `sampling_only_control`, `native_reference` |
| `quantizationApplied` | Scalar logical; reduced-bit cases must be true |
| `normalizationApplied` | Scalar logical false; preserve original amplitude |
| `quantizerDescription` | Fixed range, levels/endpoints, rounding, clipping; explain a control bypass |
| `samplingDescription` | Exact rate method, filter design/coefficient artifact, delay handling |
| `provenance` | Source result artifact, actual platform run/release, and source/result commit or run ID |
| `alignmentPolicy` | `aa03_full_record_v1` for the documented native/22,050 Hz route |

The first sample represents t=0. Expected processed count is
`ceil(numel(original)*Fs/44100)`. Surplus Simulink frames and known delay must be
removed by the processing owner before handoff. The evaluator rejects missing
samples and extra frames. It reconstructs to 44,100 Hz using
`resample(samples,p,q,10,5)` and keeps the original recording interval. It
discards only rational-grid endpoint rounding, retains edge effects, and applies
no lag optimization, gain fitting, or independent normalization.

For 11,025, 8,000 and 4,000 Hz, supply a documented, validated alignment policy
with the timing handoff. The evaluator implements `full_record_resample_v1` as
the explicit generalization to those rates, but naming it does not establish
owner approval or validation. Record the supporting evidence in `provenance`.
Do not silently select this policy for a route with different timing.

For a reduced-bit signal, `numel(unique(samples))` must not exceed `2^effectiveBits`.
This check does not prove correct uniform level mapping; Khaled must still supply
the actual convention and boundary tests. The native 16-bit control must be
exactly the unchanged original. WAV export rejects samples beyond the PCM16
range; resolve any overshoot with the processing owner rather than normalizing.

## Example after a real producer run

These variables must come from actual processing and its documented metadata;
the example is not a signal generator or evidence that a case exists.

```matlab
c = struct;
c.caseId = 'speechmusic_fs22050_b08_lpf_matlab';
c.platform = 'matlab';
c.sourceFile = 'Audios/SpeechMusic.wav';
c.samples = quantizedSamples;  % exact mono column from Khaled
c.Fs = 22050;
c.effectiveBits = 8;
c.filterMode = 'lpf';
c.firstSampleTimeSeconds = 0;
c.delayCompensated = true;     % verified before quantization
c.processingStage = 'combined_quantized';
c.quantizationApplied = true;
c.normalizationApplied = false;
c.quantizerDescription = actualQuantizerSettings;
c.samplingDescription = actualSamplingAndFilterSettings;
c.provenance = actualSourceArtifactAndRunEvidence;
c.alignmentPolicy = 'aa03_full_record_v1';
cases = c;
save(fullfile('Jesher','inputs','khaled_cases.mat'),'cases','-v7');
```

Add each distinct case to the same struct vector. Do not save a second copy of
the same ID in another input file. A supplied case replaces the matching built-in
fallback source/control. Duplicate IDs among supplied handoffs are an error.

## Simulink prototype

Follow the run instructions in `team/Abdulrahman.md`. `Compare_Sampling.m` creates
`simNoFilterAligned` and `simFilteredAligned`, already delay-compensated. Save
those arrays with `platform='simulink'` and matching `_simulink` IDs. Preserve
their 22,050 Hz rate; reconstruction for metrics happens later. At b16 these are
sampling controls, so set `processingStage='sampling_only_control'` and
`quantizationApplied=false` with an explicit control description. Do not label
MATLAB arrays as Simulink results or compensate the filtered delay twice.
