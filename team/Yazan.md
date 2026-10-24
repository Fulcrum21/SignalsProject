# Yazan - Baseline Analysis and Integration

[Team progress](../README.md#team-progress) | [Schedule](../README.md#schedule) | [Shared experiment contract](../README.md#shared-experiment-contract) | [Update instructions](../README.md#how-to-update-your-progress)

**Owner:** Yazan | **Reviewer:** Abdulrahman

**Last updated:** 24 October 2026

**Internal finish:** 4 November 2026, 8:00 PM Dubai time. All deadlines below are at 8:00 PM Dubai time.

**Role:** own the baseline work already started, make it reproducible, and integrate everyone's contributions. Each teammate remains responsible for their code and report section.

## Completed work - retained for credit

These tasks acknowledge implemented artifacts, not unperformed runtime checks. Do not delete them when adding new work.

- [x] **YA-01 - Implement the original-audio MATLAB analysis. Due 25 October; already implemented.** Waveform, normalized single-sided FFT, linear/dB plots, and spectrogram are present in [the current script](../Matlab/FirstPart_AudioFreqAnalysis.m). Evidence: [initial contribution 33a0a64](https://github.com/Fulcrum21/SignalsProject/commit/33a0a64e5b40bac1c01ce1ebedd3ce62ce455985); retained under its current name.
- [x] **YA-02 - Correct the FFT even/odd condition. Due 25 October; completed 23 October.** The script now uses `if mod(numSamples,2)==0`. Evidence: [142f56b](https://github.com/Fulcrum21/SignalsProject/commit/142f56bb937ee1f12417c8b23ecba1cb889915b0).
- [x] **YA-03 - Add baseline and supplemental test audio. Due 25 October; completed 23-24 October.** [Audios](../Audios/) contains eight mono, 44.1 kHz, 16-bit WAVs including speech/music and known-frequency signals. Evidence: 142f56b and [ad8cc0d](https://github.com/Fulcrum21/SignalsProject/commit/ad8cc0d9711f4de8d5031e72e389eab35237e4e6). Microphone provenance is checked separately below; not every file is 20 seconds long.
- [x] **YA-04 - Implement the first baseline Simulink model. Due 27 October; committed 24 October.** [FirstPart_TimeFreqSimulink.slx](../Simulink/FirstPart_TimeFreqSimulink.slx) contains the time scope, FFT/magnitude chain, and spectrogram. Evidence: ad8cc0d and saved model metadata. Portable execution and numerical comparison remain separate checks.
- [x] **YA-05 - Organize recordings, scripts, and models into folders. Due 25 October; completed 24 October.** The repo now uses `Audios/`, `Matlab/`, and `Simulink/`. Evidence: ad8cc0d. This documentation update acknowledges that work without changing those source artifacts.

## Remaining tasks

- [ ] **YA-06 - Confirm acquisition, deadline, team access, and shared settings. Due 25 October.** Confirm that the primary audio was acquired through a laptop microphone and meets the brief; record the header/provenance. Confirm the actual instructor deadline: the planning assumption is 11 November, but the brief says 5 November at 6:00 PM. Record the authoritative evidence. Check all four teammates can publish progress, and accept/update the shared case matrix with all owners.
- [ ] **YA-07 - Make the baseline model portable and reproducible. Due 25 October.** Replace its saved absolute input path with a project-relative/configurable input. Document the working folder, required MATLAB release/toolboxes, model parameters, and how to run without another person's workspace variables. Run it from a second teammate's checkout; record evidence and the reviewer.
- [ ] **YA-08 - Validate baseline results and publish the reference. Due 26 October.** Run the MATLAB script and baseline model; inspect waveform, linear/dB spectra, and spectrogram. Check both odd/even input lengths, spectral scaling/units and zero-magnitude dB behavior. Match FFT/window conventions or explain the full-record versus frame-FFT difference. Share labeled figures, source metadata, and the unchanged reference with Abdulrahman, Khaled, and Jesher.
- [ ] **YA-09 - Coordinate one complete pipeline case. Due 27 October.** Integrate the 26 October component handoffs. Show one common reduced-rate/reduced-bit case with filtering choice, aligned NMSE/SNR, actual-rate WAV export/playback, and MATLAB/Simulink comparison. Each owner supplies their own evidence. Record any gaps and who will fix them.
- [ ] **YA-10 - Write the baseline report section. Due 31 October.** Include acquisition/provenance, baseline methods, software/settings, waveform/FFT/spectrogram figures with units, interpretation, and the baseline MATLAB/Simulink comparison.
- [ ] **YA-11 - Assemble the first complete report. Due 1 November.** Collect all four report sections. Add the executive summary, overall methodology/pipeline, conclusions, references, and consistent captions/notation. Ensure the report includes comparative processed-signal plots, full NMSE/SNR tables, storage/perception results, Nyquist discussion, and qualified theory-versus-experiment discussion of the 6 dB/bit rule.
- [ ] **YA-12 - Run the integrated project from a clean folder. Due 2 November.** With the other owners, verify all 36 primary cases per platform, generated figures/tables, matching case metadata, portable paths, and final report links. List run steps/toolbox requirements. Re-run or re-import the final files rather than relying only on old screenshots.
- [ ] **YA-13 - Review sampling work and close review/rehearsal findings. Review due 2 November; fixes and rehearsal due 3 November.** Review Abdulrahman's filter/rate choices, alias evidence, alignment policy, and MATLAB/Simulink agreement. Address his review of your baseline. Log each issue, owner, and resolution. Rehearse your own section and explain another teammate's section.
- [ ] **YA-14 - Assemble and sign off the final package. Due 4 November.** Verify the final PDF renders correctly, MATLAB/Simulink source is included, and Jesher's ZIP contains the original and all required exported audio with a case manifest. Run the demo, obtain all four owners' sign-offs, and prepare the Blackboard/laptop-check submission. Record the submission receipt once actually submitted by the confirmed official deadline.

## Handoffs

| When | Give / receive | Acceptance evidence |
| --- | --- | --- |
| 25-26 October | Give everyone the selected reference, settings, software/run instructions, and known limitations | Receiver can identify and load the same input |
| 27 October | Receive sampling from Abdulrahman, quantization from Khaled, and evaluation/export from Jesher | One complete case runs in both platforms |
| 31 October - 1 November | Receive each owner's figures/tables and written section | Section has methods, results, discussion, and traceable case IDs |
| 2-4 November | Receive reviewed source, corrected results, and final audio ZIP | Clean-folder run, closed findings, and four-owner sign-off |

## Progress log

Update this section with dated, specific evidence; a checkbox alone is not a handoff.

| Date | Update / evidence | Next action or blocker |
| --- | --- | --- |
| 24 October | Repository audit confirms YA-01 through YA-05 as implemented at ad8cc0d. The model still uses a machine-specific input path. MATLAB startup failed in the audit environment before script execution, so runtime validation is not claimed. | Complete YA-06/YA-07; retain all completed work above. |

**Review and final sign-off:** pending. Abdulrahman records his baseline review in his own document; Yazan records sampling findings here with task IDs and resolutions.
