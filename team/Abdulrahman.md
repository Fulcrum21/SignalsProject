# Abdulrahman - Sampling, Anti-Aliasing, and Alignment

[Team progress](../README.md#team-progress) | [Schedule](../README.md#schedule) | [Shared experiment contract](../README.md#shared-experiment-contract) | [Update instructions](../README.md#how-to-update-your-progress)

**Owner:** Abdulrahman | **Reviewer:** Yazan

**Last updated:** 24 October 2026

**Internal finish:** 4 November 2026, 8:00 PM Dubai time. All deadlines below are at 8:00 PM Dubai time.

**Role:** own the most demanding rate-conversion/filtering work and establish a defensible comparison time base with Jesher.

## Tasks

- [ ] **AA-01 - Accept the shared input/settings and define handoffs. Due 25 October.** Confirm the source, rate set, mono-column convention, and required filter modes. Agree with Khaled how he receives each MATLAB/Simulink sampling output, and with Jesher what timing metadata he needs. Document your run instructions and dependencies.
- [ ] **AA-02 - Deliver one reduced-rate prototype. Due 26 October.** Share filtered and unfiltered versions of one agreed case, with actual rate, sample count/duration, filter settings, and a readable spectrum. Document the unfiltered conversion method; verify it does not silently include the anti-aliasing treatment being compared.
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
| 25 October | Receive Yazan's baseline; agree interface with Khaled and alignment needs with Jesher | Same source and dimensions recorded |
| 26-27 October | Give the first filtered/unfiltered case and alignment policy | Jesher accepts the time basis; one complete case works |
| 29 October | Give all rate/filter outputs in both platforms to Khaled | Every route has actual rate, length, delay/filter metadata, and run instructions |
| 30 October | Help Khaled supply combined cases and Jesher evaluate them | No missing lower-rate combination; discrepancies logged |
| 31 October | Give Yazan the sampling section and figure references | Methods/results/discussion identify their cases and settings |

## Completion checks

Before checking implementation tasks, verify actual sample rate and duration; distinguish rate reduction from simply changing playback rate. Include both integer and non-integer conversions. Use the same baseline and filter settings across platforms, and identify the conditions under which aliasing is expected.

Keep all completed tasks checked with dated evidence. If a task is blocked, state the missing input/person and continue independent filter/model/theory work.

## Progress log

| Date | Update / evidence | Next action or blocker |
| --- | --- | --- |
| 24 October | Task plan created. No sampling implementation is present in the inspected tracked files at ad8cc0d; unpublished work is not assessed. | AA-01 due 25 October; first component handoff due 26 October. |

**Review findings / receiver acceptance:** pending; add task ID, finding, evidence, owner, and resolution date here.
**Final sign-off:** pending; add date, source/result commit, reviewer, and any remaining limitations.
