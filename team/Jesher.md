# Jesher - Quality Metrics, Audio Output, and Listening

[Team progress](../README.md#team-progress) | [Schedule](../README.md#schedule) | [Shared experiment contract](../README.md#shared-experiment-contract) | [Update instructions](../README.md#how-to-update-your-progress)

**Owner:** Jesher | **Reviewer:** Khaled

**Last updated:** 24 October 2026

**Internal finish:** 4 November 2026, 8:00 PM Dubai time. All deadlines below are at 8:00 PM Dubai time.

**Role:** make the quality comparison valid, ensure outputs can be heard correctly, and connect objective results to perception.

## Tasks

- [ ] **JE-01 - Accept the shared contract and define evaluation inputs. Due 25 October.** Confirm case IDs/result columns and required source/processing metadata. Agree quantizer/export metadata with Khaled and alignment needs with Abdulrahman. Document the evaluation entry point, software needs, and how outputs will be named.
- [ ] **JE-02 - Evaluate the first complete case. Due 27 October.** With Abdulrahman, approve the common time base, reconstruction, delay/edge policy, reference interval, and length handling. Evaluate a combined reduced-rate/reduced-bit case in both platforms; calculate NMSE/SNR, export at the actual rate, re-import to check it, and verify speaker playback. Give Yazan the complete-case evidence.
- [ ] **JE-03 - Check metric correctness before the full run. Due 29 October.** Include unchanged input (zero error), a deliberately degraded case with predictable behavior, zero-reference-energy handling, and mismatched-rate/length handling. Confirm NMSE and SNR are consistent for the same valid comparison; document the treatment of infinities/undefined values. Do not use independent per-case normalization or unequal time bases to improve scores.
- [ ] **JE-04 - Complete the full metrics and platform comparison table. Due 31 October, noon Dubai time.** Receive all 36 cases per platform from Khaled by 30 October. Check for missing/duplicate IDs and evaluate all 72 result rows using the same alignment policy. Record rate, bits, filter mode, sample count/duration, valid interval, NMSE, SNR, and matching export metadata. Compare MATLAB and Simulink under equivalent conditions; record tolerances and explain discrepancies with the relevant owner.
- [ ] **JE-05 - Export, verify, and package the audio. Metadata/files due 31 October, noon Dubai time; final ZIP and playback checks due 8:00 PM.** Export each agreed case at its actual rate in a supported WAV container, record effective bits separately from actual container width, and inspect re-imported samples/rate/duration. Verify playback and provide a manifest plus ZIP containing the original and all primary processed outputs from both platforms. Supply filenames/bytes/container widths to Khaled for storage analysis; preserve platform IDs so outputs do not overwrite one another.
- [ ] **JE-06 - Complete perception and combined-case analysis. Due 31 October.** Gather listening notes from all four teammates using the same playback setup/volume policy and representative native, filtered/unfiltered, reduced-bit, and combined cases. Document what was actually listened to. Link descriptions to case IDs and NMSE/SNR. With Khaled, ensure representative combined-case waveforms, FFTs, and spectrograms are included; Abdulrahman/Khaled supply their component comparisons.
- [ ] **JE-07 - Write the metrics/playback report section. Due 1 November.** Explain metric definitions and alignment, full summary tables, MATLAB/Simulink differences, export/playback method, perceptual observations, and limitations. Give Yazan the figures/tables and final audio-manifest reference.
- [ ] **JE-08 - Review Khaled's quantization/storage work. Due 2 November.** Check uniform quantization conventions and boundary checks, error plots, theoretical storage assumptions, actual export widths/bytes, and consistency between quality and storage tables. Record findings here; Khaled updates his own checklist. Address Khaled's review of your metrics/exports.
- [ ] **JE-09 - Close findings and rehearse. Due 3 November.** Resolve evaluation/export issues and regenerate affected rows/files. Rehearse the live playback and metric interpretation and explain another teammate's section.
- [ ] **JE-10 - Sign off evaluation/audio in the final package. Due 4 November, 6:00 PM Dubai time.** Check the final table covers every case, the manifest matches the ZIP, the original is retained, audio plays at the intended speed, and the final report/demo uses the same verified outputs.

## Handoffs

| When | Give / receive | Acceptance evidence |
| --- | --- | --- |
| 25-27 October | Receive baseline/settings from Yazan; agree alignment with Abdulrahman | A fixed comparison policy and one complete case in both platforms |
| 29 October | Complete sanity checks while full processing is being finalized | Expected cases/edge conditions documented with actual results |
| 30-31 October | Receive full processed signals from Khaled; return metrics and export metadata | 72 complete primary result rows and traceable WAV files |
| 31 October, noon | Give Khaled actual files/bytes and objective quality results; add listening notes by 8:00 PM | Storage calculation uses the real exported files and case IDs |
| 1 November | Give Yazan the metrics/playback section, table, and audio archive/manifest | Every report claim can be traced to a case/result |

## Completion checks

Subtract only aligned samples representing the same physical times. Verify that changing rate did not only relabel playback speed. When total error is positive and the reference energy is positive, NMSE/SNR should obey their mathematical relationship; unchanged input and silence require explicit handling.

Keep the original recording, don't normalize each export independently, and distinguish digital spectrum dB from calibrated sound-pressure measurements. Report listening observations actually collected; do not invent subjective results or assume all cases were heard.

Keep all completed tasks with evidence. If processed inputs are delayed, continue metric sanity checks, result-table design, export/re-import checks, and the listening protocol using the baseline.

## Progress log

| Date | Update / evidence | Next action or blocker |
| --- | --- | --- |
| 24 October | Task plan created. No metrics/export implementation is present in the inspected tracked files at ad8cc0d; unpublished work is not assessed. | JE-01 due 25 October; complete-case evaluation due 27 October. |

**Review findings / receiver acceptance:** pending; add task ID, finding, evidence, owner, and resolution date here.
**Final sign-off:** pending; add date, source/result commit, reviewer, and any remaining limitations.
