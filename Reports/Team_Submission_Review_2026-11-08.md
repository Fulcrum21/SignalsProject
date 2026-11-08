# Independent team submission review

Review date: 8 November 2026. Reviewed checkout: main at `0d0dd4b`; fetching origin found no newer main commits. Reviewer role: fifth-member technical review, not instructor approval or a claim of teammate authorship.

## Decision

The sampling implementation and sampling report content satisfy the reviewed sampling requirements. Whole-project submission approval remains withheld: the shared report contains Tasks 1 and 2 only, the final audio ZIP is not in the checkout, and the committed Jesher model targets R2026b while the local demonstration machine uses R2026a. Khaled's separately authored quantization/storage deliverable is not present, so it cannot be signed off from this checkout.

The brief assigns 15% to sampling/aliasing, 15% to baseline, 15% to quantization, 15% to metrics, 10% to playback/perception, 10% to report/code and 20% to Q&A. A passing sampling audit does not replace the remaining team requirements. No grade is guaranteed.

## Abdulrahman — detailed sampling review

| Requirement | Review result and evidence |
| --- | --- |
| All lower rates, both modes | 22,050, 11,025, 8,000 and 4,000 Hz; eight cases in each platform. Integer selection and rational-rate linear interpolation are clearly distinguished from filtered resampling. |
| Correct sampling grid | Output counts are 441,003 / 220,502 / 160,001 / 80,001 per path. Rates, source-covered times and reconstruction coverage pass the fresh MATLAB handoff check. |
| AA filtering | Kaiser FIR `resample(...,p,q,10,5)`, unchanged amplitude scale; filter coefficients and processing metadata preserved. Non-integer interpolation's own frequency-response effect is acknowledged. |
| Known alias | Existing 10 kHz tone produces a measured 1,025 Hz alias at 11,025 Hz. Recorded filtered residual suppression is 68.74 dB. Fresh handoff assertions confirm the peaks and suppression exceed the test threshold. |
| Visual evidence | All four rates have original/filtered/unfiltered waveform, FFT and spectrogram files. Main report plus supporting appendix contains thirteen figures. Full-resolution dB figures remain in the results folder. |
| Time alignment | Common physical time base; reconstruction restores the grid rather than information; known delay compensated, surplus frame coverage removed, no optimized shifts or independent normalization. Fresh 300 Hz checks pass for all eight MATLAB paths. |
| Exports and integrity | All 40 SHA-256 entries match their declared bytes/modes. Eight sampling WAV headers are mono PCM16 with correct rates/counts; MATLAB checks exact stored arrays, WAV round-trip bounds and metadata. |
| Simulink | Four R2026a models use project-relative audio paths. Saved eight-case comparison table passes the declared tolerances. Fresh runtime confirmation is recorded below when complete. |
| Report | Methods, Nyquist theory, known-tone prediction, interpretation, limitations and numerical platform agreement are present. The sampling section is embedded in `The report.docx`; it is not merely a separate PDF. |

No sampling algorithm rewrite is indicated. Use `Compare_All_Sampling` from the repository root to initialize coefficients and verify the saved models; standalone model execution depends on those documented coefficient variables. From Current Folder `Matlab`, use the handoff preparation/check scripts. Do not treat full-record and final-frame FFTs as interchangeable.

Your report completion does not constitute receiver acceptance, independent teammate review of your work, or Q&A rehearsal. Keep AA-06, AA-09 and whole-package sign-off open until those actions actually occur.

## Yazan — baseline review

The original baseline script runs successfully in fresh R2026a. Its real-signal single-sided FFT implements the odd/even distinction correctly; the baseline SLX archive is valid, declares R2026a and uses the relative source path `Audios/SpeechMusic.wav`.

Corrections required before signing off the baseline write-up:

1. The paragraph beginning “However, the FFT is symmetric” incorrectly says to remove DC and Nyquist. Keep DC; for an even-length signal keep the exact Nyquist bin without doubling it. For odd lengths, there is no exact Nyquist bin and all positive-frequency bins after DC are doubled.
2. Replace “Discrete Time Fourier (DFT)” with “discrete Fourier transform.” The DTFT has a continuous frequency variable, not a continuous-time output signal. The DFT samples the frequency representation; calling it “virtually continuous” is unnecessary and misleading.
3. Replace the unfinished “toolbox provided by P.” sentence with the actual MathWorks toolbox names used.
4. Verify the spectrogram colorbar's density convention. A kHz frequency axis does not make a per-Hz PSD become per-kHz. The final line `colorbar.Label.String = ...` should use an explicit colorbar handle if relabeling is intended; check the displayed label rather than relying on the assignment. Zero FFT bins legitimately give negative infinity in dB; use a documented display floor if a finite plot is wanted.
5. A short prose-only continuation page remains in the original baseline formatting. Repair it during final report assembly; the sampling insertion preserved that existing material.

These are report/label corrections, not evidence that the baseline audio or FFT samples are wrong. No edits to Yazan's implementation or ownership checklist are implied by this review.

## Jesher — metrics and combined pipeline review

The committed table contains exactly 72 unique cases: 36 per platform, using four native-rate bit-depth cases and 32 reduced-rate/filter/bit-depth cases. Both processing-array and exported-audio NMSE/SNR satisfy their mathematical relationship for positive finite errors. The platform table has 36 pairs and the manifest has 73 rows including the reference.

The source implements signed uniform quantization with explicit rounding/saturation, a 16-bit bypass control, distinct processing versus WAV scores, actual-rate PCM16 exports, reconstruction onto the original time grid, and explicit silence/zero-error behavior. MATLAB and Simulink processing paths are implemented separately using actual blocks. The sampling methods match Abdulrahman's convention; this still does not establish Khaled's authorship or acceptance of that quantizer.

The saved `Jesher/Demo/Audio_Demo.slx` declares R2026b. For R2026a demonstration, rebuild it with `build_model` and verify the resulting model, or supply an R2026a export. The isolated audit rebuild is kept separate from the committed model so a successful rebuild is not mistaken for a fixed published artifact.

Audio WAVs and `all_audio.zip` are intentionally ignored by Jesher's repository settings. Their absence from Git is not an algorithm defect, but the final ZIP must actually be generated, inspected and available for the required submission/laptop check. A committed manifest alone is insufficient.

The historical three-case “audible and clear” note does not document observations for the new full matrix. Abdulrahman has reported his listening checks complete; no additional subjective details, device settings or teammate listening are invented here.

## Khaled — evidence unavailable

No Khaled-owned quantization source/model or storage report section is present in the inspected main or available remote branch list. Jesher supplies a working quantizer implementation, but it must not be silently credited to Khaled. Obtain Khaled's actual work or explicitly agree and document the team's final implementation and contributions.

Before sign-off, check native-rate 8/4/2-bit levels, clipping/rounding boundaries, quantization error waveform/distribution, a combined case, and storage calculations separating theoretical effective-bit payload from actual PCM16 WAV bytes. A low effective bit depth does not automatically reduce a PCM16 WAV's size.

## Final package blockers and owners

| Priority | Action | Owner |
| --- | --- | --- |
| Required | Assemble quantization/storage and metrics/perception sections, complete tables, conclusion and references into the shared report; export and inspect the final PDF. Current Word file has only Tasks 1 and 2. | Yazan with Khaled and Jesher |
| Required | Make the final demo model open and run in the intended installed MATLAB release. | Jesher |
| Required | Supply/confirm Khaled's final contribution and quantizer convention; reconcile ownership with the existing demo. | Khaled and team |
| Required | Generate and inspect original plus processed-audio ZIP and its manifest; keep it accessible for actual submission/laptop inspection. | Jesher / Yazan |
| Required | Correct the baseline theory and labels listed above. | Yazan |
| Required | Write actual case-linked listening observations and connect them to measured NMSE/SNR; retain Abdulrahman's completed-listening acknowledgement. | Team / Jesher |
| Required | Rehearse the live demonstration and Q&A; confirm all four owners approve the final package. | Everyone |

The supplied brief states 5 November at 6 PM; the team initially planned around 11 November. This review does not resolve that discrepancy or claim that submission occurred. Use the instructor's confirmed deadline and retain the submission receipt.

## Runtime evidence and boundaries

Checks run in an isolated copy under the Codex visualization workspace so the submission sources/results were not overwritten by the audit. Baseline execution passed. The fresh MATLAB sampling handoff check passed all eight cases. Remaining model and full-pipeline outcomes are appended below after completion. Saved-table audits are explicitly distinct from fresh runtime results.

Fresh results confirmed during this review:

- `Check_Sampling_Handoff`: pass for all eight MATLAB cases, 300 Hz timing, source identity, processing methods, reconstruction coverage, export metadata and known-tone alias assertions.
- `Compare_All_Sampling`: all eight actual Simulink comparisons pass. Unfiltered maximum differences at 22.05/11.025/8/4 kHz are `0`, `0`, `1.6793746948629e-11`, `1.31944594139455e-11`; filtered differences are `3.33066907387547e-16`, `5.55111512312578e-16`, `7.7715611723761e-16`, `6.66133814775094e-16`.
- Baseline MATLAB script: executes successfully in R2026a.
- Jesher MATLAB regression suite: 22 tests pass; covers normal/zero-energy metrics, metadata, array-preserving imports, rejected invalid/duplicate inputs, case coverage and partial-package behavior.
- `CHECK_DEMO`: metric identity, half-amplitude error, silence and signed-quantizer boundary cases pass.
- Jesher's `build_model`: rebuilds the actual block diagram successfully in R2026a, inside the isolated copy only.
- `CHECK_COMPATIBILITY`: 8 exact imported controls, 8 regenerated MATLAB controls, 16 timing checks, 4 platform alias checks and direct model Run all pass after the rebuild.

The native unchanged control emits a Simulink division-by-zero warning when forming an infinite energy ratio. Its accepted result is NMSE = 0 and SNR = positive infinity; the warning is not evidence of an incorrect score. Do not replace infinity with an arbitrary finite value to make the display look cleaner.

**Completed full-matrix rerun:** `RUN_ALL` reached `AUDIT_ALL_PASS` after 72 actual MATLAB/Simulink cases and 36 paired comparisons on the rebuilt R2026a model. Largest platform sample difference: `7.7715611723761e-16`. Independent Python validation checked all 73 WAV headers/counts/container widths/file sizes and byte-matched all 74 ZIP members (73 audio files plus manifest). The archive is valid. This resolves uncertainty about fresh full-pipeline execution in the isolated environment; it does not change the release metadata of the model still committed in the main checkout.

Evidence retained in [Results/Review_20261108](../Results/Review_20261108/): `independent_review_summary.json`, `audit_matlab.log`, `baseline_regression.log`, and the three `fresh_*.csv` tables. These audit tables contain actual isolated-output paths and must not be confused with the team's final portable submission manifest.

The regenerated playback ZIP and rebuilt R2026a model remain in the isolated audit copy at `C:/Users/pc/.codex/visualizations/2026/10/21/01a15fe4-60df-7492-8058-7d8e69edcfa4/submission-audit-20261108/Jesher/Demo/`. The ZIP is under `Results/all_audio.zip`. Copy/rebuild and verify the intended final artifacts as a deliberate package step, rather than assuming ignored files appeared in the published repository.

**Final technical verdict:** Abdulrahman's sampling implementation, evidence and written section are ready for inclusion. Jesher's computational pipeline passes after the demonstrated release-compatible rebuild; his published model/package and report/listening acceptance still need finalization. Yazan's baseline executes but needs the specified report/label corrections. Khaled's own deliverables remain unverified because they are absent. The combined team report and submission package are not yet approved. No code algorithm was changed and no review changes were pushed by this audit.

## Paste-ready report corrections for Yazan

**DFT explanation:** “The discrete Fourier transform (DFT) evaluates the finite recording on a discrete frequency grid. MATLAB computes it efficiently using the fast Fourier transform (FFT). The FFT produces complex coefficients whose magnitudes describe the strength of the corresponding frequency components.”

**Single-sided spectrum:** “For a real-valued signal, positive- and negative-frequency magnitudes are paired. We divide the FFT by the number of samples, retain DC and the positive-frequency bins, and double the paired magnitudes. DC is retained without doubling. For even lengths, the exact Nyquist bin is also retained without doubling; for odd lengths, no exact Nyquist bin exists.”

**Toolbox wording:** “We used MATLAB, Signal Processing Toolbox, Simulink and DSP System Toolbox to analyze and process the recording and compare equivalent implementations.”

## Storage acceptance rule for the final report

Theoretical packed payload is `sampleCount × channels × effectiveBits / 8` bytes (round up to whole bytes when discussing an actual packed file). For the actual supported PCM16 exports, use their measured WAV file sizes and actual container width; effective-bit reduction alone does not shrink those carriers. Link the same case ID to the quality result and storage row. Include a native-rate reduced-bit case and a combined lower-rate/reduced-bit case, and explain why a speech/music signal need not follow an exact 6 dB-per-bit improvement.
