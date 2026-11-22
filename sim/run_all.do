# From the repository root: do sim/run_all.do
vlib work
vlog rtl/audio/synth_dds.v rtl/input/ps2_note_decoder.v rtl/video/piano_note_display.v
vlog rtl/audio/drums/kick_drum.v rtl/audio/drums/snare_drum.v rtl/audio/drums/hi_hat_drum.v rtl/audio/drum_audio_engine.v
vlog -sv sim/tb_synth_dds.sv sim/tb_ps2_note_decoder.sv sim/tb_vga_note_display.sv sim/tb_drums_parallel.sv
foreach tb {tb_synth_dds tb_ps2_note_decoder tb_vga_note_display tb_drums_parallel} {
    vsim -onfinish stop work.$tb
    run -all
    quit -sim
}
