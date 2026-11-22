`timescale 1ns/1ps
// Stand-alone integration test for the drum audio engine.
module tb_drums_parallel;
    reg clk = 0;
    always #10 clk = ~clk;
    reg reset = 1;
    reg sample_tick = 1;
    reg [2:0] buttons_n = 3'b111;
    reg signed [31:0] synth_sample = 32'sd100000000;
    wire signed [31:0] mixed_sample;
    wire [2:0] trigger_pulses;
    integer kick_triggers = 0;
    integer snare_triggers = 0;
    integer hihat_triggers = 0;
    reg kick_audible = 0;
    reg snare_audible = 0;
    reg hihat_audible = 0;
    reg mixed_changed = 0;

    drum_audio_engine dut (
        .clk(clk), .reset(reset), .sample_tick(sample_tick),
        .buttons_n(buttons_n), .synth_sample(synth_sample),
        .mixed_sample(mixed_sample), .trigger_pulses(trigger_pulses)
    );
    always @(posedge clk) begin
        if (!reset) begin
            if (trigger_pulses[0]) kick_triggers = kick_triggers + 1;
            if (trigger_pulses[1]) snare_triggers = snare_triggers + 1;
            if (trigger_pulses[2]) hihat_triggers = hihat_triggers + 1;
            if (dut.kick_sample != 16'sd0) kick_audible = 1;
            if (dut.snare_sample != 16'sd0) snare_audible = 1;
            if (dut.hihat_sample != 16'sd0) hihat_audible = 1;
            if (mixed_sample != synth_sample) mixed_changed = 1;
        end
    end
    initial begin
        repeat (4) @(negedge clk);
        reset = 0;
        repeat (5) @(negedge clk);
        if (mixed_sample !== synth_sample) begin
            $display("FAIL: synth-only signal was changed");
            $stop;
        end
        buttons_n = 3'b110;
        repeat (8) @(negedge clk);
        buttons_n = 3'b111;
        repeat (280) @(negedge clk);
        buttons_n = 3'b101;
        repeat (8) @(negedge clk);
        buttons_n = 3'b111;
        repeat (160) @(negedge clk);
        buttons_n = 3'b011;
        repeat (8) @(negedge clk);
        buttons_n = 3'b111;
        repeat (60) @(negedge clk);
        if (kick_triggers != 1 || snare_triggers != 1 || hihat_triggers != 1) begin
            $display("FAIL: expected one trigger per drum: %0d %0d %0d",kick_triggers,snare_triggers,hihat_triggers);
            $stop;
        end
        if (!kick_audible || !snare_audible || !hihat_audible || !mixed_changed) begin
            $display("FAIL: drum audio missing: kick=%0d snare=%0d hi-hat=%0d mixed=%0d",
                     kick_audible,snare_audible,hihat_audible,mixed_changed);
            $stop;
        end
        $display("PASS tb_drums_parallel: all voices trigger and mix with active synthesizer");
        $finish;
    end
endmodule
