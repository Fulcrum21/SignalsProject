# Abdulrahman - Sampling, Anti-Aliasing, and Alignment

[Team progress](../README.md#team-progress) | [Schedule](../README.md#schedule) | [Shared experiment contract](../README.md#shared-experiment-contract) | [Update instructions](../README.md#how-to-update-your-progress)

**Owner:** Abdulrahman | **Reviewer:** Yazan

**Last updated:** 24 October 2026

**Internal finish:** 4 November 2026, 8:00 PM Dubai time. All deadlines below are at 8:00 PM Dubai time.

**Role:** own the most demanding rate-conversion/filtering work and establish a defensible comparison time base with Jesher.

## Tasks

- [x] **AA-01 - Set the shared input/settings and define handoffs. Due 25 October; completed 24 October.** Specify the source, rate set, mono-column convention, filter modes, MATLAB/Simulink handoff format for Khaled, and timing metadata for Jesher. Document run instructions and dependencies.
  - Evidence: the shared settings and MAT-file contract below, [run instructions and source](../Matlab/Sampling_Abdulrahman.m), and [published prototype data](../Results/Abdulrahman/AA02/sampling_22050.mat). The user directed that this is the format to be used; a separate teammate-confirmation step is not required.
- [x] **AA-02 - Deliver one reduced-rate prototype. Due 26 October; completed 24 October.** Share filtered and unfiltered versions of one agreed case, with actual rate, sample count/duration, filter settings, and a readable spectrum. Document the unfiltered conversion method; verify it does not silently include the anti-aliasing treatment being compared.
  - Evidence: [verified MATLAB source](../Matlab/Sampling_Abdulrahman.m), [sample arrays and settings](../Results/Abdulrahman/AA02/sampling_22050.mat), [summary table](../Results/Abdulrahman/AA02/summary.csv), and [comparison spectrum](../Results/Abdulrahman/AA02/comparison.png). This completes the MATLAB prototype, not Simulink or the full alignment/aliasing experiments.
- [ ] **AA-03 - Finalize alignment and join the first complete case. Due 27 October.** With Jesher, document reconstruction to the common time base, known delay compensation, valid comparison interval/edges, and unequal-length handling. Test the policy with a known signal. Supply the first sampling case in MATLAB and Simulink for the full pipeline; ensure quantization and metrics use its actual rate.
- [ ] **AA-04 - Complete every sampling route in both platforms. Due 29 October.** Implement 22.05 kHz, 11.025 kHz, 8 kHz, and 4 kHz with and without anti-aliasing filtering. Handle non-integer conversions correctly; keep amplitudes consistent with the reference. Give Khaled the sampling outputs and metadata for all routes, and stay available for combination issues.
- [ ] **AA-05 - Produce sampling/aliasing evidence. Due 30 October.** For each lower rate at 16 effective bits, produce comparable original/filtered/unfiltered waveform, FFT, and spectrogram views. Demonstrate identifiable frequency folding with at least one existing known-frequency test signal and discuss what is observable in the real recording. Compare equivalent MATLAB/Simulink cases and document filter/method/axis differences.
- [ ] **AA-06 - Complete the combined-case handoff. Due 30 October.** Work with Khaled to cover every lower-rate/filter/bit-depth combination in both platforms, preserving IDs/timing metadata. Help Jesher resolve alignment or rate discrepancies. Document which cases and artifacts were accepted; do not call the whole matrix complete if any route is missing.
- [ ] **AA-07 - Write the sampling/aliasing report section. Due 31 October.** Include methods, filter choices, non-integer conversion, plots with units, observed folding/overlap, Nyquist interpretation, limitations, and MATLAB/Simulink comparison. Explain the reconstruction/alignment policy so quality results are reproducible.
- [ ] **AA-08 - Review Yazan's baseline. Due 2 November.** Check recording metadata/provenance, portable model input, FFT parity/scaling, dB and spectrogram units, and the full-record versus frame-FFT comparison. Record findings and evidence here; Yazan updates his own checklist. Address Yazan's review of your sampling work.
- [ ] **AA-09 - Close findings and rehearse. Due 3 November.** Resolve your review/integration findings and re-run affected cases. Rehearse aliasing/alignment explanations and demonstrate that you can explain another member's section.
- [ ] **AA-10 - Sign off sampling in the final package. Due 4 November, 6:00 PM Dubai time.** Check the final source/models, sample-rate/filter metadata, report figures, matching platform results, and demonstration. Confirm no essential sampling/alignment issue remains open.

## Handoffs

| When | Give / receive | Acceptance evidence |
| --- | --- | --- |
| 25 October | Receive Yazan's baseline; publish the sample/metadata interface for Khaled and Jesher | Same source, dimensions, and handoff fields documented |
| 26-27 October | Give the first filtered/unfiltered case and alignment policy | Jesher accepts the time basis; one complete case works |
| 29 October | Give all rate/filter outputs in both platforms to Khaled | Every route has actual rate, length, delay/filter metadata, and run instructions |
| 30 October | Help Khaled supply combined cases and Jesher evaluate them | No missing lower-rate combination; discrepancies logged |
| 31 October | Give Yazan the sampling section and figure references | Methods/results/discussion identify their cases and settings |

## Completion checks

Before checking implementation tasks, verify actual sample rate and duration; distinguish rate reduction from simply changing playback rate. Include both integer and non-integer conversions. Use the same baseline and filter settings across platforms, and identify the conditions under which aliasing is expected.

Keep all completed tasks checked with dated evidence. If a task is blocked, state the missing input/person and continue independent filter/model/theory work.

## AA-01 shared settings and handoff format

On 24 October, the user directed that the following format be used for the next stages. The input/settings, handoff fields, run instructions, and dependencies are documented here; AA-01 is complete. Reconstruction and the valid comparison interval remain technical work under AA-03.

| Item | Convention |
| --- | --- |
| Source | `Audios/SpeechMusic.wav`; mono, 44,100 Hz, 16-bit PCM, 882,005 samples. Yazan owns the separate microphone-provenance check. |
| Sampling-rate set | 22,050; 11,025; 8,000; 4,000 Hz, with the 44,100 Hz original retained as reference. Only 22,050 Hz is implemented in this prototype. |
| Modes | `none`: direct sample selection, without filtering; `lpf`: anti-aliasing filtering followed by rate reduction. |
| Data shape/type | One channel as an N-by-1 `double` array; preserve amplitude and do not normalize each case separately. |
| Current handoff | `Results/Abdulrahman/AA02/sampling_22050.mat`, containing the `prototype` structure described below, plus `summary.csv` and `comparison.png`. |
| Case identifiers | `speechmusic_fs22050_b16_none_matlab` and `speechmusic_fs22050_b16_lpf_matlab`. At this sampling-only stage, `b16` identifies the source/control; neither array is re-quantized or exported to a 16-bit WAV. `quantizationApplied=false` makes this explicit. Khaled owns subsequent quantization and final precision metadata. |
| Khaled receives | Both processed arrays, their actual rates, case IDs, sample counts/durations, and filter/timing metadata. Preserve this metadata when applying quantization. |
| Jesher receives | The original reference and both processed arrays, start/last sample times, actual rates, sample counts, and the filter-delay compensation flag. Common-grid reconstruction and the valid comparison-edge policy remain AA-03 decisions. |
| Future Simulink handoff | Supply equivalent samples and the same metadata fields/units, with a `simulink` platform/case label. The interface is defined; implementing and verifying the sampling model remains under AA-03 and AA-04. |

## AA-02 reproducible handoff and verified results

**Run requirements:** MATLAB and Signal Processing Toolbox (`resample`), plus the tracked source WAV. The successful verification used MATLAB R2026a. No Simulink license is needed to run this MATLAB prototype. Compatibility with earlier MATLAB releases has not been tested.

From the repository root in MATLAB, run:

```matlab
run(fullfile('Matlab', 'Sampling_Abdulrahman.m'));
```

The script locates its own input, creates three figures, and regenerates the three handoff files in `Results/Abdulrahman/AA02/`. Its saved comparison uses the same data as the two individual plots.

| Signal | Actual rate (Hz) | Sample count | Duration N/Fs (seconds) |
| --- | --- | --- | --- |
| Original | 44,100 | 882,005 | 20.000113379 |
| Without anti-aliasing filter | 22,050 | 441,003 | 20.000136054 |
| With anti-aliasing filter | 22,050 | 441,003 | 20.000136054 |

The small duration difference is sample-count rounding for an odd-length input, not a playback-speed change. Both output grids start at t=0, have sample interval 1/22,050 seconds, and have last sample time approximately 20.000090703 seconds. Duration N/Fs and last sample time (N-1)/Fs are different quantities.

**Unfiltered method:** `x(1:2:end)` retains samples 1, 3, 5, ... directly. The saved output was checked for exact equality to this indexing result; no filtering or independent amplitude normalization is performed in that branch.

**Filtered method:** `[yFiltered, filterCoefficients] = resample(x, 1, 2, 10, 5)`. The explicit settings match MATLAB's defaults: design parameter n=10 and Kaiser-window beta=5. The verified filter has 41 coefficients (order 40), saved as `prototype.filter.coefficients`. Its nominal cutoff is 11,025 Hz; it has a finite transition band rather than an ideal brick-wall response. The raw linear-phase group delay is 20 input samples, and `resample` compensates it internally. Do not shift the result by that delay a second time. See the [MathWorks resample documentation](https://www.mathworks.com/help/signal/ref/resample.html).

**Saved structure:** `prototype.original`, `prototype.unfiltered`, and `prototype.filtered` each contain `samples`, `Fs`, `sampleCount`, and `durationSeconds`. Each processed branch also contains `caseId`, `filterMode`, `firstSampleTimeSeconds`, and `lastSampleTimeSeconds`. `prototype.filter` holds the ratio, design settings, actual coefficients, order, nominal cutoff, raw group delay, and compensation flag. The root records source bit depth, MATLAB release, and that no quantization/normalization was applied.

Example receiver access, from the repository root:

```matlab
handoff = load(fullfile('Results', 'Abdulrahman', 'AA02', 'sampling_22050.mat'));
signal = handoff.prototype.unfiltered.samples;
signalFs = handoff.prototype.unfiltered.Fs;
```

**Verification performed:** fresh MATLAB execution from a different working folder; mono-column shape; output rates/counts and odd-length rounding; duration bounds; exact unfiltered indexing; equality of the explicit filtered call to `resample(x,1,2)`; saved MAT-file round trip; CSV counts/rates; and three generated figures. The saved comparison image was visually inspected before publication.

**What this evidence establishes:** a reproducible 22.05 kHz MATLAB sampling prototype and a concrete handoff. The closely overlapping linear spectra do not, by themselves, prove that aliasing is absent. Original/processed waveform and spectrogram comparisons, a clear known-tone aliasing demonstration, Simulink sampling, and the full alignment policy remain in AA-03 through AA-05.

## Progress log

| Date | Update / evidence | Next action or blocker |
| --- | --- | --- |
| 24 October | Task plan created. No sampling implementation is present in the inspected tracked files at ad8cc0d; unpublished work is not assessed. | AA-01 due 25 October; first component handoff due 26 October. |
| 24 October | AA-02 MATLAB prototype implemented and verified; saved arrays, settings, numeric summary, and spectrum evidence are linked above. Earlier task-plan entry is retained as history. | Use the documented MAT-file format for subsequent handoffs. |
| 24 October | AA-01 completed: source/settings, data shape, filter modes, timing fields, and run requirements documented. Separate format confirmation removed at the user's instruction; recipient approval is not claimed. | Next: AA-03 alignment and the first MATLAB/Simulink pipeline case. |

**Technical review findings:** pending under AA-08; add task ID, finding, evidence, owner, and resolution date here.
**Final sign-off:** pending; add date, source/result commit, reviewer, and any remaining limitations.
