`timescale 1ns/1ps
module tb_synth_dds;
    reg clk = 0;
    always #10 clk = ~clk;
    reg reset = 1;
    reg sample_tick = 0;
    reg note_valid = 0;
    reg [3:0] note_index = 0;
    reg [1:0] octave = 1;
    reg waveform_triangle = 0;
    wire signed [31:0] audio_sample;
    synth_dds dut (
        .clk(clk), .reset(reset), .sample_tick(sample_tick),
        .note_valid(note_valid), .note_index(note_index),
        .octave(octave), .waveform_triangle(waveform_triangle),
        .audio_sample(audio_sample)
    );
    integer n;
    integer transitions;
    reg old_sign;
    task measure_frequency(input integer low_expected, input integer high_expected);
        begin
            transitions = 0;
            old_sign = dut.phase[31];
            for (n = 0; n < 48000; n = n + 1) begin
                @(negedge clk); sample_tick = 1;
                @(negedge clk); sample_tick = 0;
                if (dut.phase[31] != old_sign) transitions = transitions + 1;
                old_sign = dut.phase[31];
            end
            if (transitions < low_expected || transitions > high_expected)
                $fatal(1,"Frequency out of range: %d sign transitions",transitions);
        end
    endtask
    initial begin
        $dumpfile("tb_synth_dds.vcd");
        $dumpvars(0,tb_synth_dds);
        #25; reset = 0;
        repeat(3) @(negedge clk);
        if (audio_sample !== 32'sd0)
            $fatal(1,"The synthesizer must be silent without a note");
        note_valid = 1; note_index = 0; octave = 1;
        repeat(3) @(negedge clk);
        if (audio_sample !== 32'sd200000000)
            $fatal(1,"A newly played square note must begin at positive amplitude");
        measure_frequency(522,526);
        note_index = 7; octave = 2;
        repeat(3) @(negedge clk);
        measure_frequency(1566,1570);
        waveform_triangle = 1;
        @(negedge clk);
        if (audio_sample === 32'sd200000000 ||
            audio_sample === -32'sd200000000)
            $fatal(1,"Triangle waveform should not be a fixed square level");
        note_valid = 0;
        repeat(2) @(negedge clk);
        if (audio_sample !== 32'sd0)
            $fatal(1,"The synthesizer must stop when note_valid goes low");
        $display("PASS tb_synth_dds: C4, G5, waveform selection and silence");
        $finish;
    end
endmodule
