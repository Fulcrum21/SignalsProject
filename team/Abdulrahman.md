# Abdulrahman - Sampling, Anti-Aliasing, and Alignment

[Team progress](../README.md#team-progress) | [Schedule](../README.md#schedule) | [Shared experiment contract](../README.md#shared-experiment-contract) | [Update instructions](../README.md#how-to-update-your-progress)

**Owner:** Abdulrahman | **Reviewer:** Yazan

**Last updated:** 8 November 2026

**Internal finish:** 4 November 2026, 8:00 PM Dubai time. All deadlines below are at 8:00 PM Dubai time.

**Role:** own the most demanding rate-conversion/filtering work and establish a defensible comparison time base with Jesher.

## Tasks

- [x] **AA-01 - Set the shared input/settings and define handoffs. Due 25 October; completed 24 October.** Specify the source, rate set, mono-column convention, filter modes, MATLAB/Simulink handoff format for Khaled, and timing metadata for Jesher. Document run instructions and dependencies.
  - Evidence: the shared settings and MAT-file contract below, [run instructions and source](../Matlab/Sampling_Abdulrahman.m), and [published prototype data](../Results/Abdulrahman/AA02/sampling_22050.mat). The user directed that this is the format to be used; a separate teammate-confirmation step is not required.
- [x] **AA-02 - Deliver one reduced-rate prototype. Due 26 October; completed 24 October.** Share filtered and unfiltered versions of one agreed case, with actual rate, sample count/duration, filter settings, and a readable spectrum. Document the unfiltered conversion method; verify it does not silently include the anti-aliasing treatment being compared.
  - Evidence: [verified MATLAB source](../Matlab/Sampling_Abdulrahman.m), [sample arrays and settings](../Results/Abdulrahman/AA02/sampling_22050.mat), [summary table](../Results/Abdulrahman/AA02/summary.csv), [comparison spectrum](../Results/Abdulrahman/AA02/comparison.png), and the WAV copies linked below. This completes the MATLAB prototype, not Simulink or the full alignment/aliasing experiments.
- [x] **AA-03 - Finalize alignment and join the first complete case. Due 27 October; completed 25 October.** Document reconstruction to the common time base, known delay compensation, valid comparison interval/edges, and unequal-length handling for Jesher. Test the policy with a known signal. Supply the first sampling case in MATLAB and Simulink for the full pipeline; preserve its actual rate for quantization and metrics.
  - Evidence: the saved 22.05 kHz [Simulink model](../Simulink/SamplingModel_Abdulrahman.slx), [comparison script](../Matlab/Compare_Sampling.m), alignment procedure below, and [300 Hz validation results](../Results/Abdulrahman/AA03/known_tone_validation.csv). Speech/music differences were `0` and `3.33066907388e-16`; known-tone differences were `0` and `6.93889390391e-17`, with zero residual reconstruction lag. This supplies the verified sampling case; Khaled's quantization and Jesher's metrics remain their tasks.
- [x] **AA-04 - Complete every sampling route in both platforms. Due 29 October; implementation verified 3 November.** Implement 22.05 kHz, 11.025 kHz, 8 kHz, and 4 kHz with and without anti-aliasing filtering. Handle non-integer conversions correctly; keep amplitudes consistent with the reference. Sampling outputs and metadata are packaged for Khaled; recipient acceptance and combined-case integration remain under AA-06.
  - [x] **MATLAB portion completed 1 November:** all eight rate/filter cases are implemented, packaged and checked in the [sampling handoff](../Results/Abdulrahman/Sampling/README.md). The 8/4 kHz unfiltered methods are explicitly identified as linear interpolation without an AA LPF.
  - [x] **Simulink portion completed 3 November:** all four saved models were rerun using [Compare_All_Sampling.m](../Matlab/Compare_All_Sampling.m). All eight comparisons passed; [measured table](../Results/Abdulrahman/Sampling/simulink_comparison.csv) and [actual aligned Simulink arrays](../Results/Abdulrahman/Sampling/simulink_cases.mat) are saved. Both-platform sampling is ready for handoff; recipient acceptance and combined cases remain under AA-06.
- [x] **AA-05 - Produce sampling/aliasing evidence. Due 30 October; reviewed 8 November.** For each lower rate at 16 effective bits, produce comparable original/filtered/unfiltered waveform, FFT, and spectrogram views. Demonstrate identifiable frequency folding with at least one existing known-frequency test signal and discuss what is observable in the real recording. Compare equivalent MATLAB/Simulink cases and document filter/method/axis differences.
  - [x] **MATLAB portion completed 1 November:** twelve real-audio comparisons plus the known-tone figure are saved in [Sampling](../Results/Abdulrahman/Sampling/). The 10 kHz tone folds to 1,025 Hz at 11.025 kHz; filtering suppresses the largest residual by 68.74 dB. See [measured peaks](../Results/Abdulrahman/Sampling/aliasing_summary.csv).
  - [x] **Numerical platform evidence completed 3 November:** all eight maximum differences and delay corrections are recorded in the comparison CSV and report. The report explains frame FFTs versus full-record plots and the final padded frame. Final figure review remains part of sign-off.
- [ ] **AA-06 - Complete the combined-case handoff. Due 30 October.** Work with Khaled to cover every lower-rate/filter/bit-depth combination in both platforms, preserving IDs/timing metadata. Help Jesher resolve alignment or rate discrepancies. Document which cases and artifacts were accepted; do not call the whole matrix complete if any route is missing.
  - **Ready for integration:** eight MATLAB sampling cases, eight actual aligned Simulink controls, eight MATLAB WAV copies and timing/filter metadata are prepared. Recipient acceptance, reduced-bit combinations and final integration are not claimed.
- [x] **AA-07 - Write the sampling/aliasing report section. Due 31 October; reviewed 8 November.** Include methods, filter choices, non-integer conversion, plots with units, observed folding/overlap, Nyquist interpretation, limitations, and MATLAB/Simulink comparison. Explain the reconstruction/alignment policy so quality results are reproducible.
  - [x] **MATLAB draft ready 1 November:** [editable report section](../Reports/Abdulrahman_Sampling.md) and [18-page PDF](../output/pdf/Abdulrahman_Sampling_Report_Draft.pdf), using the measured results and thirteen figures.
  - [x] **Simulink results added 3 November:** the updated 19-page sampling draft includes all rates, numerical tolerances, known-delay handling and reproducible commands. Final team integration/review remains open.
  - [x] **Report revision completed 5 November:** the current PDF replaces the longer draft with seven main pages and three supporting appendix pages. It covers theory, all rates, methods, known-tone evidence, Simulink comparisons and limitations. The [Q&A sheet](../Reports/Abdulrahman_Sampling_QA.md) supports rehearsal. All ten pages were rendered and visually inspected; figure links and existing evidence hashes passed. No new experiments or subjective findings were invented. Shared Word report unchanged; team assembly/sign-off remains open.
- [ ] **AA-08 - Review Yazan's baseline. Due 2 November.** Check recording metadata/provenance, portable model input, FFT parity/scaling, dB and spectrogram units, and the full-record versus frame-FFT comparison. Record findings and evidence here; Yazan updates his own checklist. Address Yazan's review of your sampling work.
- [ ] **AA-09 - Close findings and rehearse. Due 3 November.** Resolve your review/integration findings and re-run affected cases. Rehearse aliasing/alignment explanations and demonstrate that you can explain another member's section.
- [ ] **AA-10 - Sign off sampling in the final package. Due 4 November, 6:00 PM Dubai time.** Check the final source/models, sample-rate/filter metadata, report figures, matching platform results, and demonstration. Confirm no essential sampling/alignment issue remains open.

## Handoffs

**Current MATLAB package:** [Results/Abdulrahman/Sampling/README.md](../Results/Abdulrahman/Sampling/README.md). Set Current Folder to `Matlab` and run `Prepare_Sampling_Handoff` to reproduce the package. The original AA-02 files and AA-03 verification below are retained unchanged.

**Current Simulink package, 3 November:** from the repository root, run `addpath("Matlab"); Compare_All_Sampling`. This initializes the required coefficient variables, runs all four saved models to 20 s and writes `simulink_comparison.csv` plus eight top-level `cases` in `simulink_cases.mat`. The visual spectrogram is temporarily bypassed during the automated check to avoid a scope UI callback error; models are not saved by this script. The data paths and logging remain active. Your shared Word report is not edited by this workflow.

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
| Current handoff | `Results/Abdulrahman/AA02/sampling_22050.mat`, containing the `prototype` structure described below, plus `summary.csv`, `comparison.png`, and filtered/unfiltered 16-bit PCM WAV copies. |
| Case identifiers | `speechmusic_fs22050_b16_none_matlab` and `speechmusic_fs22050_b16_lpf_matlab`. At this sampling-only stage, `b16` identifies the source/control. MAT arrays retain their double samples with no explicit reduced-bit-depth quantization (`quantizationApplied=false`); separate WAV copies use a 16-bit PCM container and include its rounding error. Khaled owns subsequent quantization and final precision metadata. |
| Khaled receives | Both processed arrays, their actual rates, case IDs, sample counts/durations, and filter/timing metadata. Preserve this metadata when applying quantization. |
| Jesher receives | The original reference and processed arrays, start/last sample times, actual rates, sample counts, and filter-delay metadata. The AA-03 policy is documented below; the all-rate extension and inverse ratios are in the current sampling handoff. |
| Simulink handoff | The 22.05 kHz model is saved in `Simulink/SamplingModel_Abdulrahman.slx`, with verification in `Matlab/Compare_Sampling.m`. Supply equivalent samples and the same metadata fields/units with a `simulink` case label. Other sampling rates remain under AA-04. |

## AA-02 reproducible handoff and verified results

**Run requirements:** MATLAB and Signal Processing Toolbox (`resample`), plus the tracked source WAV. The successful verification used MATLAB R2026a. No Simulink license is needed to run this MATLAB prototype. Compatibility with earlier MATLAB releases has not been tested.

Set MATLAB's **Current Folder to the repository's `Matlab` folder**. The script uses `../Audios/SpeechMusic.wav` and saves into `../Results/Abdulrahman/AA02`. Run:

```matlab
Sampling_Abdulrahman
```

Running the whole script creates three figures and regenerates five handoff files in `Results/Abdulrahman/AA02/`: the MAT file, summary CSV, comparison PNG, and two WAV copies. Its saved comparison uses the same data as the two individual plots. To work only through AA-03, use **Run to Here** on the first executable line after the AA-03 section. The reconstruction retains the full original sample interval; optional edge trimming is deferred.

### Run the separate MATLAB/Simulink comparison

[Sampling_Abdulrahman.m](../Matlab/Sampling_Abdulrahman.m) runs independently of Simulink. [Compare_Sampling.m](../Matlab/Compare_Sampling.m) contains the checks that require the model's `out` result.

1. Set Current Folder to `Matlab` and run the whole `Sampling_Abdulrahman` script. This creates the MATLAB signals and `filterCoefficients` without requiring `out`.
2. Change Current Folder to the repository root. Open `Simulink/SamplingModel_Abdulrahman.slx` and run it. Its audio source uses `Audios/SpeechMusic.wav`; the model uses the filter coefficients from step 1 and returns `out`.
3. Change Current Folder back to `Matlab` and run `Compare_Sampling`.

Keep the workspace variables between these steps. Repeat steps 1 and 2 after changing the recording, filter, or sampling rate so the comparison uses matching current results. The comparison is optional when running the MATLAB-only script, but requires both earlier steps when executed.

For the current 22.05 kHz prototype, the comparison joins the logged frames, removes only excess frame coverage, and compensates the known 10-output-sample FIR delay. Expected maximum absolute differences are zero without filtering and floating-point rounding noise (approximately `3.33e-16`) with filtering. These compare MATLAB versus Simulink, not audio degradation against the original recording. We retain the full shared recording; optional edge trimming is deferred.

### AA-03 alignment procedure for Jesher

Use this procedure for the verified 44,100 -> 22,050 Hz sampling case. Quantization must preserve the processed signal's 22,050 Hz rate and timing metadata.

1. **Reference:** use the original mono samples `x` at 44,100 Hz, starting at t=0. The primary recording has 882,005 samples.
2. **MATLAB processed arrays:** `yNoFilter` and `yFiltered` are at 22,050 Hz. `resample` has already compensated its own FIR delay; do not shift these arrays again.
3. **Raw Simulink outputs:** flatten each logged `Data` array with `(:)`. For the unfiltered branch, retain the first 441,003 samples. For the filtered branch, remove the known 10-output-sample FIR delay, then retain 441,003 samples (indices 11 through 441,013). This discards only delay and excess frame coverage. `Compare_Sampling.m` already performs these steps; do not compensate its aligned arrays a second time.
4. **Common grid for quality metrics:** reconstruct each processed array at 44,100 Hz using `resample(signal,2,1)`. This changes the grid, not the information content. Retain the first `length(x)` reconstructed samples. The primary odd-length recording produces 882,006 reconstructed samples, so only the final unmatched endpoint is removed.
5. **Comparison interval:** use all 882,005 original sample times, t=0 through `(882005-1)/44100` seconds. No additional edge trimming, optimized lag shifts, or independent amplitude normalization is applied. Filtering/reconstruction errors remain part of the measured degradation.

The MAT handoff preserves exact sampling-stage arrays and their actual rates. The WAVs are 16-bit playback copies with recorded conversion errors. Use matching representations and report the choice when computing NMSE/SNR. The remaining sampling rates and combined bit-depth cases belong to AA-04/AA-06.

**Known-signal check, 25 October:** the existing `Audios/300Hz_Sine.wav` was verified to have a dominant frequency of 300 Hz. Its 882,000 original samples produced 441,000 samples at 22,050 Hz. Both source-rate reconstructions retained all 882,000 samples and had zero residual lag (full-record correlation checked over +/-20 original-rate samples; no corrective lag search was applied). Simulink agreed with MATLAB exactly without filtering and within `6.93889390391e-17` with filtering after the known 10-sample delay. See the linked CSV for the measured values.

The test used an isolated input fixture so the unchanged processing code and saved model received the same known tone through their normal relative paths. Production audio files were not replaced. To repeat manually, use the 300 Hz file in both inputs, run MATLAB only through AA-03 to avoid overwriting the primary handoff, run Simulink, and run `Compare_Sampling`; restore the primary input afterward. The speech/music handoff arrays were checked unchanged when updating its policy metadata.

**Playable WAV copies:**

- [Without anti-aliasing filter](../Results/Abdulrahman/AA02/speechmusic_fs22050_b16_none_matlab.wav)
- [With anti-aliasing filter](../Results/Abdulrahman/AA02/speechmusic_fs22050_b16_lpf_matlab.wav)

Both WAVs are mono, 22,050 Hz, 16-bit PCM copies with the same sample counts/durations as their respective MAT arrays. The script does not normalize them. WAV conversion rounds samples to the PCM representation; use the saved round-trip-error metadata when evaluating exported audio. The MAT arrays preserve the original processing results. The original 44.1 kHz WAV remains in `Audios/SpeechMusic.wav`.

| Signal | Actual rate (Hz) | Sample count | Duration N/Fs (seconds) |
| --- | --- | --- | --- |
| Original | 44,100 | 882,005 | 20.000113379 |
| Without anti-aliasing filter | 22,050 | 441,003 | 20.000136054 |
| With anti-aliasing filter | 22,050 | 441,003 | 20.000136054 |

The small duration difference is sample-count rounding for an odd-length input, not a playback-speed change. Both output grids start at t=0, have sample interval 1/22,050 seconds, and have last sample time approximately 20.000090703 seconds. Duration N/Fs and last sample time (N-1)/Fs are different quantities.

**Unfiltered method:** `x(1:2:end)` retains samples 1, 3, 5, ... directly. The saved output was checked for exact equality to this indexing result; no filtering or independent amplitude normalization is performed in that branch.

**Filtered method:** `[yFiltered, filterCoefficients] = resample(x, 1, 2, 10, 5)`. The explicit settings match MATLAB's defaults: design parameter n=10 and Kaiser-window beta=5. The verified filter has 41 coefficients (order 40), saved as `prototype.filter.coefficients`. Its nominal cutoff is 11,025 Hz; it has a finite transition band rather than an ideal brick-wall response. The raw linear-phase group delay is 20 input samples, and `resample` compensates it internally. Do not shift the result by that delay a second time. See the [MathWorks resample documentation](https://www.mathworks.com/help/signal/ref/resample.html).

**Saved structure:** `prototype.original`, `prototype.unfiltered`, and `prototype.filtered` each contain `samples`, `Fs`, `sampleCount`, and `durationSeconds`. Each processed branch also contains `caseId`, `filterMode`, `firstSampleTimeSeconds`, `lastSampleTimeSeconds`, and a `wav` structure recording its WAV filename, container bit depth, file bytes, and maximum absolute round-trip error. `prototype.filter` holds the ratio, design settings, actual coefficients, order, nominal cutoff, raw group delay, and compensation flag. The root records source bit depth, MATLAB release, and that the MAT sampling-stage arrays have no explicit quantization/normalization applied. The CSV includes the WAV metadata too.

Example receiver access, from the repository root:

```matlab
handoff = load(fullfile('Results', 'Abdulrahman', 'AA02', 'sampling_22050.mat'));
signal = handoff.prototype.unfiltered.samples;
signalFs = handoff.prototype.unfiltered.Fs;
```

**Verification performed:** mono-column shape; output rates/counts and odd-length rounding; duration bounds; exact unfiltered indexing; equality of the explicit filtered call to `resample(x,1,2)`; saved MAT-file round trip; CSV counts/rates; and three generated figures. The saved comparison image was visually inspected before publication. The current simplified script uses the relative paths above and must run with `Matlab` as the Current Folder.

**What this AA-02/AA-03 evidence establishes:** the reproducible 22.05 kHz prototype and its verified Simulink comparison. The closely overlapping linear spectra do not, by themselves, prove that aliasing is absent. The 1 November MATLAB extension, figures, aliasing demonstration and all-rate handoff are linked at the top of this document; the corresponding new-rate Simulink comparisons and combined quantization/metric integration remain open.

## Progress log

| Date | Update / evidence | Next action or blocker |
| --- | --- | --- |
| 24 October | Task plan created. No sampling implementation is present in the inspected tracked files at ad8cc0d; unpublished work is not assessed. | AA-01 due 25 October; first component handoff due 26 October. |
| 24 October | AA-02 MATLAB prototype implemented and verified; saved arrays, settings, numeric summary, and spectrum evidence are linked above. Earlier task-plan entry is retained as history. | Use the documented MAT-file format for subsequent handoffs. |
| 24 October | AA-01 completed: source/settings, data shape, filter modes, timing fields, and run requirements documented. Separate format confirmation removed at the user's instruction; recipient approval is not claimed. | Next: AA-03 alignment and the first MATLAB/Simulink pipeline case. |
| 24 October | Added team-requested filtered/unfiltered WAV copies alongside the MAT handoff. The script recreates both exports and records WAV width, file bytes, and round-trip error. | Teammates can play/import the WAVs or load the exact processing arrays from the MAT file. |
| 25 October | Moved checks requiring `out` into `Compare_Sampling.m`. Verified a fresh MATLAB-only run without `out`, then the saved Simulink model and separate comparison: differences `0` and `3.33066907388e-16`. | Follow the three-step run order above. |
| 25 October | Completed AA-03: documented the full-record metric alignment procedure and verified the known 300 Hz tone, including sample counts, zero residual lag, and matching MATLAB/Simulink outputs. | Next session: AA-04, extend sampling to 11.025 kHz, 8 kHz, and 4 kHz in both platforms. |
| 1 November | Completed the remaining MATLAB rate conversions, known 10 kHz aliasing demonstration, eight-case MAT/WAV handoff, thirteen comparison figures and a report draft. All WAVs were read back; processing methods and reconstruction coverage checked. | Complete the three new Simulink rates and comparisons; integrate quantization/metrics with Khaled and Jesher. |
| 1 November | The existing 300 Hz tone retained its dominant frequency and zero diagnostic residual lag in all eight reconstructed MATLAB cases; no lag correction was applied. See [alignment checks](../Results/Abdulrahman/Sampling/alignment_checks.csv). | Preserve the same time-grid policy in subsequent quality measurements. |
| 2 November | Prepared the MATLAB checkpoint for publication: rechecked the case/WAV inventories, saved verification records, report links and artifact checksums. Text checksums now tolerate Git's Windows line-ending conversion. The 1 November measurements are retained. | Finish the remaining Simulink cases and comparisons; complete combined-case integration and final review. |
| 2 November | Virtual merge with Jesher's branch at `13fc434` was clean. Documented the external MAT schema adapter requirement, nearest-selection versus linear-interpolation difference, and MAT/WAV measurement basis in the handoff README. | Reconcile interfaces/methods before treating the branches as one equivalent experiment. |

**Technical review findings (5 November):** [Review record](../Reports/Package_Review_2026-11-05.md). All 40 sampling manifest entries and eight WAV headers pass; all eight saved platform comparisons satisfy tolerance. Yazan's FFT parity/scaling and relative model input were inspected. Baseline spectrogram units need checking; zero FFT magnitudes produce negative infinity in the dB display. Integrated quantization/metrics, final package execution, and reciprocal teammate acceptance remain open. No new simulations were run during this audit.

**Listening checks (5 November):** Abdulrahman reports completion. Case-specific subjective observations and playback conditions have not been recorded here; no additional listening claims are inferred.

**Shared Word report (5 November):** sampling section and supporting appendix inserted into [The report.docx](../The%20report.docx), with thirteen embedded figures and three editable tables. Existing report body content was preserved exactly. The combined document was exported using Word and visually reviewed; it contains nineteen pages at this checkpoint. This publishes the sampling section, not the still-pending whole-team submission sign-off.

**Publication checkpoint (5 November):** all four sampling Simulink models are complete and numerically verified. The comparison script, aligned Simulink MAT handoff, results table, report updates and this progress file are included in the publication checkpoint. AA-06 and final report/package sign-off remain open; no sampling model needs to be redone for those tasks.

**Repository synchronization (5 November):** origin/main already includes Jesher's work at `e8c404f`; this sampling checkpoint was rebased onto it without conflicts. His work is now available locally. Final integrated execution and the R2026b/R2026a model compatibility issue remain separate from the completed sampling simulations.

**3 November verification:** unfiltered differences at 22.05/11.025/8/4 kHz were `0`, `0`, `1.6794e-11`, `1.3194e-11`; filtered differences were `3.3307e-16`, `5.5511e-16`, `7.7716e-16`, `6.6613e-16`. These compare actual saved-model outputs with exact MATLAB controls, not quality degradation against the original.
**Final sign-off:** pending; add date, source/result commit, reviewer, and any remaining limitations.

**8 November independent technical review:** source and all 40 sampling evidence checksums pass. A fresh isolated R2026a run passed `Check_Sampling_Handoff` and all eight actual saved-model comparisons using `Compare_All_Sampling`, reproducing the recorded tolerances and differences. Baseline execution and Jesher's 22 MATLAB regression tests also passed. Sampling implementation, aliasing evidence and written section are technically ready for inclusion; no sampling rewrite is indicated. See [team submission review](../Reports/Team_Submission_Review_2026-11-08.md) for exact scope and remaining team blockers. AA-06, reciprocal owner acceptance, rehearsal and final whole-package sign-off remain open; this review does not claim those actions occurred.
