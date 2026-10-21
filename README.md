# CCEN 302 Signals Project

**Audio Signal Acquisition, Processing, and Quality Evaluation**

Course: Signals and Communications Systems (CCEN 302)

This coursework project investigates how sampling rate and bit depth affect audio quality and storage. The full experiment covers audio acquisition, time and frequency analysis, downsampling with and without anti-aliasing filtering, uniform quantization, NMSE/SNR measurements, playback, and a comparison between MATLAB and Simulink.

See the [project brief](CCEN%20302%20Project-3.pdf) for the authoritative requirements and submission instructions.

## Repository contents

| File | Purpose |
| --- | --- |
| `Original_Audio.m` | Existing MATLAB script for the original waveform, linear and decibel FFT magnitude plots, and spectrogram. |
| `untitled.wav` | Baseline recording: mono, 44,100 Hz, 16-bit PCM, approximately 20.004 seconds. |
| `CCEN 302 Project-3.pdf` | Supplied project brief. |
| `README.md` | Setup, current status, and required deliverables. |

## Run the current MATLAB script

Requirements:

- MATLAB with Signal Processing Toolbox for `spectrogram` and `hamming`.
- Keep `Original_Audio.m` and `untitled.wav` in the same folder.

Open that folder as MATLAB's Current Folder, then run:

```matlab
Original_Audio
```

The script is intended to create four figures:

1. Original audio waveform.
2. Single-sided FFT magnitude spectrum.
3. FFT magnitude spectrum in decibels.
4. Spectrogram using a 30 ms window, 20 ms overlap, and 2,048 FFT bins.

The frequency plots currently display 0-4 kHz. This is a display limit; the recording's sampling rate remains 44.1 kHz. The script currently reads an existing recording; it does not record microphone input or play audio.

## Current status

The repository contains an initial baseline-analysis script and a recording. MATLAB execution and the resulting figures have not yet been verified as part of this documentation update.

One existing detail needs review before relying on FFT amplitudes: in `if numSamples%2==0`, MATLAB treats `%` as the start of a comment, so this does not actually test whether the sample count is even. The implementation has been left unchanged for the team to review.

The following project requirements are not yet implemented in the tracked files:

- Downsampling to multiple lower rates, comparing filtered and unfiltered processing and identifying aliasing.
- Uniform quantization at lower bit depths, including quantization-error waveforms and distributions.
- NMSE and SNR tables across sampling-rate and bit-depth combinations, with signals aligned on a common comparison basis.
- Processed-audio export and playback, listening observations, and storage comparisons.
- A Simulink implementation of the experiment and comparison with MATLAB.
- The technical report and final audio archive.

Example settings in the brief include sampling rates of 22.05 kHz, 11.025 kHz, 8 kHz, and 4 kHz, and reduced bit depths of 8, 4, and 2 bits.

## Required deliverables

- Commented, modular MATLAB source and Simulink source with reproducible figures.
- A PDF report containing an executive summary, methods, comparative waveform/FFT/spectrogram plots, NMSE/SNR tables, and discussion of theory versus experiment.
- A ZIP containing the original and processed WAV recordings.
- An in-class demonstration and preparation for questions about the whole experiment.

The brief specifies groups of **two or four students** and a deadline of **5 November 2026 at 6:00 PM** (written as `5/11/2026` in the brief), with no extension. Submit the report and MATLAB/Simulink source through Blackboard. The brief also says recordings will be checked directly on laptops; keep the required audio archive ready and follow the instructor's final submission directions.

## Assessment weights

| Component | Weight |
| --- | --- |
| Audio acquisition and baseline analysis | 15% |
| Sampling and aliasing | 15% |
| Quantization | 15% |
| NMSE and SNR | 15% |
| Audio output and perceptual evaluation | 10% |
| Report and code documentation | 10% |
| Questions and answers | 20% |

Work ownership and team roles have not yet been agreed.
