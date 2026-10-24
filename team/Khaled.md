# Khaled - Quantization, Error Analysis, and Storage

[Team progress](../README.md#team-progress) | [Schedule](../README.md#schedule) | [Shared experiment contract](../README.md#shared-experiment-contract) | [Update instructions](../README.md#how-to-update-your-progress)

**Owner:** Khaled | **Reviewer:** Jesher

**Last updated:** 24 October 2026

**Internal finish:** 4 November 2026, 8:00 PM Dubai time. All deadlines below are at 8:00 PM Dubai time.

**Role:** own quantization and its error analysis, then quantify the storage-quality compromise.

## Tasks

- [ ] **KH-01 - Accept the shared contract and define the quantizer convention. Due 25 October.** Confirm effective bit depths, fixed amplitude range, levels/endpoints, clipping, and rounding convention for both platforms. Agree the sampling-output interface with Abdulrahman and the effective-bit/export metadata with Jesher. Document run instructions; do not normalize each case separately.
- [ ] **KH-02 - Deliver one quantization prototype. Due 26 October.** Share one reduced-bit-depth case from the primary recording, including quantized samples, error samples, unchanged actual sample rate, and an initial error plot. Include ordinary values, zero, range boundaries, and out-of-range/clipping checks.
- [ ] **KH-03 - Complete native-rate quantization in both platforms. First complete-case participation due 27 October; all bit depths due 29 October.** Implement 8-, 4-, and 2-bit uniform quantization and preserve the 16-bit reference/control. Confirm the same level mapping/range in MATLAB and Simulink; record the error waveform/distribution and any explained numerical differences.
- [ ] **KH-04 - Generate all combined processing cases. Due 30 October.** Receive Abdulrahman's full sampling outputs by 29 October and apply the agreed bit depths after sampling. Include native-rate controls and all lower-rate/filter combinations. Hand Jesher all 36 signals per platform, keyed by case ID with rate, effective bits, filter mode, timing/length, and quantizer settings. Preserve the original reference.
- [ ] **KH-05 - Produce quantization and processed-signal plots. Due 31 October.** At the native rate, compare the original and each reduced bit depth using waveform, FFT, spectrogram, error waveform, and error distribution views. Include a representative combined rate/bit-depth case, agreed with Jesher, and compare matching MATLAB/Simulink results. Keep axes/units and reference settings consistent.
- [ ] **KH-06 - Complete the storage-quality table. Due 31 October.** Receive Jesher's metrics/files/container metadata by noon, then use each case's actual rate, duration/sample count, channel count, effective bits, and actual export size/container width. Report theoretical payload separately from actual WAV bytes, explain packing/header/container overhead, and link to NMSE/SNR and listening results by case ID. Do not claim that a low-bit quantizer automatically produces a low-bit WAV container.
- [ ] **KH-07 - Write the quantization/storage report section. Due 1 November.** Include methods/conventions, error figures, storage table, quality-storage tradeoffs, MATLAB/Simulink comparison, and theory versus results. Discuss the assumptions behind the approximate 6 dB/bit rule rather than expecting every speech/music case to follow it exactly.
- [ ] **KH-08 - Review Jesher's evaluation/export work. Due 2 November.** Check matrix completeness, signal alignment consistency, NMSE/SNR sanity cases, actual export rates/container widths, playback checks, and case-linked listening/storage results. Record findings here; Jesher updates his own checklist. Address Jesher's quantizer/storage review.
- [ ] **KH-09 - Close findings and rehearse. Due 3 November.** Resolve your quantizer/storage/integration issues and regenerate affected cases/tables. Explain quantization error and storage choices during rehearsal, and explain another teammate's section.
- [ ] **KH-10 - Sign off quantization/storage in the final package. Due 4 November, 6:00 PM Dubai time.** Check that final source/models, effective-bit metadata, error figures, storage calculations, and report interpretations agree with the exported files and demonstration.

## Handoffs

| When | Give / receive | Acceptance evidence |
| --- | --- | --- |
| 25-26 October | Receive Yazan's input; give first quantization output to Yazan/Jesher | Same rate/time base, quantizer convention and error signal documented |
| 27 October | Join the first complete case in both platforms | Quantization accepts Abdulrahman's output and preserves its metadata |
| 29-30 October | Receive all sampling routes; give all combined cases to Jesher | 36 cases per platform with stable IDs and settings |
| 31 October | Receive actual WAV metadata/sizes and metrics from Jesher | Storage table links effective precision, container bytes, and quality |
| 1 November | Give Yazan the quantization/storage section | Figures/tables are traceable to cases and methods |

## Completion checks

Check that the number of distinct output levels does not exceed the selected bit depth's capacity; check boundary/clipping behavior and agreement across platforms. Separate quantizer error at a given time base from total degradation relative to the original recording. Keep effective quantizer bits distinct from WAV container bits.

Keep completed tasks and evidence. If sampling inputs are delayed, continue native-rate quantization, boundary checks, Simulink work, and the theoretical storage table.

## Progress log

| Date | Update / evidence | Next action or blocker |
| --- | --- | --- |
| 24 October | Task plan created. No quantization implementation is present in the inspected tracked files at ad8cc0d; unpublished work is not assessed. | KH-01 due 25 October; prototype due 26 October. |

**Review findings / receiver acceptance:** pending; add task ID, finding, evidence, owner, and resolution date here.
**Final sign-off:** pending; add date, source/result commit, reviewer, and any remaining limitations.
