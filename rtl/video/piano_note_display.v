// VGA piano visualization for a 160x120, 3-bit RGB adapter.
// Twelve vertically oriented bars display held keyboard notes. This module
// is a pixel WRITER, not a VGA timing generator: connect it to vga_adapter.
module vga_note_display (
    input  wire        clk,
    input  wire        reset,
    input  wire [11:0] held_notes,
    output wire [7:0]  x,
    output wire [6:0]  y,
    output reg  [2:0]  colour,
    output wire        plot
);
    reg drawing;
    reg [7:0] draw_x;
    reg [6:0] draw_y;
    reg [11:0] draw_mask;
    integer key_num;

    assign x = draw_x;
    assign y = draw_y;
    assign plot = drawing;

    // Draw the whole background at reset. Redraw when a key changes.
    // Holding the mask steady for one frame prevents tearing within an update.
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            drawing   <= 1'b1;
            draw_x    <= 8'd0;
            draw_y    <= 7'd0;
            draw_mask <= 12'b0;
        end else if (drawing) begin
            if (draw_x == 8'd159) begin
                draw_x <= 8'd0;
                if (draw_y == 7'd119)
                    drawing <= 1'b0;
                else
                    draw_y <= draw_y + 7'd1;
            end else begin
                draw_x <= draw_x + 8'd1;
            end
        end else if (draw_mask != held_notes) begin
            draw_mask <= held_notes;
            draw_x    <= 8'd0;
            draw_y    <= 7'd0;
            drawing   <= 1'b1;
        end
    end

    function is_sharp;
        input integer n;
        begin
            is_sharp = (n == 1 || n == 3 || n == 6 || n == 8 || n == 10);
        end
    endfunction

    // Cyan = sharp, white = natural, green = held note.
    always @(*) begin
        key_num = 0; // Default assignment prevents inferred latch.
        colour = 3'b001; // Blue background
        if ((draw_y >= 7'd27 && draw_y <= 7'd31) ||
            (draw_y >= 7'd99 && draw_y <= 7'd103))
            colour = 3'b111;

        if (draw_y >= 7'd34 && draw_y <= 7'd96) begin
            for (key_num = 0; key_num < 12; key_num = key_num + 1) begin
                if (draw_x >= (8 + 12 * key_num) &&
                    draw_x <  (18 + 12 * key_num)) begin
                    if (draw_mask[key_num])
                        colour = 3'b010;
                    else if (is_sharp(key_num))
                        colour = 3'b011;
                    else
                        colour = 3'b111;
                end
            end
        end
    end
endmodule
