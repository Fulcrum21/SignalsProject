# Start here: simple course demonstration

This folder is the complete working demonstration. The older `Jesher/matlab/`,
`report/` and `results/` folders preserve the earlier three-case work; you do not
need them to run this demo. Other teammates' files are unchanged.

## Run it

1. Set MATLAB's Current Folder to `Jesher/Demo`.
2. Open `SETTINGS.m`. Choose the source WAV, output rate, bits and filter mode.
3. Run `RUN_MATLAB.m` for one MATLAB case.
4. Run `RUN_SIMULINK.m` for the same case using the visible `Audio_Demo.slx` blocks.
5. Run `PLAY_AUDIO.m` to hear the original and the last exported case.
6. Run `RUN_ALL.m` once to generate the full 72-case comparison and audio ZIP.

From the repository root, the equivalent commands are:

```matlab
cd(fullfile('Jesher','Demo'))
RUN_MATLAB
RUN_SIMULINK
PLAY_AUDIO
```

Use MATLAB, Signal Processing Toolbox, Simulink and DSP System Toolbox. The
implementation is exercised on MATLAB R2026b. Relative paths are calculated
from the script location; no username or absolute audio path is hard-coded.

## Which file does what?

| File | Purpose |
| --- | --- |
| `SETTINGS.m` | The settings you change for the demonstration |
| `RUN_MATLAB.m` | Run one MATLAB case, export it, score it and show plots |
| `RUN_SIMULINK.m` | Run one Simulink case, export it, score it and open the model |
| `RUN_ALL.m` | Run the 36 conditions on each platform and compare them |
| `PLAY_AUDIO.m` | Play the original and most recently selected exported WAV |
| `Audio_Demo.slx` | Actual sampling, quantization, reconstruction and metric blocks |
| `run_case.m` | The step-by-step processing/export/evaluation used by the run scripts |
| `prepare_audio.m` | Load the audio and calculate sample indices and filter coefficients |
| `setup_model.m` | Automatically put the selected settings into the Simulink workspace |
| `quality_metrics.m` | The NMSE and SNR formulas, including silence/zero-error cases |
| `make_plots.m` | Waveform, FFT, spectrogram, quantization error and histogram |
| `build_model.m` | Recreate the saved diagram if needed; not a normal demo step |
| `CHECK_DEMO.m` | A few short metric/quantizer sanity checks without a test framework |
| `DEMONSTRATE_ALIASING.m` | Optional 10 kHz tone example at 8 kHz; shows the measured alias peak |

Everything generated goes into **`Results/`**: WAVs, a single full `metrics.csv`,
`platform_comparison.csv`, `audio_manifest.csv`, selected figures and `all_audio.zip`.
`last_case.csv` describes the latest single-case run. Audio/MAT/ZIP payloads stay
local under the user's existing sharing preference.

The full current results are written up in [RESULTS.md](RESULTS.md), with a
[PDF report section](../report/output/pdf/Jesher_Complete_Demo_Results.pdf).

## Explain the pipeline to the doctor

1. **Read the original.** No independent normalization is applied. A stereo input
   is explicitly averaged to mono; the project source is already mono.
2. **Choose the output sampling rate.** The filtered path uses a Kaiser-window
   FIR with `resample(...,p,q,10,5)`. The unfiltered path selects the original
   sample nearest each output time, without prefiltering. At 22,050/11,025 Hz
   this is ordinary sample selection; 8,000/4,000 Hz use rational time indices.
3. **Quantize.** At B=8,4,2, step size is `2/2^B`. Round to a signed integer
   level, limit it to `[-2^(B-1), 2^(B-1)-1]`, and multiply by the step.
   The 16-bit control bypasses extra quantization. The same convention is used
   in MATLAB and in Simulink's Gain/Round/Saturation/Gain blocks.
4. **Export.** Write at the actual output rate in a supported mono 16-bit PCM
   WAV. Effective quantizer bits and carrier width are different. PCM conversion
   uses explicit nearest-integer rounding, and any clipping is counted.
5. **Read the WAV back.** Check its real rate, length and container width.
6. **Align.** Reconstruct the exported samples onto the original sample grid.
   Compensate known FIR/phase delay; retain the full original interval and its
   edge effects. Reconstruction does not recover lost frequencies.
7. **Measure.** `NMSE=sum((x-y).^2)/sum(x.^2)` and
   `SNR=10*log10(sum(x.^2)/sum((x-y).^2))`. The main result columns score the
   exported WAV. `ProcessingNMSE/ProcessingSNRdB` separately score the arrays
   before WAV conversion; these match the model's displays.

The Simulink model processes the complete recording as **one audio frame**.
Stop time 0 means one frame is evaluated once; it does not mean a zero-duration
recording. WAV duration comes from sample count / actual audio rate. Actual DSP
FIR rate-conversion and quantizer blocks process the samples; this is not a model
fed with an already processed MATLAB answer.

Opening the saved model and pressing **Run** also loads `SETTINGS.m` automatically.
You do not need to create workspace variables by hand. The MATLAB scripts use
temporary settings overrides when running the matrix; the model's normal Run
button returns to the settings file afterward. No source samples are embedded
in the saved model.

The figure renderer retains the minimum and maximum of dense display bins for
speed. Every sample is still used for the metrics and full-record FFT; only
the number of points drawn on the screen is reduced.

## Live demonstration order

Start with 22,050 Hz, 8 bits, `lpf` (the defaults). Run both scripts and compare
the printed scores and model displays. Play the output. Then change to 4,000 Hz,
2 bits, `none` and repeat to make the degradation more noticeable. Use `RUN_ALL`
for the full table; its completed results can be shown without waiting for a
batch run during the presentation.

Human listening observations, microphone provenance, teammate review and live
rehearsal are not claimed by a successful numerical run. The new complete
implementation is provided for the course demo; it does not claim that teammates
independently implemented or accepted these conventions.

## Five questions to rehearse

- **Why reconstruct before subtracting?** The two arrays must represent the same
  physical sample times. Different rates cannot be compared by their array index.
- **Why is native-control SNR infinite?** The signal has positive energy but its
  error is zero. It is not a claim about acoustic background noise.
- **Why is an 8-bit case's WAV still 16-bit?** Eight bits describe its quantizer
  levels; the supported WAV carrier is 16-bit. File size does not automatically
  fall when only effective quantizer bits change.
- **Why might the unfiltered plot also have a cutoff?** Reconstruction uses a
  low-pass interpolation filter. It cannot undo aliasing introduced earlier.
- **Must every added bit improve speech/music SNR by exactly 6 dB?** No. The
  approximate rule relies on an ideal quantization-noise model and suitable
  signal amplitude/statistics; low-bit clipping and quiet content violate those
  assumptions.
