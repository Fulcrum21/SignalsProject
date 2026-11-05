# Sampling and aliasing: short Q&A preparation

1. **What does AA mean?** Anti-aliasing: a low-pass filter used before reducing the sampling rate.
2. **Why half the sampling rate?** Frequencies separated by sampling-frequency multiples can produce the same samples. For real signals, frequencies above half the rate fold into the positive baseband.
3. **Why does 10 kHz become 1,025 Hz?** At 11,025 samples/s, its samples match a tone at |10,000 - 11,025| = 1,025 Hz (up to phase/sign).
4. **Why not filter afterward?** The alias already overlaps genuine low-frequency content; a later filter cannot tell them apart.
5. **Why interpolate at 8/4 kHz?** Neither rate is an integer divisor of 44.1 kHz. We evaluate the original signal on exact new sample times using linear interpolation for the unfiltered comparison.
6. **Does interpolation prevent aliasing?** It affects frequency response but is not the dedicated new-Nyquist AA filter used by the filtered branch.
7. **What do p and q mean?** Interpolation and decimation factors: new Fs = old Fs × p/q. They are 80/441 for 8 kHz and 40/441 for 4 kHz.
8. **What is Kaiser?** The window family used to design the FIR filter; beta controls its shape. Our settings are n = 10 and beta = 5.
9. **Why remove 10 output samples in Simulink?** The causal FIR introduces a known delay. MATLAB resample compensates its designed delay, so that delay must be handled before comparing matching physical times.
10. **Why trim the final frame?** Frame processing pads beyond the original recording. We retain the actual reference sample count, not extra padding.
11. **Do near-zero platform differences mean perfect audio?** No. They show the two implementations agree. Degradation against the original is a separate NMSE/SNR measurement.
12. **Does upsampling recover lost information?** No. It reconstructs a comparison time grid; it cannot recover discarded bandwidth or undo aliasing.
13. **Why do filtered and unfiltered graphs overlap?** Much of the recording's energy is already in the retained band. Small differences may be clearer on dB axes.
14. **Is 68.74 dB the output SNR?** No. It is the measured amplitude suppression of the largest residual relative to the unfiltered alias in the known-tone test.
15. **How do FFT dB and spectrogram dB differ?** FFT amplitude uses 20 log10; spectrogram PSD uses a power-density reference and 10 log10. A frequency axis in kHz does not itself change per-Hz density units.

Practice: explain questions 3, 5, 9 and 11 aloud while pointing to the matching report figure or table. Read the code before answering follow-up questions about implementation.
