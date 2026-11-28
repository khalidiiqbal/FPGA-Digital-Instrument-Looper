# Final-project scope — usability-focused drum looper

## Motivation

Milestone 2 successfully demonstrated a sixteen-step drum loop with recording from physical drum buttons. The main limitation is **programming accuracy**: storing a hit requires pressing KEY1–KEY3 while the playback counter is on the intended step. The 160×120 VGA display also communicates only basic status using colors and thin step markers.

The final-project goal is to improve the existing instrument, rather than add melody recording.

## Prioritized work

### Priority 1 — Interactive step editor

- Add a distinct **EDIT** mode and preserve **LIVE PLAY** mode.
- Navigate the sixteen steps and three drum rows using PS/2 arrow keys.
- Use Space to **toggle** the selected beat on/off; live recording remains optionally available.
- Keep the selected edit cursor visibly distinct from the moving sequencer playhead.
- Implement edit inputs as **single events** (handle key make/break and repeat carefully), so holding a key does not unintentionally toggle repeatedly.
- PS/2 extended scan codes (E0) currently ignored by the note decoder must be decoded separately. Gate musical-note input appropriately while editing.
- Reconsider SW4 assignment; it currently enables live recording. The final design must avoid conflicting control mappings.

**Success criterion:** Construct and revise a standard 16-step beat at a stopped or running sequencer position without time-critical button presses.

### Priority 2 — Clearer 160×120 VGA UI

- Three labeled drum lanes: KICK, SNARE, HAT.
- Sixteen columns grouped visually in sets of four, with stored hits easy to distinguish.
- Separate highlights for **playhead** (moving playback position) and **selection cursor** (editing position).
- Show **EDIT/LIVE**, **RUN/STOP**, and recording state using text or symbols, not just colors.
- Show tempo in numerals, ideally using a small bitmap-font ROM.
- Retain a compact piano-note visualization if screen space permits.
- Respect the VGA adapter's existing 160×120, 3-bit-color constraints and framebuffer write protocol.

**Success criterion:** A new person can identify the stored beat and playback position without consulting the control manual.

### Priority 3 — Fast demonstration presets

- Provide at least **Empty**, **Basic Rock/Pop**, and **Dance** 16-step patterns.
- Load a preset into the same 3×16-bit pattern storage used by manual editing.
- Clearly communicate that selecting a preset replaces the current stored pattern.

**Success criterion:** Load a recognizable rhythm in one control action.

### Priority 4 — Drum-track muting and correction

- Mute or unmute kick, snare and hi-hat **during playback**, without deleting their pattern bits.
- Allow deletion of a single hit by toggling the selected edit cell.
- Preserve live synth performance over the drum beat.
- Consider simple button debouncing if testing reveals repeated events.

**Success criterion:** Switch between full and isolated drum tracks and remove one mistaken hit without clearing the whole loop.

## Preserve from Milestone 2

The existing DDS synthesizer, drum sound generators, audio controller, 16-step tempo clock, current pattern memory and working peripheral connections should remain stable. New code is primarily needed in **input mode decoding**, **pattern edit interface**, **VGA presentation**, and **preset/mute control**.

## Explicitly out of scope

- Recording/repeating keyboard melodies.
- Digital sampling or exporting recorded audio.
- Permanent storage across power cycles.
- MIDI, networking or USB integration.

## Validation targets

- ModelSim: cursor movement, editing/toggle behavior, record/play mode switching, preset loading and muting.
- Quartus: full compile and timing review on the Cyclone V device **5CSEMA5F31C6**.
- DE1-SoC: interactive demo demonstrating creation, correction, playback and muting of a drum beat.

**Status:** This document describes planned final-project features. It does not claim they are implemented in the current RTL.
