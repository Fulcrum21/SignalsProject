# CCEN 302 Signals Project

**Audio Signal Acquisition, Processing, and Quality Evaluation**

Course: Signals and Communications Systems (CCEN 302). This project studies sampling, aliasing, quantization, audio quality, and storage using MATLAB and Simulink.

[Project brief](CCEN%20302%20Project-3.pdf) | [Team progress](#team-progress) | [Schedule](#schedule) | [Shared experiment contract](#shared-experiment-contract) | [Requirement coverage](#requirement-coverage) | [Update instructions](#how-to-update-your-progress)

## Team progress

Each person owns one editable document. Open a teammate's document to see their current checkboxes, evidence, blockers, and next action. Completed tasks stay in the document to preserve credit; this table does not duplicate their live status.

| Owner | Task document | Responsibility | Reviewer |
| --- | --- | --- | --- |
| Yazan | [Yazan's tasks](team/Yazan.md) | Existing baseline work, baseline Simulink, project/report integration | Abdulrahman |
| Abdulrahman | [Abdulrahman's tasks](team/Abdulrahman.md) | Sampling, anti-aliasing, rate conversion, and alignment | Yazan |
| Khaled | [Khaled's tasks](team/Khaled.md) | Quantization, quantization error, and storage | Jesher |
| Jesher | [Jesher's tasks](team/Jesher.md) | Metrics, exports/playback, and listening evaluation | Khaled |

Yazan's existing MATLAB analysis, FFT parity correction, audio additions, baseline Simulink model, and folder organization are acknowledged as completed implementation tasks in his document. Execution checks and scientific validation are separate tasks.

**Working agreement:** update your own document after a meaningful change and by 8:00 PM on days you work. Publish blockers as soon as they appear. Keep a blocked task unchecked, name the person/input needed, and state what you can continue independently. Do not silently change another person's checklist or mark a review passed on their behalf.

## Schedule

All dates are in **2026**. All task deadlines are **8:00 PM Asia/Dubai**, unless an instructor's confirmed submission time is earlier.

**Requested planning assumption: submission on 11 November; complete project by 4 November, one week early.** The supplied PDF instead says 5 November at 6:00 PM. Yazan must confirm the instructor's current deadline by 25 October and record the evidence in YA-06. Until confirmed, retain the earlier official deadline for submission safety. The 4 November finish target remains in place either way; a full contingency week exists only if 11 November is confirmed.

| Date | Milestone and acceptance condition |
| --- | --- |
| 25 October | Shared inputs/settings accepted; recording provenance and deadline checked; Yazan checks everyone's repository write access and lists software requirements. |
| 26 October | Abdulrahman supplies one reduced-rate case, Khaled one reduced-bit-depth case, and Yazan the verified baseline/reference. Each owner documents how to run their part. |
| 27 October | One complete case works in MATLAB and Simulink: baseline -> filtering/rate conversion -> quantization -> aligned metrics -> WAV export/playback. Yazan coordinates; every owner supplies evidence. |
| 29 October | Sampling and quantization components cover all agreed settings in both platforms, ready to combine. |
| 30 October | All 36 primary cases per platform exist with metadata; implementations cover the complete matrix. |
| 31 October | Jesher supplies full metrics and WAV size/container metadata by noon; processed-signal plots, listening comparisons, storage tables, and baseline/sampling report sections are ready by 8:00 PM. |
| 1 November | Every report section is ready; Yazan adds the executive summary, overall methods, conclusions, and references and assembles the first complete report. |
| 2 November | Clean-folder project run and paired technical review completed; each finding has an owner and a fix date. |
| 3 November | Corrections completed; whole-team demonstration and Q&A rehearsal passed. |
| 4 November | Section owners sign off by 6:00 PM; Yazan finishes the final PDF/source/audio package inspection by 8:00 PM. No required implementation or report writing remains. |
| 5-10 November | Contingency and submission checks only if the 11 November assumption is confirmed. |

The 29 October component handoff precedes the 30 October combination milestone, which precedes the 31 October evaluation milestone. This avoids expecting Jesher to finish evaluation before the other components arrive.

## Shared experiment contract

These are the working defaults so the team can start consistently. Acknowledge them in each personal document by 25 October. Yazan records any agreed change here before the team regenerates results. These are planning specifications, not completed experiments.

### Input and case matrix

- Primary input: `Audios/SpeechMusic.wav`, already selected by the MATLAB script and saved Simulink source. Its header reports mono, 44,100 Hz, 16-bit PCM, 882,005 samples, about 20.000113 seconds.
- Yazan must confirm microphone-acquisition provenance. If that cannot be established, select a compliant microphone recording and change this contract before final experiments. Existing supplemental tones demonstrate known-frequency behavior; they do not replace the required real recording.
- Keep the original sample amplitudes. Do not independently normalize every processed case, since this changes the quality comparison.
- Rate set: **44,100; 22,050; 11,025; 8,000; 4,000 Hz**.
- Effective bit-depth set: **16, 8, 4, 2 bits**.
- At 44,100 Hz: one `native` path for each bit depth, including the unchanged 16-bit reference.
- At each lower rate: `lpf` and `none` anti-aliasing paths, each at all four bit depths.
- Coverage: **4 native cases + 4 lower rates x 2 paths x 4 bit depths = 36 cases per platform**, or **72 MATLAB/Simulink result rows** for the primary recording.
- Processing order for combined cases: original input -> anti-aliasing choice/rate reduction -> quantization. Include sampling-only 16-bit cases and native-rate quantization-only cases as controls.
- Supplemental known-frequency checks use the existing sine/square recordings. Yazan should not use `Music.wav` alone as the required 20-second baseline: it is about 13.106576 seconds.

### Handoffs and comparison rules

| Item | Owner and rule |
| --- | --- |
| Baseline | Yazan supplies the selected recording, original sample rate, duration, channel policy, and agreed waveform/spectrum/spectrogram settings. |
| Sampling output | Abdulrahman supplies samples as a mono column vector, actual rate, filter mode/settings, actual output length, and timing/delay metadata. Document the unfiltered method so filtering is not applied accidentally. |
| Quantization output | Khaled accepts the sampling output without changing its time base. Supply effective bits, range, clipping/rounding convention, error signal, and the same rate/timing metadata. |
| Combined-case generation | Abdulrahman supplies both platform sampling outputs by 29 October. Khaled applies the agreed bit depths and hands all combined signals to Jesher by 30 October. Owners resolve integration issues together. |
| Alignment | Abdulrahman defines the common comparison time base, reconstruction method, known-delay compensation, overlap/edge policy, and reference interval; Jesher reviews it by 27 October. Do not subtract arrays at different rates or silently truncate unrelated samples. |
| Metrics | Jesher records NMSE and SNR against the aligned original baseline for every case. Document zero-error and zero-reference-energy handling; do not hide an invalid result. |
| Plot comparability | Owners use consistent units, axis labels, window/FFT settings, and amplitude/power conventions. A full-record FFT and a 2,048-sample frame FFT are not numerically identical analyses; match methods or explain the difference. |
| Export | Jesher exports at the actual processed rate. Default WAV carrier is supported 16-bit PCM; log its actual container width separately from effective quantizer bits. A 2-bit quantized signal inside a 16-bit WAV is not a 2-bit-per-sample file. Check and explain any export/re-import error. |
| Storage | Khaled reports theoretical payload based on rate, duration, channels, and effective bits, plus actual exported file size/container width from Jesher. Explain headers, packing, and unused carrier precision. |
| Cross-platform comparison | All owners use the same source, case ID/settings, and comparison interval. Record numerical differences/tolerances and explain differences in processing or spectral estimates. |

Case names identify source, rate, effective bits, filter choice, and platform, for example `speechmusic_fs22050_b08_lpf_matlab`. Use `native`, `lpf`, or `none`; use `matlab` or `simulink`. This is a naming contract, not a requirement to create one source file per case.

Jesher's final results table must identify: case ID, platform, source, sampling rate, effective bits, filter mode, sample count/duration, comparison interval, NMSE, SNR in dB, WAV filename, WAV container bits, and file bytes. Link storage/listening results by case ID. Supporting filter, quantizer, and alignment settings must be traceable from the report or case metadata.

### Evidence and task status

- `[x]` = the exact task described is complete, with a commit/file/result reference.
- `[ ]` = open. Prefix the note with **In progress**, **Blocked**, or **Ready for review** when useful.
- An implementation can be complete while a separate validation task remains open.
- A result is verified only after it was run and checked. A model file or screenshot alone does not establish full experiment correctness.
- Keep completed checkboxes and their evidence. Record a dated correction if later checks find a problem.
- For each handoff, identify the artifact, settings/cases covered, run instructions, limitations, and receiver. The receiver records acceptance or the specific problem in their own document.

## Requirement coverage

This audit maps every substantive requirement in the supplied brief to an owner and a review/output. Check the linked tasks for live progress.

| Requirement | Accountable tasks | Required evidence |
| --- | --- | --- |
| 20-second microphone recording, at least 44.1 kHz and 16-bit | [Yazan YA-06 / YA-08](team/Yazan.md) | Recording metadata, acquisition/provenance note, original WAV |
| Original waveform, FFT magnitude, spectrogram | [Yazan YA-01 / YA-07 / YA-08](team/Yazan.md) | Labeled MATLAB and Simulink results |
| Rate reduction with/without anti-aliasing; folding/overlap | [Abdulrahman AA-02 / AA-04 / AA-05](team/Abdulrahman.md) | Every selected rate, real-audio comparison, known-tone alias evidence |
| Uniform quantization and error waveform/distribution | [Khaled KH-02 / KH-03 / KH-05](team/Khaled.md) | Every selected bit depth, documented range/clipping, error plots |
| NMSE/SNR across all rate/bit-depth cases | [Jesher JE-02 / JE-04](team/Jesher.md) and [Abdulrahman AA-03](team/Abdulrahman.md) | All 72 rows, alignment record, sanity checks |
| Processed waveforms, FFTs, spectrograms | [Abdulrahman AA-05](team/Abdulrahman.md), [Khaled KH-05](team/Khaled.md), [Jesher JE-06](team/Jesher.md) | Sampling, quantization, and combined-case comparisons |
| Processed WAV export and speaker playback | [Jesher JE-02 / JE-05](team/Jesher.md) | Correct-rate WAVs, playback check, audio ZIP |
| Perception correlated with measured quality | [Jesher JE-06](team/Jesher.md), all listeners | Case-linked listening notes and NMSE/SNR |
| Storage-quality compromise | [Khaled KH-06](team/Khaled.md) | Theoretical payload and actual files, linked to quality |
| Repeat experiment in Simulink; compare both platforms | All implementation tasks; [Yazan YA-12](team/Yazan.md) | Matching settings, source models, results and discussion |
| Commented modular source and reproducible figures | Each owner; [Yazan YA-12](team/Yazan.md) | Run instructions, software list, clean-folder run |
| PDF: executive summary, methods, plots, metrics tables, theory/discussion | [Yazan YA-10 / YA-11](team/Yazan.md), each report task | Complete report including Nyquist and qualified 6 dB/bit discussion |
| Original and processed audio ZIP | [Jesher JE-05](team/Jesher.md), [Yazan YA-14](team/Yazan.md) | Manifest matching exported files to cases |
| In-class demo and Q&A | Every owner's rehearsal task | Everyone explains the full pipeline and a teammate's section |
| Blackboard source/PDF submission; laptop audio check | [Yazan YA-06 / YA-14](team/Yazan.md), all sign-offs | Confirmed deadline, final checklist, submission receipt |

## How to update your progress

The four documents are ordinary Markdown files: edit locally in a text editor or on GitHub. Each teammate edits their own file; everyone can read all four after changes are pushed. This is the team progress view, so no separate status file must be kept in sync.

For a local update, start from a clean checkout in the repository root:

1. Switch to `main` and get the latest shared changes: `git switch main`, then `git pull --ff-only origin main`.
2. Edit your document. Tick completed tasks without deleting them; add dated evidence and your next action/blockers.
3. Stage only your document: `git add -- team/Yazan.md` (replace the name with yours).
4. Check `git diff --cached --stat` and `git diff --cached`; ensure you are committing only the intended update.
5. Commit, for example `git commit -m "Update Yazan task progress"`, then `git push origin main`.

If another teammate pushed first and your push is rejected, use `git pull --rebase origin main`, then push again. If a conflict appears, stop and coordinate with the affected owner; preserve both sets of work. Use `git rebase --abort` if you cannot resolve it safely. Do not force-push shared `main`.

An uncommitted edit is visible only on your computer. After a successful push, teammates can read it on GitHub or pull it locally. Each person needs repository write access; Yazan checks this by 25 October. If shared-main writes are unavailable, publish a branch and open a pull request instead.

For source changes, coordinate shared entry points and commit only files you own. Simulink `.slx` files are binary: use separate owner models and have Yazan integrate copies; do not concurrently edit the same model.

## Current implementation and checks

Repository inspected at commit [ad8cc0d](https://github.com/Fulcrum21/SignalsProject/commit/ad8cc0d9711f4de8d5031e72e389eab35237e4e6) on 24 October 2026.

| Existing artifact | What is established |
| --- | --- |
| [MATLAB baseline script](Matlab/FirstPart_AudioFreqAnalysis.m) | Original waveform, single-sided linear/dB FFT, spectrogram implemented; parity condition corrected to `mod(numSamples,2)==0`. |
| [Audio collection](Audios/) | Eight WAVs, all mono 44.1 kHz / 16-bit PCM; durations vary. |
| [Simulink baseline model](Simulink/FirstPart_TimeFreqSimulink.slx) | Saved time scope, normalized FFT/magnitude chain, and spectrogram are present. Cross-machine execution/comparison remains to be checked. |

Known checks for Yazan, not reasons to erase completed implementation credit:

- The saved Simulink source uses an absolute path on Yazan's computer. Replace it with a portable project input and verify from another teammate's checkout.
- The MATLAB script uses a full-record FFT; the saved Simulink FFT uses 2,048-sample input frames. Comparisons must match the analysis or explain the distinction.
- The default primary file has an odd sample count; validate both odd/even FFT scaling using existing inputs. Check finite dB handling at zero magnitude and spectrogram units.
- MATLAB startup was attempted during this audit but failed before executing the script with a filesystem startup error. No MATLAB or Simulink run is certified by this documentation audit. Each owner records actual execution evidence.

### Run existing work

Use MATLAB with Signal Processing Toolbox for the baseline script. The saved model references DSP System Toolbox blocks and was saved with MATLAB/Simulink R2026a; Yazan must record the team's required products and release compatibility after a successful run.

From the repository root in MATLAB:

```matlab
cd Matlab
FirstPart_AudioFreqAnalysis
```

This working folder is required by the current `../Audios/SpeechMusic.wav` input path. The script is analysis of an existing file, not a microphone-recording or playback routine.

Open `Simulink/FirstPart_TimeFreqSimulink.slx` for the baseline model. Complete YA-07's portable-input check before expecting it to run on another machine.

## Final submission

Keep the original brief unchanged. Final outputs must include the report PDF, commented MATLAB and Simulink source, and a ZIP of original/processed WAVs. Prepare the laptop audio check and in-class demonstration. The brief specifies report/source submission through Blackboard, not email.

Before sign-off, the team must have no unexplained missing cases, unresolved essential review findings, broken required paths, or unverified required outputs. Yazan assembles and checks the submission package; all four owners verify their own contributions and the integrated demonstration. Record the actual submission receipt after uploading to Blackboard; no deadline or receipt is assumed from a Git push.

Assessment: baseline 15%, sampling 15%, quantization 15%, metrics 15%, playback/perception 10%, report/documentation 10%, Q&A 20%.
