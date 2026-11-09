# Run Jesher's evaluation of Khaled's work

This pipeline uses Abdulrahman's actual sampling outputs, **Khaled's published script/model from commit `fa2fc06`**, and Jesher's evaluator. Khaled's original source and model are preserved unchanged.

Use MATLAB R2026b, Signal Processing Toolbox, Simulink and DSP System Toolbox. This is the installation used for verification. Keep the complete repository folder structure.

## Your part: start here

Set MATLAB's Current Folder to the repository root and run:

```matlab
RUN_JESHER
```

This reads `Results/Khaled/Combined/KH04_MATLAB_Cases.mat` and `KH04_Simulink_Cases.mat` directly. If missing on a new download, it first runs Khaled's `Khaled_KH04_All_Cases` script to generate them. His script runs his own MATLAB quantizer and `Simulink/Khaled_Quantizer_Model.slx`. Jesher then evaluates all 72 exact outputs, exports/re-imports their WAVs and creates the local audio ZIP, tables, figures and report section.

The wrapper runs his script in a separate workspace because it starts with `clear`. It does not modify his processing.

## Regenerate everything

```matlab
RUN_PROJECT
```

This regenerates Abdulrahman's MATLAB handoff, runs his four sampling models, runs Khaled's actual producer, then calls `RUN_JESHER`. It takes several minutes.

## One live case

1. Edit `PROJECT_SETTINGS.m`: rate, effective bits, filter mode and platform. Defaults are 22,050 Hz, 8 bits, LPF, Simulink.
2. Run `RUN_DEMO`. It runs Khaled's function or model on the corresponding sampling input and checks exact equality with his saved case. It exports the WAV, prints processing-array and exported-WAV NMSE/SNR and shows plots.
3. For Simulink, his model opens with `simIn`, `Fs` and `Bsim` prepared for the direct Run button. Runtime parameters are not saved over his model.
4. Run `PLAY_PROJECT_AUDIO`. Set `settings.playAllCases = true` in `PROJECT_SETTINGS.m` to hear all outputs, about 25 minutes; Ctrl+C stops playback.

To demonstrate sampling, run `Compare_All_Sampling` from the root after initialization and inspect the four `SamplingModel_*Abdulrahman.slx` files.

## File responsibilities

| Owner/stage | Main files | Output |
| --- | --- | --- |
| Abdulrahman: sampling | `Sampling_Abdulrahman`, `Prepare_Sampling_Handoff`, `Compare_All_Sampling` and four sampling models | Exact sampling arrays and timing/filter metadata |
| Khaled: quantization | `Khaled_Quantizer`, `Khaled_KH04_All_Cases`, `Khaled_Quantizer_Model.slx` | Two 36-case KH04 MAT handoffs with isolated quantization errors |
| Jesher: evaluation/export | `Jesher/matlab/Run_Jesher_Evaluation` and `+jesher` helpers | Aligned NMSE/SNR, PCM16 WAVs, manifests and verified ZIP |
| Jesher: checks/report | `CHECK_INTEGRATION`, `Make_Integrated_Results`, `Write_Integrated_Report` | Exact handoff acceptance, platform comparison, storage tables, listening attribution and captions |

`Run_Khaled_Quantizer` is a live adapter that sets the same variables/solver settings as Khaled's producer. It contains no quantization algorithm.

## Results, interpretation and remaining actions

`Results/Integrated/latest_run.txt` identifies the latest successful folder. Use its `metrics.csv`, `producer_acceptance.csv`, `integration_comparison.csv`, `storage_quality.csv`, `listening_results.csv` and `figures/` together.

Insert [the current Jesher report section](Reports/Jesher_Khaled_Handoff_Results.md) after Khaled's section. The shared Word report is not automatically edited. Earlier standalone-demo and assistant-quantizer results are historical experiments with separate provenance.

Jesher uses the agreed `resample(...,p,q,10,5)` reconstruction. Khaled's KH06 quality table uses linear interpolation with held endpoints. `reconstruction_comparison.csv` labels both methods and compares processing-array scores; different scores do not imply different producer audio.

Effective bits and PCM16 WAV width are separate. `nmse/snrDb` score processing arrays; `exportedNmse/exportedSnrDb` score re-imported WAVs. The storage table distinguishes theoretical packed payload from actual WAV bytes.

Khaled's worksheet supplies nine listening observations and marks 63 cases untested. Joined results retain those notes with attribution; Jesher's new playback verification remains false. Actual speaker checks, further notes, rehearsal, peer approval and report assembly require the students. The ZIP stays named `UNREVIEWED` until those actions are completed.

Generated WAV/MAT/ZIP payloads remain local. Code, models, figures, CSVs and report text are published.
