# Build and simulation instructions

## Hardware and project

- **Board:** Terasic DE1-SoC
- **FPGA:** Intel / Altera Cyclone V SoC **5CSEMA5F31C6**
- **Clock:** 50 MHz (`CLOCK_50`)
- **Project:** `digital_instrument_looper.qpf`
- **Current top-level entity:** `digital_instrument_ms2_top`
- **Toolchain:** Quartus Prime (project originated with Lite 18.1), ModelSim

## External University of Toronto peripheral IP

This repository publishes custom instrument RTL but **does not include** the original University of Toronto hardware-interface libraries. The design uses:

- `PS2_Controller` with its `Altera_UP_PS2_*` helper modules;
- `Audio_Controller`, `Audio_Clock`, and `Altera_UP_Audio_*` helpers;
- `avconf` and `I2C_Controller`;
- `vga_adapter`, `vga_controller`, `vga_pll` and `vga_address_translator`.

Obtain authorized copies from your existing DE1-SoC or compatible teaching-library installation. Place them under `course_ip/` in the folders referenced by `digital_instrument_looper.qsf`, or update the paths in that file to your local library locations. Do not replace this project's custom `rtl/` source files with the peripheral libraries.

## Compile and program

1. Open `digital_instrument_looper.qpf` in Quartus.
2. Confirm **Top-level entity = digital_instrument_ms2_top** and **device = 5CSEMA5F31C6**.
3. Check the imported `constraints/de1_soc_pins.qsf` and `constraints/clock_50.sdc` assignments.
4. Compile and review errors, timing and ignored-node/pin warnings.
5. Program the newly compiled `output_files/digital_instrument_looper.sof`.
6. Connect a PS/2 keyboard, VGA monitor, and board audio output.

The original local Milestone 2 project was tested on the DE1-SoC. The newly organized repository layout **has not been independently compiled or programmed after restructuring**; please verify the repository build locally.

## Controls

| Control | Function |
| --- | --- |
| KEY0 | Reset and erase saved patterns |
| KEY1, KEY2, KEY3 | Kick, snare, hi-hat (also record while SW4 is up and SW3 is running) |
| SW0–SW1 | Octave |
| SW2 | Synth waveform |
| SW3 | Start/stop sequence |
| SW4 | Enable live recording |
| SW5 | Clear all patterns on switch rising edge |
| SW6–SW9 | Tempo: 60–180 BPM |

The VGA screen shows three colored sequencer rows and a moving yellow playhead, with live keyboard-note indicators at the bottom.

## Simulation

From the repository root, run the custom RTL simulations with ModelSim:

```tcl
do sim/run_all.do
do sim/run_milestone2.do
```

Both scripts depend on the Verilog testbench files in `sim/`; the Milestone 2 script tests step timing, recording and playback, integrated drum triggers and VGA pixel output. These unit simulations do not require the third-party board-support IP.
