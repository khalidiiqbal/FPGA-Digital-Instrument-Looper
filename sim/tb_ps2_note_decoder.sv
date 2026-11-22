`timescale 1ns/1ps
module tb_ps2_note_decoder;
    reg clk = 0;
    always #10 clk = ~clk;
    reg reset = 1;
    reg [7:0] scan_code = 0;
    reg scan_valid = 0;
    wire [11:0] held_notes;
    wire note_valid;
    wire [3:0] note_index;
    ps2_note_decoder dut (
        .clk(clk), .reset(reset), .scan_code(scan_code),
        .scan_valid(scan_valid), .held_notes(held_notes),
        .note_valid(note_valid), .note_index(note_index)
    );
    task send_byte(input [7:0] code);
        begin
            @(negedge clk);
            scan_code = code;
            scan_valid = 1;
            @(negedge clk);
            scan_valid = 0;
            #1;
        end
    endtask
    task check(input [11:0] expected_mask,
               input expected_valid, input [3:0] expected_note);
        begin
            #1;
            if (held_notes !== expected_mask ||
                note_valid !== expected_valid ||
                note_index !== expected_note)
                $fatal(1,"Decoder failed: got mask %h valid %b note %d; expected %h %b %d",
                       held_notes, note_valid, note_index,
                       expected_mask, expected_valid, expected_note);
        end
    endtask
    initial begin
        $dumpfile("tb_ps2_note_decoder.vcd");
        $dumpvars(0,tb_ps2_note_decoder);
        #25; reset = 0;
        check(12'h000,0,0);
        send_byte(8'h1C);
        check(12'h001,1,0);
        send_byte(8'h1D);
        check(12'h003,1,1);
        send_byte(8'h1D);
        check(12'h003,1,1);
        send_byte(8'hF0); send_byte(8'h1D);
        check(12'h001,1,0);
        send_byte(8'hF0); send_byte(8'h1C);
        check(12'h000,0,0);
        send_byte(8'hE0); send_byte(8'h1C);
        check(12'h000,0,0);
        send_byte(8'hE0); send_byte(8'hF0); send_byte(8'h1C);
        check(12'h000,0,0);
        send_byte(8'h3B);
        check(12'h800,1,11);
        send_byte(8'h29);
        check(12'h800,1,11);
        send_byte(8'hF0); send_byte(8'h3B);
        check(12'h000,0,0);
        $display("PASS tb_ps2_note_decoder: make, repeat, break, priority, extended and ignored keys");
        $finish;
    end
endmodule
