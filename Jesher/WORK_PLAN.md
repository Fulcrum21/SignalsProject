# Jesher's local work plan

Prepared 30 October 2026 after reading the entire four-page project brief and
the current repository. The brief states **5 November 2026, 6:00 PM**; retain
the earlier official deadline until Yazan records an instructor-confirmed change.
The team targets 4 November; the 72-case metrics and WAV metadata are due
31 October at noon Dubai time.

| Task | What is implemented here | What still establishes completion |
| --- | --- | --- |
| JE-01: inputs and contract | 72-ID matrix, fixed metadata schema, handoff adapter, documented run commands | Receive Khaled's quantizer convention and remaining timing settings |
| JE-02: first combined case | Evaluate/export/re-import exact handed-off arrays; AA03 alignment implemented | Actual reduced-rate/reduced-bit case in both platforms, MATLAB run, speaker check |
| JE-03: metric correctness | Executed Python sanity tests; corresponding MATLAB tests authored | Run MATLAB tests and retain evidence before full evaluation |
| JE-04: full result table | Coverage and platform comparison code; 3 existing controls audited | Obtain and run all 72 real cases under documented common policies |
| JE-05: audio package | PCM16 export/re-import and byte-verified archive code; existing WAV headers/bytes audited | Full MATLAB exports, actual playback on laptop, matching full archive |
| JE-06: perception and plots | Common-grid plots; four-listener protocol and blank forms | Representative combined arrays and genuine notes from all four teammates |
| JE-07: report section | Definitions, methods, caveats, and insertion checklist drafted | Verified full tables/figures and actual listening findings |
| JE-08: Khaled review | Storage/export fields defined; review questions below | Inspect actual quantizer/error/storage implementation and close findings |
| JE-09: corrections/rehearsal | Reproducible entry point and explicit pending evidence | Fix review findings, regenerate affected results, rehearse explanations |
| JE-10: sign-off | Completeness gating and archive checks implemented | Accepted full evidence, reviewer, actual playback and final package |

## Status update, 31 October

All 19 MATLAB tests passed in the successful 30 October session. The completed
three-control run contains metrics, figures, verified WAV exports and a
byte-verified partial audio archive. JE-03 is complete; the original task table
above describes the implementation plan and should be read with this update.
The user reports all three files audible and clear; setup details and other
listeners are not yet documented. Remaining inputs: 33 MATLAB cases and all
36 Simulink cases. The earlier missing-toolbox issue is resolved.

## Do next, in order

1. Preserve `results/matlab_run_20261030_170138_859` and the successful
   `results/matlab_session_20261030_170012.txt` diary. The first run and tests
   are complete; continue with the remaining handoffs rather than repeating
   an unchanged three-case evaluation.
2. Receive Khaled's reduced-bit/combined MAT arrays using `inputs/README.md`.
   A WAV alone adds carrier conversion error; request exact arrays for primary
   metrics. Require actual platform IDs and documented quantizer settings.
3. For the current Simulink prototype, run Abdulrahman's documented three-step
   flow. Save the already aligned `simNoFilterAligned`/`simFilteredAligned`
   arrays with the correct `simulink` metadata. Do not remove the FIR delay twice.
4. Receive the other sampling rates and their explicitly documented alignment
   policy from Abdulrahman. The existing AA03 policy authorizes only native and
   22,050 Hz. `full_record_resample_v1` is an implementation option, not evidence
   that the other routes have already been approved or validated.
5. Run with `RequireComplete=true`; inspect platform discrepancies. Give Khaled
   `metrics.csv` and `audio_package/manifest.csv` for storage analysis. Give
   Yazan the run evidence, figures, report section, and archive reference.
6. Play every exported file through the intended laptop speakers, then collect
   representative listening notes from all four people under the fixed protocol.
   Enter real dates, setup, observations, and matching case scores.
7. Review quantization/storage with Khaled; resolve findings and rerun affected
   cases. Finish report discussion and rehearse the live demo before sign-off.

## Missing inputs and owners

- **Khaled:** no quantizer code/convention or reduced-bit/combined handoff is
  present in upstream `be17af9`. Needed: fixed range/level mapping, boundary and
  clipping behavior, bit depths, processing arrays and provenance for both platforms.
- **Abdulrahman:** remaining rates/routes and timing validation, plus persisted
  Simulink samples. The current saved model and comparison evidence do not provide
  those arrays to this evaluator.
- **Yazan:** recording microphone provenance and deadline confirmation remain
  open in his task document. Header checks cannot establish microphone provenance.
- **Jesher and all listeners:** actual MATLAB execution, laptop audibility and
  listening observations cannot be substituted by Python or code inspection.

No messages have been sent to teammates. This document identifies the necessary
handoffs for coordination by the team.

## Review Khaled's work when it arrives

Check that effective bits match the number of available levels; fixed range,
endpoints, zero, rounding and clipping are consistent across platforms; native
16-bit reference bypasses further changes; quantization preserves actual sample
times; error plots use the same definition and units; theoretical payload uses
effective bits while measured bytes use the true WAV container; storage rows
join to the exact case IDs and quality representation in the metrics table.
Record findings and resolutions in `team/Jesher.md`; do not mark Khaled's own
checklist or acceptance on his behalf.
