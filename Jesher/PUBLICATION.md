# Publication scope

The user requested code and reports on GitHub and explicitly chose to keep
audio files, audio ZIPs and MAT sample arrays local on 31 October 2026.

## Included in this contribution

- Jesher's MATLAB evaluation/alignment/export/playback/plotting implementation.
- MATLAB tests and independent Python audit source/tests.
- The current measured report in Markdown, HTML and PDF, with captioned figures.
- Plain result tables, case coverage, audio manifests, run metadata and test logs.
- Listening protocol/forms and the user's actual initial observation.
- Jesher's own task document; only JE-03 is marked complete.

## Kept local

New processed/original-copy WAVs, audio ZIPs, `evaluation.mat`, input snapshot
MATs, temporary renders, redundant archive extractions and the unredacted diary
are not included in the publication commit or its new history. A full-evidence
commit is preserved only on the local branch `codex/jesher-local-full-evidence`.
That branch must not be pushed without separate authorization for the payloads.

The shared repository already contains baseline audio and Abdulrahman's original
sampling MAT handoff. Those existing upstream files are unchanged by this work.

Report references to audio/MAT artifacts identify the owner's saved local run;
they are not download promises. Their filenames, sizes, measurements and hashes
are published for traceability. The report builder needs those local artifacts
to reproduce this exact report. Other teammates can run `Run_Jesher_Evaluation`
to produce their own fresh local result folder from the existing upstream inputs.

The MATLAB session diary's license number is redacted. Its 19 passing test rows
and run output are preserved. Shared `main` is not modified by publishing this
separate contribution branch.
