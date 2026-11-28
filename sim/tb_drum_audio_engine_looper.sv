`timescale 1ns/1ps
module tb_drum_audio_engine_looper;
    reg clk=0;
    always #5 clk=~clk;
    reg reset=1, sample_tick=1;
    reg [2:0] buttons_n=3'b111;
    reg [2:0] playback_triggers=3'b000;
    reg signed [31:0] synth_sample=32'sd100000000;
    wire signed [31:0] mixed_sample;
    wire [2:0] live_triggers, combined_triggers;
    drum_audio_engine_looper dut (
        .clk(clk), .reset(reset), .sample_tick(sample_tick),
        .buttons_n(buttons_n), .playback_triggers(playback_triggers),
        .synth_sample(synth_sample), .mixed_sample(mixed_sample),
        .live_triggers(live_triggers), .combined_triggers(combined_triggers)
    );
    integer kick_live=0, kick_total=0, snare_total=0, hat_total=0;
    reg heard_kick=0, heard_snare=0, heard_hat=0;
    always @(posedge clk) begin
        if (!reset) begin
            if (live_triggers[0]) kick_live=kick_live+1;
            if (combined_triggers[0]) kick_total=kick_total+1;
            if (combined_triggers[1]) snare_total=snare_total+1;
            if (combined_triggers[2]) hat_total=hat_total+1;
            if (dut.kick_sample !== 16'sd0) heard_kick=1;
            if (dut.snare_sample !== 16'sd0) heard_snare=1;
            if (dut.hihat_sample !== 16'sd0) heard_hat=1;
        end
    end
    initial begin
        repeat (4) @(negedge clk);
        reset=0;
        repeat (6) @(negedge clk);
        // Current project scales the live synth to 50%.
        if (mixed_sample !== (synth_sample >>> 1))
            $fatal(1,"Idle drums must leave half-gain synth unchanged");

        buttons_n=3'b110;
        repeat (7) @(negedge clk);
        playback_triggers=3'b001;
        @(negedge clk); playback_triggers=0;
        buttons_n=3'b111;
        repeat (260) @(negedge clk);

        playback_triggers=3'b110;
        @(negedge clk); playback_triggers=0;
        repeat (70) @(negedge clk);
        if (kick_live != 1 || kick_total != 2 || snare_total != 1 || hat_total != 1)
            $fatal(1,"Live/playback triggers wrong: live=%d k=%d s=%d h=%d",
                kick_live,kick_total,snare_total,hat_total);
        if (!heard_kick || !heard_snare || !heard_hat)
            $fatal(1,"A percussion voice never generated nonzero audio");
        $display("PASS tb_drum_audio_engine_looper: live+loop triggers and three audible voices");
        $finish;
    end
endmodule
