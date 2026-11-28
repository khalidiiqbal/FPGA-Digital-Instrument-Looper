// 160x120 VGA frame-buffer writer for the external vga_adapter.
// Header: left green=RUN/red=STOP; middle red=REC/blue=PLAY;
//         right magenta bar represents tempo.
// Drum rows: kick (red), snare (magenta), hi-hat (cyan).
// Recorded steps show track colors; the moving playhead is yellow.
// Bottom 12 bars: live PS/2 synth keyboard, green when held.
module vga_looper_display(
    input  wire        clk,
    input  wire        reset,
    input  wire [11:0] held_notes,
    input  wire [15:0] kick_pattern,
    input  wire [15:0] snare_pattern,
    input  wire [15:0] hihat_pattern,
    input  wire [3:0]  step_index,
    input  wire        running,
    input  wire        recording,
    input  wire [3:0]  tempo_sel,
    output wire [7:0]  x,
    output wire [6:0]  y,
    output reg  [2:0]  colour,
    output wire        plot
);
    reg drawing;
    reg [7:0] draw_x;
    reg [6:0] draw_y;
    reg [11:0] frame_keys;
    reg [15:0] frame_kick, frame_snare, frame_hihat;
    reg [3:0] frame_step, frame_tempo;
    reg frame_running, frame_recording;

    assign x = draw_x;
    assign y = draw_y;
    assign plot = drawing;

    // Freeze visual state over a complete pixel-write sweep, so a sequencer
    // step change halfway through the sweep cannot produce a mixed frame.
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            drawing <= 1'b1;
            draw_x <= 8'd0;
            draw_y <= 7'd0;
            frame_keys <= 12'b0;
            frame_kick <= 16'b0;
            frame_snare <= 16'b0;
            frame_hihat <= 16'b0;
            frame_step <= 4'd0;
            frame_tempo <= 4'd0;
            frame_running <= 1'b0;
            frame_recording <= 1'b0;
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
        end else if (frame_keys != held_notes ||
                     frame_kick != kick_pattern ||
                     frame_snare != snare_pattern ||
                     frame_hihat != hihat_pattern ||
                     frame_step != step_index ||
                     frame_running != running ||
                     frame_recording != recording ||
                     frame_tempo != tempo_sel) begin
            frame_keys <= held_notes;
            frame_kick <= kick_pattern;
            frame_snare <= snare_pattern;
            frame_hihat <= hihat_pattern;
            frame_step <= step_index;
            frame_tempo <= tempo_sel;
            frame_running <= running;
            frame_recording <= recording;
            draw_x <= 8'd0;
            draw_y <= 7'd0;
            drawing <= 1'b1;
        end
    end

    function is_sharp;
        input integer n;
        begin
            is_sharp = (n == 1 || n == 3 || n == 6 || n == 8 || n == 10);
        end
    endfunction

    integer col;
    reg [3:0] selected_step;
    reg inside_step;
    reg inside_key;
    reg [3:0] selected_key;
    reg [15:0] selected_pattern;
    reg [2:0] track_colour;
    reg [6:0] row_top, row_bottom;
    reg in_row;

    always @(*) begin
        colour = 3'b000;
        selected_step = 4'd0;
        inside_step = 1'b0;
        inside_key = 1'b0;
        selected_key = 4'd0;
        selected_pattern = 16'b0;
        track_colour = 3'b000;
        row_top = 7'd0;
        row_bottom = 7'd0;
        in_row = 1'b0;

        // Three status bars at the top.
        if (draw_y < 7'd9) begin
            if (draw_x < 8'd55)
                colour = frame_running ? 3'b010 : 3'b100;
            else if (draw_x >= 8'd62 && draw_x < 8'd115)
                colour = frame_recording ? 3'b100 : 3'b001;
            else if (draw_x >= 8'd123 &&
                     draw_x < (8'd125 + {3'b000, frame_tempo, 1'b0}))
                colour = 3'b101;
        end

        if (draw_y >= 7'd16 && draw_y <= 7'd34) begin
            in_row = 1'b1;
            row_top = 7'd16; row_bottom = 7'd34;
            selected_pattern = frame_kick;
            track_colour = 3'b100;
        end else if (draw_y >= 7'd41 && draw_y <= 7'd59) begin
            in_row = 1'b1;
            row_top = 7'd41; row_bottom = 7'd59;
            selected_pattern = frame_snare;
            track_colour = 3'b101;
        end else if (draw_y >= 7'd66 && draw_y <= 7'd84) begin
            in_row = 1'b1;
            row_top = 7'd66; row_bottom = 7'd84;
            selected_pattern = frame_hihat;
            track_colour = 3'b011;
        end

        if (in_row) begin
            if (draw_x < 8'd5)
                colour = track_colour;
            for (col = 0; col < 16; col = col + 1) begin
                // Each cell: 8 pixels wide + 1 pixel spacing.
                if (draw_x >= (8 + col * 9) &&
                    draw_x < (16 + col * 9)) begin
                    inside_step = 1'b1;
                    selected_step = col[3:0];
                end
            end
            if (inside_step) begin
                if (frame_running && selected_step == frame_step &&
                    (draw_y == row_top || draw_y == row_bottom))
                    colour = 3'b110; // Yellow playhead border.
                else if (selected_pattern[selected_step])
                    colour = track_colour; // Hit stored.
                else if (frame_running && selected_step == frame_step)
                    colour = 3'b110; // Yellow current empty step.
                else
                    colour = 3'b001; // Blue empty cell.
            end
        end

        if (draw_y >= 7'd97 && draw_y <= 7'd116) begin
            for (col = 0; col < 12; col = col + 1) begin
                if (draw_x >= (8 + col * 12) &&
                    draw_x < (18 + col * 12)) begin
                    inside_key = 1'b1;
                    selected_key = col[3:0];
                end
            end
            if (inside_key) begin
                if (frame_keys[selected_key])
                    colour = 3'b010;
                else if (is_sharp(selected_key))
                    colour = 3'b011;
                else
                    colour = 3'b111;
            end
        end
    end
endmodule
