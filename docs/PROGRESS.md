# Development progress

## Milestone 1 — Completed

- PS/2 keyboard decoding and 12-note DDS synth.
- Three custom percussion voices (kick, snare, hi-hat).
- Signed PCM mixing and DE1-SoC audio output.
- VGA piano-note display.
- ModelSim component-level tests and hardware demo.

## Milestone 2 — Demonstrated on DE1-SoC

- 50 MHz clock-derived 16-step sequencer with selectable 60–180 BPM speed.
- 48-bit storage: 16 steps each for kick, snare and hi-hat.
- Live, timing-based additive drum recording.
- Recorded percussion repeats in time while synth is played live.
- SW3 transport, SW4 live-record mode, SW5 clear, SW6–SW9 tempo.
- 160×120 VGA drum-lane grid, basic tempo/status bars, live piano indicators.
- Physical demo completed according to the latest project update.

### Known limitations

1. Recording requires pressing each drum button during its desired step and is hard to program precisely.
2. Individual recorded hits cannot yet be toggled off; SW5 clears all lanes.
3. The current VGA presentation lacks explicit labels, a visible edit cursor and a numeric tempo display.
4. Patterns are stored only in volatile FPGA registers; reset/power-off removes them.
5. The repository sources have been reorganized from the tested local project, and should undergo a fresh Quartus build.

## Final project — Planned

- Direct keyboard-driven step editor (arrow navigation, Space toggle).
- Clearer, labeled VGA interface with edit cursor and playback playhead.
- Quick-load preset drum beats.
- Independent drum-lane muting and single-hit corrections.

The final phase focuses on usability and presentation. Melody loop recording is not planned.

See [FINAL_SCOPE.md](FINAL_SCOPE.md).
