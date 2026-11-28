# ModelSim / Questa: run from repository root
# Run: do sim/run_milestone2.do
# Board-support IP is not required for these tests.
if {![file exists work]} { vlib work }
vlog rtl/audio/drums/kick_drum.v rtl/audio/drums/snare_drum.v rtl/audio/drums/hi_hat_drum.v
vlog rtl/sequencer/drum_step_clock.v rtl/sequencer/drum_pattern_memory.v
vlog rtl/audio/drum_audio_engine_looper.v rtl/video/vga_looper_display.v
vlog -sv sim/tb_drum_step_clock.sv sim/tb_drum_pattern_memory.sv
vlog -sv sim/tb_drum_audio_engine_looper.sv sim/tb_vga_looper_display.sv
vlog -sv sim/tb_drum_loop_integration.sv

foreach tb {tb_drum_step_clock tb_drum_pattern_memory tb_drum_audio_engine_looper tb_vga_looper_display tb_drum_loop_integration} {
    echo "------------------- Running $tb -------------------"
    vsim -onfinish stop work.$tb
    run -all
    quit -sim
}
echo "Completed Milestone 2 testbench run. Check Transcript for PASS messages."
