`timescale 1ns/1ps
module tb_drum_pattern_memory;
    reg clk = 0;
    always #5 clk = ~clk;
    reg reset=1, run=0, record_enable=0, clear_pulse=0, step_tick=0;
    reg [3:0] step_index=0;
    reg [2:0] live_triggers=0;
    wire [15:0] kick_pattern, snare_pattern, hihat_pattern;
    wire [2:0] playback_triggers;
    drum_pattern_memory dut (
        .clk(clk), .reset(reset), .run(run),
        .record_enable(record_enable), .clear_pulse(clear_pulse),
        .step_index(step_index), .step_tick(step_tick),
        .live_triggers(live_triggers),
        .kick_pattern(kick_pattern), .snare_pattern(snare_pattern),
        .hihat_pattern(hihat_pattern),
        .playback_triggers(playback_triggers)
    );
    initial begin
        repeat (2) @(negedge clk);
        reset=0; run=1; record_enable=1;
        step_index=0; live_triggers=3'b001;
        @(negedge clk);
        live_triggers=0;
        if (kick_pattern !== 16'h0001) $fatal(1,"Kick step 0 not recorded");

        step_index=4; live_triggers=3'b110;
        @(negedge clk); live_triggers=0;
        if (snare_pattern !== 16'h0010 || hihat_pattern !== 16'h0010)
            $fatal(1,"Snare and hi-hat step 4 not recorded");

        record_enable=0;
        step_index=1; live_triggers=3'b001;
        @(negedge clk); live_triggers=0;
        if (kick_pattern !== 16'h0001) $fatal(1,"Recorded without REC enabled");

        step_index=0; step_tick=1; #1;
        if (playback_triggers !== 3'b001) $fatal(1,"Kick playback failed");
        step_tick=0;
        step_index=4; step_tick=1; #1;
        if (playback_triggers !== 3'b110) $fatal(1,"Snare + hi-hat playback failed");
        step_tick=0;

        run=0; step_tick=1; #1;
        if (playback_triggers !== 3'b000) $fatal(1,"Playback while stopped");
        step_tick=0;
        clear_pulse=1;
        @(negedge clk); clear_pulse=0;
        if (kick_pattern !== 0 || snare_pattern !== 0 || hihat_pattern !== 0)
            $fatal(1,"Clear did not erase all patterns");
        $display("PASS tb_drum_pattern_memory: recording, playback, stop and clear");
        $finish;
    end
endmodule
