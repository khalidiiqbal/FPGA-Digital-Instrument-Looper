`timescale 1ns/1ps
module tb_vga_looper_display;
    reg clk=0;
    always #5 clk=~clk;
    reg reset=1;
    reg [11:0] held_notes=0;
    reg [15:0] kick_pattern=0,snare_pattern=0,hihat_pattern=0;
    reg [3:0] step_index=0, tempo_sel=0;
    reg running=0,recording=0;
    wire [7:0] x;
    wire [6:0] y;
    wire [2:0] colour;
    wire plot;
    vga_looper_display dut (
        .clk(clk), .reset(reset), .held_notes(held_notes),
        .kick_pattern(kick_pattern),.snare_pattern(snare_pattern),
        .hihat_pattern(hihat_pattern), .step_index(step_index),
        .running(running),.recording(recording),.tempo_sel(tempo_sel),
        .x(x),.y(y),.colour(colour),.plot(plot)
    );
    task check_pixel(input [7:0] expected_x, input [6:0] expected_y,
                     input [2:0] expected_color);
        integer timeout;
        reg found;
        begin
            timeout=0; found=0;
            while (!found && timeout < 23000) begin
                @(negedge clk);
                if (plot && x==expected_x && y==expected_y) begin
                    found=1;
                    if (colour !== expected_color)
                        $fatal(1,"VGA (%d,%d) got=%b expected=%b",
                               x,y,colour,expected_color);
                end
                timeout=timeout+1;
            end
            if (!found) $fatal(1,"Never drew requested VGA pixel (%d,%d)",expected_x,expected_y);
        end
    endtask
    initial begin
        repeat(3) @(negedge clk); reset=0;
        check_pixel(8'd10,7'd5,3'b100);
        check_pixel(8'd8,7'd20,3'b001);
        check_pixel(8'd8,7'd101,3'b111);
        wait (plot==0);
        @(negedge clk);
        held_notes=12'h001; kick_pattern=16'h0001;
        snare_pattern=16'h0010; hihat_pattern=16'h0100;
        running=1;recording=1;step_index=4;tempo_sel=15;
        check_pixel(8'd10,7'd5,3'b010);
        check_pixel(8'd70,7'd5,3'b100);
        check_pixel(8'd8,7'd20,3'b100);
        check_pixel(8'd44,7'd45,3'b101);
        check_pixel(8'd80,7'd70,3'b011);
        check_pixel(8'd8,7'd101,3'b010);
        $display("PASS tb_vga_looper_display: status, recorded cells, cursor and held note");
        $finish;
    end
endmodule
