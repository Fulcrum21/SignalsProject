# MATLAB sampling handoff

**Owner:** Abdulrahman. **Prepared:** 1 November 2026. **Receivers:** Khaled (quantization), Jesher (metrics), Yazan (report integration).

This folder supplies eight sampling-only MATLAB cases from the unchanged `Audios/SpeechMusic.wav`: 22,050, 11,025, 8,000 and 4,000 Hz, each with `none` and `lpf` anti-aliasing choices. The new-rate Simulink cases and comparisons remain Abdulrahman's work. Receiver acceptance and the combined quantization matrix are not claimed.

## Files

- `sampling_all_rates.mat`: `samplingHandoff.original` and eight `samplingHandoff.cases`, with exact double arrays, actual rates, case IDs, conversion ratios, methods, filter coefficients and timing.
- `case_manifest.csv`: one row per case, including sample count/duration, timing, inverse ratio and WAV metadata.
- Eight `speechmusic_fs..._b16_..._matlab.wav` files: mono 16-bit PCM playback copies at the actual rate.
- `waveforms_*.png`, `spectra_*.png`, `spectrograms_*.png`: original/unfiltered/filtered comparisons for all four rates.
- `aliasing_10000_to_1025.png` and `aliasing_summary.csv`: known 10 kHz tone folding to 1,025 Hz after unfiltered reduction to 11.025 kHz, with the filtered residual measured separately.
- `alignment_checks.csv`: the existing 300 Hz recording processed through all eight methods, reconstructed at 44.1 kHz, with measured dominant frequency and diagnostic residual lag.
- `sha256_manifest.csv`: source/code/data/figure identity checksums. Regenerated with the report builder.
- `verification.json`: verified coverage and outstanding scope.
- [Report section](../../../Reports/Abdulrahman_Sampling.md) and [readable PDF](../../../output/pdf/Abdulrahman_Sampling_Report_Draft.pdf).
- [MATLAB run log](../sampling_run_log.txt).

Checksums use `HashMode=raw` for binary files. For text files, `HashMode=text-lf` means convert CRLF line endings to LF before hashing; `HashedBytes` is the length after that conversion. This keeps verification stable across Git checkouts on Windows and other systems. Actual WAV file sizes remain recorded separately in `case_manifest.csv`.

## Run instructions

Use MATLAB R2026a with Signal Processing Toolbox. Earlier releases have not been tested; the figure helpers use the light-theme option. No Simulink run is needed for this package.

1. Set Current Folder to the repository's `Matlab` directory.
2. Run `Prepare_Sampling_Handoff`. It runs the remaining-rate and aliasing scripts, packages the existing AA-02 22.05 kHz result, writes WAV/MAT/CSV outputs, plots comparisons and runs the checks. The AA-02 reference must match the current source.
3. For checks without regenerating the audio/plots, run `Check_Sampling_Handoff`. It rewrites only `alignment_checks.csv` with the repeated known-tone measurements.
4. For figures only, run `Plot_Sampling_Comparisons`.
5. From the repository root, rebuild the editable report/PDF/checksums using `python tools/build_sampling_report.py` in a Python environment with ReportLab, Pillow and pypdf. The Codex bundled runtime provided these for the verified build; installation is not part of these instructions.

To regenerate the original AA-02 case after deliberately changing its input, use `Sampling_Abdulrahman` first. A source change also requires reviewing the reference-specific expected counts in the check script and regenerating all downstream results.

## Load a case

From the repository root:

```matlab
data = load("Results/Abdulrahman/Sampling/sampling_all_rates.mat");
reference = data.samplingHandoff.original.samples;
entry = data.samplingHandoff.cases(6); % 8 kHz, filtered
samples = entry.samples;
Fs = entry.Fs;
```

| Positions | Rate | Order |
| --- | --- | --- |
| 1, 2 | 22,050 Hz | none, lpf |
| 3, 4 | 11,025 Hz | none, lpf |
| 5, 6 | 8,000 Hz | none, lpf |
| 7, 8 | 4,000 Hz | none, lpf |

Find cases by `caseId` or `Fs`/`filterMode` when combining tables. Do not rely on file ordering alone.

## Processing conventions

The 22.05 and 11.025 kHz `none` paths select every second/fourth source sample. The 8 and 4 kHz `none` paths use linear interpolation at uniform target times. They have no dedicated anti-aliasing LPF, but interpolation affects amplitude response. Reproduce that method for a controlled platform comparison; do not describe it as pure integer sample selection.

The `lpf` paths use `resample(x,p,q,10,5)`, then retain the same source-covered output grid as the corresponding unfiltered case. The stored coefficients for p greater than 1 operate at `entry.coefficientFsHz`, the intermediate upsampled rate. They cannot simply be used as an ordinary source-rate FIR Decimation filter. Designed FIR delay is compensated by MATLAB; the saved raw delay is descriptive, not a second shift to apply.

No independent amplitude normalization or reduced-bit quantization is applied. `b16` identifies the source/control. The MAT data retain double-valued processing samples. WAV carriers are 16-bit, with their measured export error in the manifest; use MAT arrays for Khaled's quantization input.

## Comparison grid for Jesher

Quantization should preserve the case's actual sampling rate and timing. From the loaded case:

```matlab
reconstructed = resample(entry.samples, entry.reconstructionP, entry.reconstructionQ);
aligned = reconstructed(1:length(reference));
```

The reference is all 882,005 original samples at 44.1 kHz, t=0 through 20.000090703 s. All current cases have enough reconstructed samples for that interval. No extra delay shift, optimized lag correction, amplitude normalization or error-based edge removal is applied. Interpolation/reconstruction boundary errors remain part of quality degradation. The 8/4 kHz source-covered arrays end at 20.000000000 s; reconstruction supplies the short remaining tail through its finite-filter boundary behavior. Restoring the time grid does not recover removed or aliased information.

Use the same representation for paired measurements. WAV round-trip error is export rounding, not the sampling-stage NMSE/SNR. Do not compare a double-valued MAT signal with a separately rounded WAV and silently attribute all differences to sampling.

## Compatibility with Jesher's branch

Checked on 2 November against `origin/codex/jesher-quality-evaluation` at `13fc434`. A virtual Git merge with this sampling checkpoint was clean. Jesher's branch adds its implementation under `Jesher/` and updates `team/Jesher.md`; it does not overwrite the new sampling scripts or results.

The code interfaces still require integration:

- `Jesher/matlab/+jesher/loadAvailableCases.m` automatically adapts the earlier AA-02 prototype. Explicit external inputs instead require a top-level `cases` struct vector with the fields in `Jesher/inputs/README.md`. This package exposes `samplingHandoff.cases`; it is not yet a drop-in external input to that loader. A packaging adapter must map metadata including platform, sampling-only control status, provenance and `alignmentPolicy='full_record_resample_v1'`, preserving the exact arrays. The current counts and full-record policy match that evaluator's lower-rate timing requirements for this source.
- Jesher's separate `Jesher/Demo/prepare_audio.m` uses nearest-source-time selection for unfiltered 8/4 kHz conversion. This package uses linear interpolation. Those paths are different experiments despite similar case IDs. Preserve their provenance and agree on one shared method before presenting them as matching platform results or combining same-ID rows.
- His demo report primarily scores exported/re-imported WAVs and also records processing-array scores. The MAT arrays here preserve the sampling-stage doubles; use the same representation and documented PCM conversion when comparing numeric quality results.

Jesher's branch includes an independently generated full-case demo and result tables. That work has not been merged into this checkpoint or independently revalidated here. Its existence does not complete this package's outstanding new-rate Simulink comparison. No Jesher-owned files were changed by the compatibility check.

## What remains

Finish the three new Simulink rates and their comparison evidence. Preserve equivalent conversion/interpolation methods and verify block timing/delay rather than reusing an assumed delay. Khaled and Jesher still own combined bit-depth generation, quality metrics and final audio/listening evidence. Yazan integrates the report. The earlier 22.05 kHz platform check is recorded under AA-03; it does not certify the new Simulink rates.
