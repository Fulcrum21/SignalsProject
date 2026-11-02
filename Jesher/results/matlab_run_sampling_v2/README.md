# Current sampling-handoff evaluation: 2 November 2026

These are actual results of `Run_Jesher_Evaluation` in MATLAB R2026b, using the
unchanged native recording plus eight exact `samplingHandoff.cases` arrays from
upstream `9b6ae88`. There are 9 available MATLAB controls and 63 missing producer
handoffs. This package is separate from the independent 72-case Demo experiment.

`metrics.csv` scores the supplied processing doubles in `nmse`/`snrDb`;
`exportedNmse`/`exportedSnrDb` score its WAV export/re-import. Both retain all
882,005 source sample times. No gain fitting, optimized lag, extra shift or
error-based trimming is applied. Export uses explicit nearest-integer PCM16;
the carrier width is separate from the b16 sampling-only control metadata.

**Common figure caption:** each PNG is named by its exact case ID. Original
(left) and supplied processing array reconstructed to 44.1 kHz (right) are
compared. Rows show waveform, full-record single-sided FFT (digital amplitude
reference, -160 dB display floor), and one-sided PSD spectrogram (periodic Hann
1024, overlap 768, 2048 DFT, -160 to 0 dB color scale). These plots use the
processing arrays, not the WAV representation; see the CSV for both measurements.

`case_coverage.csv`, `platform_comparison.csv` and the ten-audio manifest report
actual availability. There is no supplied Simulink counterpart in this package.
The independently generated Demo is not relabeled as a producer handoff.
The original plus nine exported WAVs, input snapshots, evaluation MAT and the
byte-verified partial audio ZIP remain local under the user's sharing preference.

Run instructions and the full current report are in `../../Demo/README.md`.
