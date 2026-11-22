# Build and simulation guide

## Target board

- Board: **Terasic DE1-SoC**
- FPGA: Intel/Altera Cyclone V SoC, **5CSEMA5F31C6**
- System clock: `CLOCK_50` (50 MHz)
- Toolchain used for the uploaded source project: Quartus Prime Lite 18.1, ModelSim

## Quartus setup

1. Obtain the compatible University Program/board-support Verilog modules for `PS2_Controller`, `Audio_Controller`, `avconf`, and `vga_adapter` and their dependencies. They are deliberately excluded from this repository.
2. Place the files under the `course_ip/` structure referenced by `digital_instrument_looper.qsf`, or update those paths to match your local installation.
3. Open `digital_instrument_looper.qpf` in Quartus. Select the `digital_instrument_top` module as top level (already configured in the QSF).
4. The QSF imports physical pins via `constraints/de1_soc_pins.qsf`, and clocks via `constraints/clock_50.sdc`. Confirm the assignments against your hardware.
5. Run Analysis & Synthesis, then Full Compilation. Review warnings and timing before programming the FPGA.
6. Program using the newly generated `.sof` from `output_files/`.

These reorganized paths and names have **not** been recompiled after restructuring. The original uploaded project was demonstrated working on a DE1-SoC.

## Simulations

From the repository root in ModelSim/Questa, run:

```tcl
do sim/run_all.do
```

Each testbench is separate and targets the custom RTL. ModelSim waveforms can be displayed by adding signal paths for the corresponding testbench.

## User controls

- PS/2 keyboard: play musical notes
- KEY[1]: kick; KEY[2]: snare; KEY[3]: hi-hat
- KEY[0]: active-low reset
- SW[1:0]: octave; SW[2]: square/triangle selection

## Core interfaces

The FPGA-design top module, DDS synthesizer, keyboard decoder, drum engines, mixer and VGA piano renderer are in `rtl/`. The third-party controller modules are **not** included here.
