# Jesher's current evaluation: use Khaled's published work

From the repository root, run **`RUN_JESHER`**. It reads Khaled's actual `KH04_MATLAB_Cases.mat` and `KH04_Simulink_Cases.mat`, generating them with his script/model if absent. It preserves the producer arrays, computes aligned NMSE/SNR, exports and verifies WAVs, and writes report figures and tables. **`RUN_PROJECT`** also regenerates Abdulrahman's sampling first.

For the live demonstration, edit root `PROJECT_SETTINGS.m`, run `RUN_DEMO`, then `PLAY_PROJECT_AUDIO`. See [QUICK_START](../QUICK_START.md) and [the current report](../Reports/Jesher_Khaled_Handoff_Results.md). Khaled's nine supplied observations are attributed separately from new Jesher speaker checks.

## Earlier independent demo and historical status

The material below describes the earlier standalone experiment. Its old coverage/status statements do not describe the current complete KH04 handoff evaluation.

The complete live demonstration is in **[Demo/](Demo/README.md)**. It reads the original audio directly, processes it in MATLAB or Simulink, exports a WAV, reads it back and calculates aligned NMSE/SNR. No handoff MAT files or Python environment are needed to run it.

## What to open for the presentation

| File | What you do |
| --- | --- |
| `Demo/SETTINGS.m` | Choose audio file, sampling rate, bits and filter mode |
| `Demo/RUN_MATLAB.m` | Run one MATLAB case and see its figures/results |
| `Demo/RUN_SIMULINK.m` | Run the same case through actual Simulink blocks |
| `Demo/Audio_Demo.slx` | Open the sampling, quantization and metric diagram |
| `Demo/PLAY_AUDIO.m` | Play the original and last processed case |
| `Demo/RUN_ALL.m` | Generate the complete 72-case experiment |

From the repository root in MATLAB:

```matlab
cd(fullfile('Jesher','Demo'))
RUN_MATLAB
RUN_SIMULINK
PLAY_AUDIO
```

Edit only the clearly commented settings in `SETTINGS.m`. The default is 22,050 Hz, 8 effective bits, with filtering. A useful second live case is 4,000 Hz, 2 bits, without filtering. The [code guide](Demo/README.md) explains every file and formula.

## Completed with the available resources

- The **36 MATLAB and 36 Simulink cases** are regenerated for the current
  `linear_interp_v2` method; see the actual run evidence in the results section.
- All 36 platform comparisons passed. Processing-array and exported-WAV agreement are recorded separately in the
  current comparison CSV; see the results section for measured differences.
- All 72 exports were re-imported and their headers/counts/sizes checked.
- A local archive contains the unchanged original, 72 outputs and their manifest.
- Waveform, FFT, spectrogram, quantization-error and histogram figures are generated.
- A known 10 kHz tone at an 8 kHz output rate produced the expected 2 kHz alias.
- Both single-case scripts, the direct model Run button and changed settings were tested.

Read [the full results section](Demo/RESULTS.md) or the [complete results PDF](report/output/pdf/Jesher_Complete_Demo_Results.pdf).

Generated audio and results go into `Demo/Results/`. New WAV/ZIP/MAT payloads stay local under your sharing preference. The saved model contains no embedded audio samples.

Human listening to the new outputs, four-person notes, live rehearsal and peer review still require the people involved. Earlier listening to three controls is recorded separately; no new subjective observations are invented.

## Older work

The `matlab/` public evaluator now accepts the new eight-case sampling handoff
(`samplingHandoff.cases`) as well as the existing top-level `cases` contract.
It evaluates 9 MATLAB controls and honestly reports 63 missing handoff cases.
This is separate from the independently generated 72-case demo.

Older `results/`, `validation/` and earlier report files are kept as history and evidence. They are not extra steps for the live demo. The earlier three-case report is superseded for current objective coverage by `Demo/RESULTS.md`. Other teammates' scripts and models are unchanged.

The previous nearest-source-time experiment is preserved at [Demo/history/13fc434/](Demo/history/13fc434/README.md). Current 8/4 kHz unfiltered routes use linear interpolation in both MATLAB and actual Simulink blocks, matching Abdulrahman's handoff. Both evaluators use documented, explicit nearest-integer PCM16 export.
