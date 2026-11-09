# Run the combined project

Use MATLAB R2026b with Signal Processing Toolbox, Simulink and DSP System Toolbox. This is the release actually tested for the combined pipeline. Abdulrahman's sampling models and the new quantization model use the R2026a saved format. The latter is exported with [MathWorks' previous-version export](https://www.mathworks.com/help/simulink/slref/simulink.exporttoversion.html); an R2026a execution test has not been performed for the new combined pipeline. Keep the folder structure after downloading the repository.

## First run: the whole experiment

Set MATLAB's Current Folder to the repository root, where `RUN_PROJECT.m` is located, then run:

```matlab
RUN_PROJECT
```

This executes Abdulrahman's MATLAB sampling scripts and all four of his actual Simulink sampling models. It then quantizes their exact output arrays and runs Jesher's evaluator. It produces 36 MATLAB cases and 36 Simulink cases. Every case gets a correctly rated WAV file and both processing-array and exported-WAV NMSE/SNR. The original recording is retained. This takes several minutes.

`Results/Integrated/latest_run.txt` identifies the most recent successful run. Its folder contains `metrics.csv`, `storage_quality.csv`, `integration_comparison.csv`, report figures, and a local audio ZIP with the original and all 72 processed WAVs. The ZIP name says `UNREVIEWED` because human listening and final team approval are separate from successful computation.

## In front of the instructor: one selected case

1. Open `PROJECT_SETTINGS.m`. Choose the sampling rate, effective bit depth, filter mode and platform.
2. Run `RUN_DEMO` from the repository root. It uses the actual sampling handoff prepared by `RUN_PROJECT`, runs the selected quantizer, exports the WAV, evaluates it and shows the waveform, FFT, spectrogram and quantization error plots. It opens the quantization model for a Simulink case.
3. Run `PLAY_PROJECT_AUDIO` to hear the original followed by that output. The script uses the actual sample rate for each file and does not normalize playback levels. To listen through every output, set `settings.playAllCases = true` in `PROJECT_SETTINGS.m`; the full sequence takes about 25 minutes and can be stopped with Ctrl+C.
4. To demonstrate sampling itself live, run `Compare_All_Sampling` from the repository root after `RUN_PROJECT`; open the four `SamplingModel_*Abdulrahman.slx` designs in `Simulink` to inspect their blocks. This comparison runs all four sampling models again.

For a new source recording, regenerate sampling and all downstream results with `RUN_PROJECT`. The current contract and validation deliberately require the agreed mono 44.1 kHz PCM16 source at `Audios/SpeechMusic.wav`.

## Which code belongs to which stage?

| Stage | Files to explain | What happens |
| --- | --- | --- |
| Abdulrahman: sampling | `Matlab/Sampling_Abdulrahman.m`, `Sampling_OtherRates.m`, `Prepare_Sampling_Handoff.m`, `Compare_All_Sampling.m`; four sampling models in `Simulink` | Reduce the sampling rate with or without an anti-aliasing LPF. Save exact arrays, rates, timing and filter metadata. |
| Khaled: quantization | `Matlab/Uniform_Quantize.m`, `Quantize_Simulink.m`, `Quantize_All_Cases.m`; `Simulink/Quantization_Khaled.slx` | Round the sampling outputs onto 8-, 4- or 2-bit amplitude levels. Keep rate and timing. Save the isolated input-minus-quantized error. The 16-bit setting bypasses this stage. |
| Jesher: evaluation/export | `Jesher/matlab/Run_Jesher_Evaluation.m` and `+jesher` helpers | Reconstruct to the original time grid, compute NMSE/SNR, write and read back PCM16 WAVs, record file metadata and verify the ZIP. |
| Combined results | `Matlab/Make_Integrated_Results.m`, `CHECK_INTEGRATION.m` | Generate storage/quality tables and report plots; check source inputs, quantizer boundaries, timing, all files and platform differences. |

The quantization implementation was completed with assistant help at Jesher's request. Task ownership labels describe project responsibilities; they do not claim independent authorship or peer approval by Khaled.

## Two errors and two kinds of bit depth

Quantization error is `samplingInput - quantizedOutput`, at the processed rate. Total reconstruction error is `original - reconstructedProcessedOutput`, at 44.1 kHz. The two errors measure different things. `quantization_summary.csv` reports the first; `metrics.csv` reports total quality before and after WAV export.

An effective 2-bit signal has four possible amplitude levels. Its exported file still uses a supported 16-bit WAV carrier. `storage_quality.csv` reports theoretical packed low-bit payload and measured PCM16 file bytes separately. No packed low-bit file is produced or claimed.

## Verification and listening

`CHECK_INTEGRATION(evaluationFolder,handoffFile)` checks all 72 cases and 36 pairs. `Matlab/Check_Quantizer.m` checks explicit expected values at zero, exact half-step ties, endpoints and out-of-range inputs in both platforms. All errors use the fixed original amplitude scale, without per-case normalization or an optimized time shift.

At non-integer rates, the sampling models can have tiny interpolation differences. A difference at an exact quantizer half-step can produce adjacent output levels. `integration_comparison.csv` checks this explanation against the actual sampling inputs rather than hiding it behind a large tolerance. Jesher's original `platform_comparison.csv` retains its stricter generic result; use the integration comparison for the documented resolution.

The code cannot provide human listening observations, microphone-provenance confirmation, Q&A rehearsal or final team sign-off. Record those actions when actually done. No listening observation for the new outputs is inferred from an earlier audio check.

## Earlier independent demo

`Jesher/Demo` remains available as an earlier self-contained demonstration. The combined workflow above uses Abdulrahman's actual outputs instead. Use the newest successful `Results/Integrated` tables and matching report for this integrated experiment; keep older demo tables identified by their own provenance.

Generated WAV/MAT/ZIP files remain local under the user's publication preference. They can be regenerated from the tracked source recording and scripts.
