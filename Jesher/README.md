# Jesher: quality metrics, audio exports, and listening

This folder contains Jesher's contribution. It reads existing team artifacts and
writes new results here; it does not run or overwrite teammates' scripts/models.
The repository was downloaded from `Fulcrum21/SignalsProject`, upstream commit
`be17af9179ecc91a2e8c2a50f606d82070afe503`, on 30 October 2026.

## What is ready locally

- Modular MATLAB evaluation, alignment, WAV export/re-import, archive verification,
  case coverage, platform comparison, and comparable plots.
- An explicit playback helper and blank forms for all four listeners.
- An independent Python audit with executed tests and numerical checks of the
  existing original and two sampling controls.
- A methods/report draft and a concrete [work plan](WORK_PLAN.md).

**31 October update:** the later MATLAB session passed all 19 tests and produced
a completed three-control evaluation on 30 October. Its summary records Signal
Processing Toolbox, DSP System Toolbox and Simulink with MATLAB R2026b Update 1.
This supersedes the earlier missing-toolbox run. The full matrix remains
incomplete. The user reports these three files were audible and clear; see
[initial observation](listening/initial_observation.md). Full playback/setup
checks and the other listeners remain pending. Python results are labeled separately.

The existing handoff provides only the two 22,050 Hz MATLAB sampling controls;
the unchanged source is the third available control. The remaining **69 of 72**
matrix entries need actual processing handoffs. No missing signals or Simulink
outputs have been copied or invented. `b16` sampling controls contain double
processing arrays without an explicit quantization stage.

## Run your MATLAB contribution

Use MATLAB with Signal Processing Toolbox. R2026a matches the producer's recorded
release; other releases have not been tested. The saved team Simulink models
need their own licensed products, but evaluating saved arrays does not require
starting Simulink. These commands start in the repository root:

```matlab
addpath(fullfile(pwd,'Jesher','matlab'));
testResults = runtests(fullfile(pwd,'Jesher','matlab','tests'));
assert(all([testResults.Passed]), 'Resolve failed or skipped tests before evaluation.');
summary = Run_Jesher_Evaluation();
```

The default run loads the unchanged source, Abdulrahman's exact AA02 MAT arrays,
and any additional `cases` MAT handoffs in `Jesher/inputs/`. It applies the
documented AA03 alignment for the currently verified 22.05 kHz route. It does
not generate Khaled's quantizer outputs or execute Simulink.

New outputs go to a unique `Jesher/results/matlab_run_<Dubai timestamp>/`:

| Output | Purpose |
| --- | --- |
| `metrics.csv` | Available cases, interval, NMSE/SNR, stage, provenance, WAV metadata, and separate exported-audio scores |
| `case_coverage.csv` | All 72 expected IDs with explicit missing/available status |
| `platform_comparison.csv` | 36 pairs; missing counterparts remain missing |
| `figures/` | Matched reference-grid waveform, full-record FFT, and spectrogram views |
| `audio_package/manifest.csv` | Original and exported file rates/counts/widths/bytes and conversion error |
| `audio_partial_NOT_FINAL.zip` | Original plus available exports and coverage; never labeled final |
| `run_summary.json`, `evaluation.mat` | Actual MATLAB release, dependencies, inputs, run time, and completion flags |
| `input_snapshot/` | Copies of supplied producer MAT artifacts; exact evaluated case arrays are also saved in `evaluation.mat` |

The ZIP is unpacked into `archive_verification/` and each audio member is checked
byte for byte against its staging file. Original audio is copied unchanged.
Results use new folders to avoid mixing old and new runs. No automatic speaker
playback occurs. A complete matrix produces `audio_all_cases_UNREVIEWED.zip`;
human playback, technical review, and final sign-off still remain separate.

For a fast run without figures:

```matlab
summary = Run_Jesher_Evaluation('MakePlots',false);
```

After receiving every handoff, make completeness mandatory:

```matlab
summary = Run_Jesher_Evaluation('RequireComplete',true);
```

This rejects a missing matrix before writing outputs. Additional handoffs must
follow [inputs/README.md](inputs/README.md). The loader rejects duplicate IDs
among supplied handoffs and metadata mismatches. Supplied cases replace matching
built-in fallback controls. Sampling descriptions must retain the exact filter
settings/coefficient artifact; quantizer descriptions must identify range, levels,
rounding, clipping, and any control bypass.

## Checks you can run on this computer

Python 3.13, NumPy 2.3.5, and SciPy 1.16.3 were available for the local audit:

```powershell
python -X utf8 -m unittest discover -s Jesher/validation -p 'test_*.py' -v
python -X utf8 Jesher/validation/audit_existing.py
```

If those packages are absent, install `Jesher/validation/requirements.txt` into
your chosen Python environment. The audit reads the tracked artifacts without
changing them. Its outputs are in [results/local_audit](results/local_audit).
The JSON includes input SHA-256 hashes, upstream commit, software versions,
checks, limitations, and test outcomes. The audit is deliberately scoped to the
existing handoff and does not treat new teammate cases as evaluated.

The executed audit passed 20 tests and 20 artifact checks. Its two
sampling controls gave the following independent numerical cross-checks:

| Case | NMSE before WAV conversion | SNR (dB) |
| --- | ---: | ---: |
| `speechmusic_fs22050_b16_none_matlab` | 0.00122019794119 | 29.1356971 |
| `speechmusic_fs22050_b16_lpf_matlab` | 0.000807222473989 | 30.9300676 |

These use the full original interval and the producer's saved FIR coefficients
for reconstruction. Parity with MATLAB's default reconstruction is inferred from
the shared FIR design and still requires the actual MATLAB run. Python execution
does not certify MATLAB/Simulink execution or the whole experiment.

MISS_HIT 0.9.44 also parsed/linted all 12 MATLAB source/test files successfully.
[Static-check evidence](results/local_audit/matlab_static_check.json) records the
command and checked source hashes. This checks syntax, not MATLAB execution.
All 19 MATLAB test methods passed in the later run. See
`results/matlab_session_20261030_170012.txt`. The earlier
`results/matlab_first_run.log` is retained as historical failed-run evidence.

## Interpretation rules

- Compare samples on the same physical time grid. AA03 reconstructs 22,050 Hz
  samples at 44,100 Hz and removes just the one unmatched final endpoint.
- Preserve amplitudes. Do not fit gain, search for an optimal lag, or normalize
  individual cases. Already compensated arrays must not be shifted again.
- For positive energies, `SNR_dB = -10*log10(NMSE)`. Unchanged nonzero input gives
  `0, +Inf`; silent reference/output gives `NaN, NaN`; zero reference with error
  gives `+Inf, -Inf`. CSV status fields explain these values.
- Metrics on exact processing arrays and re-imported WAVs are separate columns.
  A 2-bit quantizer output in a 16-bit WAV still has a 16-bit container.
- The exporter rejects values outside `[-1, 1-1/32768]` rather than silently
  clipping or normalizing. Resolve any producer overshoot with its owner.
- Platform sample tolerance is provisionally `1e-10 + 1e-8*max(abs(matlabSamples))`,
  with absolute NMSE tolerance `1e-10` and SNR tolerance `1e-6` dB. These are
  proposed review thresholds, not already accepted scientific tolerances.

Reconstruction uses explicit `resample(...,10,5)` settings and delay compensation
per [MathWorks](https://www.mathworks.com/help/signal/ref/resample.html).
The independent check uses a saved-coefficient polyphase calculation documented
by [SciPy](https://docs.scipy.org/doc/scipy/reference/generated/scipy.signal.resample_poly.html).
WAV conversion follows [audiowrite](https://www.mathworks.com/help/matlab/ref/audiowrite.html).

## Listening, report, and publishing

Follow [listening/PROTOCOL.md](listening/PROTOCOL.md), copy the blank forms, then
record what each person actually heard. Use `Play_Jesher_Case` explicitly at the
header rate and one fixed playback gain. No observation has been prefilled.
Finish [report/metrics_playback_draft.md](report/metrics_playback_draft.md) using
the verified case tables, actual listening evidence, and Khaled's review.

Publication branch: `codex/jesher-quality-evaluation`. Implementation files are
contained in `Jesher/`; only Jesher's own progress document is updated outside it.
The reviewed three-control snapshot's metrics, manifests, metadata and figures
are included under `results/matlab_run_20261030_170138_859/`. At the user's
direction, all newly generated WAVs, ZIP archives, MAT arrays and producer
snapshots stay local. The full local evidence commit is retained on the
local-only branch `codex/jesher-local-full-evidence`, which is not published.
The run's redundant `archive_verification/` extraction also stays local.
Future generated MATLAB runs and private handoff MATs remain ignored by default.
See [PUBLICATION.md](PUBLICATION.md) for the exact sharing scope.

The published MATLAB session diary retains all test results and commands, with
the MATLAB license number redacted. Its unredacted backup remains in the ignored
local `results/private_originals/` directory. Report verification hashes refer
to the published redacted diary. Shared `main` and teammates' files are outside
this contribution's change scope.
