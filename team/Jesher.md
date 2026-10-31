# Jesher - Quality Metrics, Audio Output, and Listening

[Team progress](../README.md#team-progress) | [Schedule](../README.md#schedule) | [Shared experiment contract](../README.md#shared-experiment-contract) | [Update instructions](../README.md#how-to-update-your-progress)

**Owner:** Jesher | **Reviewer:** Khaled

**Last updated:** 31 October 2026

**Internal finish:** 4 November 2026, 8:00 PM Dubai time. All deadlines below are at 8:00 PM Dubai time.

**Role:** make the quality comparison valid, ensure outputs can be heard correctly, and connect objective results to perception.

## Tasks

- [ ] **JE-01 - Accept the shared contract and define evaluation inputs. Due 25 October.** Confirm case IDs/result columns and required source/processing metadata. Agree quantizer/export metadata with Khaled and alignment needs with Abdulrahman. Document the evaluation entry point, software needs, and how outputs will be named.
- [ ] **JE-02 - Evaluate the first complete case. Due 27 October.** With Abdulrahman, approve the common time base, reconstruction, delay/edge policy, reference interval, and length handling. Evaluate a combined reduced-rate/reduced-bit case in both platforms; calculate NMSE/SNR, export at the actual rate, re-import to check it, and verify speaker playback. Give Yazan the complete-case evidence.
- [x] **JE-03 - Check metric correctness before the full run. Due 29 October; execution evidence from 30 October, reviewed 31 October.** Include unchanged input (zero error), a deliberately degraded case with predictable behavior, zero-reference-energy handling, and mismatched-rate/length handling. Confirm NMSE and SNR are consistent for the same valid comparison; document the treatment of infinities/undefined values. Do not use independent per-case normalization or unequal time bases to improve scores.
  - Evidence: all 19 MATLAB tests passed with no failed/incomplete cases in [session diary](../Jesher/results/matlab_session_20261030_170012.txt). Special metric values and alignment rules are documented in [the implementation guide](../Jesher/README.md). Full-matrix evaluation and reviewer sign-off remain separate tasks.
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
| 30 October | Downloaded upstream `be17af9` locally and read all four pages of the unchanged project brief. New implementation is isolated in [Jesher/](../Jesher/README.md), including MATLAB metrics/alignment/export/archive code, handoff schema, tests, listening forms, and a report methods draft. | MATLAB is absent locally; MATLAB execution, actual listening, and reviewer acceptance remain pending. No push made in this local preparation. |
| 30 October | Independent Python audit passed the metric/validation tests and all 20 artifact checks; [audit evidence](../Jesher/results/local_audit/audit.json) includes software versions, input hashes, and limitations. Three existing source/sampling controls are available; 69 primary case handoffs are missing. [Work plan and owners](../Jesher/WORK_PLAN.md). | Receive Khaled's reduced-bit/combined arrays and quantizer convention, plus remaining sampling routes and persisted Simulink outputs. Do not treat Python results as MATLAB/Simulink execution. |
| 30 October | Final local validation: 20 Python tests passed; MISS_HIT 0.9.44 parsed/linted all 12 MATLAB files successfully. [Static-check evidence](../Jesher/results/local_audit/matlab_static_check.json) records source hashes. Nineteen MATLAB test methods cover numerical and integration behavior. | Static checks do not execute MATLAB; retain the actual MATLAB test/run and human-check requirements. |

### Local implementation and outstanding evidence

**Publication package, 31 October:** branch `codex/jesher-quality-evaluation`
contains Jesher's implementation, three-case metric/manifest tables, actual test
diary, captioned report/PDF and listening forms. At the user's direction, new
WAVs, audio ZIPs, MAT arrays and producer snapshots remain local; the full-evidence
commit is retained on a local-only branch. Scope is `Jesher/` plus this task document. The diary's license identifier
is redacted for publication; all numerical/test evidence remains intact.
The remaining 33 MATLAB and 36 Simulink cases, four-person listening and final
review/sign-off are still outstanding. This publication is a partial handoff.

**Report update, 31 October:** the [editable report section](../Jesher/report/metrics_playback_draft.md)
now contains the measured three-case results, six captioned tables, three
captioned MATLAB figures, alignment/analysis settings, WAV results and the
user-reported listening observation. A [seven-page PDF](../Jesher/report/output/pdf/Jesher_Current_MATLAB_Results.pdf)
and [browser view](../Jesher/report/current_matlab_results.html) present the
same content. Independent recomputation and exact archive/member checks are
recorded in [report verification](../Jesher/report/report_verification.json).
JE-07 remains partial until the missing cases, platform comparison and full
listening evidence are available.

**MATLAB execution update, 31 October:** the later successful diary supersedes
the earlier missing-toolbox run. All 19 MATLAB tests passed. The completed
[three-control run](../Jesher/results/matlab_run_20261030_170138_859/run_summary.json)
records MATLAB R2026b Update 1, Signal Processing Toolbox, DSP System Toolbox and
Simulink. Metrics, figures, exports and a byte-verified partial ZIP exist.
The user subsequently reported all three audios audible and clear; see
[initial observation](../Jesher/listening/initial_observation.md). The historical
automated run flags remain unchanged. The full matrix needs 33 more MATLAB cases
and all 36 Simulink cases; full listening, review and sign-off remain open.

- **JE-01, in progress / JE-03, complete:** schema, AA03 alignment and numerical sanity tests are implemented and executed in MATLAB. Quantizer metadata and remaining-route timing evidence are still needed for the broader handoff.
- **JE-02 / JE-04 / JE-05, in progress:** three MATLAB controls have actual metrics/export/archive evidence. Combined reduced-bit cases in both platforms, the full matrix, full playback/setup checks and a final package are still missing.
- **JE-06 / JE-07, in progress:** initial three-case figures, metrics and one listener's clear/audible observation exist. Four-person observations, reduced-bit/combined-case analysis, full results and report acceptance remain open.
- **JE-08 through JE-10:** quantizer/storage review, corrections/rehearsal, reviewer acceptance and final sign-off remain open. All original tasks are retained; only JE-03 is marked complete on current evidence.

**Review findings / receiver acceptance:** pending; add task ID, finding, evidence, owner, and resolution date here.
**Final sign-off:** pending; add date, source/result commit, reviewer, and any remaining limitations.
