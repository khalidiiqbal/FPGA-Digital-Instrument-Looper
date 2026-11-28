`timescale 1ns/1ps
// End-to-end drum loop test without external board IP.
module tb_drum_loop_integration;
    reg clk=0;
    always #5 clk=~clk;
    reg reset=1, run=0, rec=0, clear=0, sample_tick=1;
    reg [2:0] buttons_n=3'b111;
    wire [3:0] step_index;
    wire step_tick;
    wire [2:0] live_triggers,playback_triggers,combined_triggers;
    wire [15:0] kick_pattern,snare_pattern,hihat_pattern;
    wire signed [31:0] mixed_sample;
    integer loop_kicks=0, loop_snares=0, loop_hats=0;

    drum_step_clock #(.CLK_HZ(240)) clocker (
        .clk(clk), .reset(reset), .run(run), .tempo_sel(4'd0),
        .step_index(step_index), .step_tick(step_tick)
    );
    drum_pattern_memory patterns (
        .clk(clk),.reset(reset),.run(run),.record_enable(rec),
        .clear_pulse(clear),.step_index(step_index),.step_tick(step_tick),
        .live_triggers(live_triggers),.kick_pattern(kick_pattern),
        .snare_pattern(snare_pattern),.hihat_pattern(hihat_pattern),
        .playback_triggers(playback_triggers)
    );
    drum_audio_engine_looper engine (
        .clk(clk),.reset(reset),.sample_tick(sample_tick),
        .buttons_n(buttons_n),.playback_triggers(playback_triggers),
        .synth_sample(32'sd100000000),.mixed_sample(mixed_sample),
        .live_triggers(live_triggers),.combined_triggers(combined_triggers)
    );
    always @(posedge clk) begin
        if (!reset) begin
            if (playback_triggers[0]) loop_kicks=loop_kicks+1;
            if (playback_triggers[1]) loop_snares=loop_snares+1;
            if (playback_triggers[2]) loop_hats=loop_hats+1;
        end
    end
    task press_drum(input [2:0] active_low_buttons);
        begin
            @(negedge clk);buttons_n=active_low_buttons;
            repeat(6) @(negedge clk);
            buttons_n=3'b111;
            repeat(5) @(negedge clk);
        end
    endtask
    task await_step(input [3:0] wanted);
        integer timeout;
        reg found;
        begin
            timeout=0;found=0;
            while (!found && timeout < 2000) begin
                @(negedge clk);
                if(step_tick && step_index==wanted)found=1;
                timeout=timeout+1;
            end
            if(!found)$fatal(1,"Timed out waiting for step %0d",wanted);
        end
    endtask
    initial begin
        repeat(4) @(negedge clk);reset=0;
        @(negedge clk);rec=1;run=1;
        await_step(0);
        press_drum(3'b110);
        await_step(4);
        press_drum(3'b101);
        await_step(8);
        press_drum(3'b011);
        rec=0;
        if(kick_pattern !== 16'h0001 || snare_pattern !== 16'h0010 || hihat_pattern !== 16'h0100)
            $fatal(1,"Pattern memory mismatch: %h %h %h",kick_pattern,snare_pattern,hihat_pattern);
        repeat (16*60*3) @(negedge clk);
        if(loop_kicks < 2 || loop_snares < 2 || loop_hats < 2)
            $fatal(1,"Automatic loop did not repeat twice: %d %d %d",
                   loop_kicks,loop_snares,loop_hats);
        run=0;
        repeat(4) @(negedge clk);
        if(step_index !== 0) $fatal(1,"Stop failed to reset step counter");
        if(kick_pattern !== 16'h0001) $fatal(1,"Stop must not erase recorded pattern");
        clear=1;
        @(negedge clk);clear=0;
        if(kick_pattern !== 0 || snare_pattern !== 0 || hihat_pattern !== 0)
            $fatal(1,"Clear did not reset the drum patterns");
        $display("PASS tb_drum_loop_integration: record, repeat, stop, persist and clear");
        $finish;
    end
endmodule
