# Listening and speaker checks

These files are blank evidence forms. No teammate has been recorded as having listened, and no successful speaker check is asserted.

## Set up one comparison session

1. Use the same laptop speakers, seat, room, operating-system volume, and MATLAB playback gain for every case. Begin at a comfortable level using the original, then leave those settings fixed. Record the settings and actual date/time with timezone. Do not independently normalize the cases or use `soundsc`.
2. Use the verified exported WAVs at their native header rates. Check the manifest for the case ID, file, actual rate, effective quantizer bits, WAV container bits, and sample count. Preserve the original recording. A reduced sampling rate must retain the recording's duration rather than alter its speed.
3. Choose one common physical excerpt, for example 0 through 20 seconds when available. Record the exact excerpt actually used. Play the original first, then the selected cases in a recorded order. Keep this order the same for all four listeners, or record a different order if it was deliberately used.
4. Each listener writes their own observations before the group discusses them. Listen for clarity, high-frequency loss, hiss, harshness, or other changes, but record only what was heard. A blank observation is not evidence of "no difference". Leave missing files and unperformed comparisons pending.

## Play a file in MATLAB

From the repository root:

```matlab
addpath(fullfile('Jesher', 'matlab'));
info = Play_Jesher_Case(fullfile('Audios', 'SpeechMusic.wav'), 0.5, 0, 20);
```

For a processed case, pass its verified WAV path from the generated manifest. The function uses the file's actual sample rate and one fixed gain. It does not normalize audio. `streamCompleted=true` means the audio stream finished; a person must still verify audibility, speed, and speaker routing. Do not mark a speaker check passed merely because this function returned.

If a playback device cannot support a native rate, record the device error and use a documented device/output conversion that preserves duration. Keep the original native-rate WAV for export verification. Do not relabel the WAV rate to make it playable.

## Evidence forms

- Copy `playback_checks_template.csv` to a dated working file. It lists the original and all 72 expected processed cases. Check every available export through the laptop speakers; record the actual filename, rate, duration, session settings, outcome, and checker. Missing processed inputs remain `pending_missing_case`. `pending_playback` also does not mean passed.
- Copy `listening_notes_template.csv` to a dated working file. It supplies representative cases for Yazan, Abdulrahman, Khaled, and Jesher: native reference, native reduced-bit controls, filtered/unfiltered sampling controls, and combined reduced-rate/reduced-bit cases. These are planned selections, not completed experiments. Add rows when a listener hears other cases.
- Enter case-linked NMSE/SNR from the matching evaluation table after listening. State whether the metric used exact pre-export samples or re-imported WAV samples. WAV round-trip error is a separate measurement. Avoid presenting a sample-accurate pre-export score as a direct measurement of the speaker/room response.
- Record each actual listener and date/time; do not fill all listeners' notes from one person's opinion. Retain unperformed rows so the coverage remains visible.

## Connect observations to measurements

Compare the actual descriptions with the matching case IDs and NMSE/SNR. For example, state that a listener reported a change on a named case and give that case's score. Do not predict a listening result from the score and then record that prediction as an observation. Overall error energy does not capture all audible differences. Digital spectrum levels are not calibrated sound-pressure measurements.

## Completion

The audio package is ready only when its manifest matches the original and all required exports, WAV re-import checks have passed, and actual speaker checks are recorded. The perception section is ready only when the required listeners' actual observations are linked to verified case metrics. Keep unresolved inputs, playback problems, and missing listening notes explicit.
