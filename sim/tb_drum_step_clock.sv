`timescale 1ns/1ps
module tb_drum_step_clock;
    reg clk = 0;
    always #5 clk = ~clk;
    reg reset = 1;
    reg run = 0;
    reg [3:0] tempo_sel = 0;
    wire [3:0] step_index;
    wire step_tick;

    // 60 BPM @ CLK_HZ=240 => 60 clocks per sixteenth note.
    // 180 BPM @ CLK_HZ=240 => 20 clocks per sixteenth note.
    drum_step_clock #(.CLK_HZ(240)) dut (
        .clk(clk), .reset(reset), .run(run), .tempo_sel(tempo_sel),
        .step_index(step_index), .step_tick(step_tick)
    );
    integer i;
    initial begin
        repeat(3) @(negedge clk);
        reset=0;
        repeat(3) @(negedge clk);
        if (step_tick || step_index !== 4'd0)
            $fatal(1,"Stopped sequencer not idle");

        run=1;
        @(negedge clk);
        if (!step_tick || step_index !== 4'd0)
            $fatal(1,"Start must trigger step 0 immediately");
        for (i=1;i<60;i=i+1) begin
            @(negedge clk);
            if (step_tick) $fatal(1,"Step fired too early at 60 BPM");
        end
        @(negedge clk);
        if (!step_tick || step_index !== 4'd1)
            $fatal(1,"60 BPM step interval incorrect");

        run=0;
        @(negedge clk);
        if (step_tick || step_index !== 4'd0)
            $fatal(1,"Stop must reset to step 0");

        tempo_sel=15;
        repeat(3) @(negedge clk);
        run=1;
        @(negedge clk);
        if (!step_tick || step_index !== 4'd0)
            $fatal(1,"Restart must trigger step 0");
        for (i=1;i<20;i=i+1) begin
            @(negedge clk);
            if (step_tick) $fatal(1,"180 BPM fired too early");
        end
        @(negedge clk);
        if (!step_tick || step_index !== 4'd1)
            $fatal(1,"180 BPM interval incorrect");

        for (i=0;i<15*20;i=i+1) @(negedge clk);
        if (step_index !== 4'd0)
            $fatal(1,"Step index failed to wrap 15->0");
        $display("PASS tb_drum_step_clock: start, timing, tempo, stop and 16-step wrapping");
        $finish;
    end
endmodule
