`timescale 1ns/1ps
module tb_vga_note_display;
    reg clk = 0;
    always #10 clk = ~clk;
    reg reset = 1;
    reg [11:0] held_notes = 0;
    wire [7:0] x;
    wire [6:0] y;
    wire [2:0] colour;
    wire plot;
    vga_note_display dut (
        .clk(clk), .reset(reset), .held_notes(held_notes),
        .x(x), .y(y), .colour(colour), .plot(plot)
    );
    task await_pixel(input [7:0] wanted_x, input [6:0] wanted_y,
                     input [2:0] expected_colour);
        integer timeout;
        reg found;
        begin
            timeout = 0;
            found = 0;
            while (!found && timeout < 50000) begin
                @(negedge clk);
                if (plot && x == wanted_x && y == wanted_y) begin
                    found = 1;
                    if (colour !== expected_colour)
                        $fatal(1,"Pixel (%d,%d) color %b expected %b",
                               x,y,colour,expected_colour);
                end
                timeout = timeout + 1;
            end
            if (!found) $fatal(1,"Timed out waiting for pixel (%d,%d)", wanted_x,wanted_y);
        end
    endtask
    initial begin
        $dumpfile("tb_vga_note_display.vcd");
        $dumpvars(0,tb_vga_note_display);
        #25; reset=0;
        await_pixel(8'd8,7'd50,3'b111);
        await_pixel(8'd20,7'd50,3'b011);
        wait(plot == 0);
        @(negedge clk); held_notes = 12'h001;
        await_pixel(8'd8,7'd50,3'b010);
        await_pixel(8'd20,7'd50,3'b011);
        $display("PASS tb_vga_note_display: initial draw, sharp key and active note redraw");
        $finish;
    end
endmodule
