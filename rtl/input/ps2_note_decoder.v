// PS/2 Set-2 scan codes -> held-note bitmap for a 12-key chromatic keyboard.
// Keys (low to high): A W S E D F T G Y H U J
// Notes:              C C# D D# E F F# G G# A A# B
// This module receives BYTES from the PS2_Controller, not raw PS/2 pins.
module ps2_note_decoder (
    input  wire        clk,
    input  wire        reset,
    input  wire [7:0]  scan_code,
    input  wire        scan_valid,
    output reg  [11:0] held_notes,
    output reg         note_valid,
    output reg  [3:0]  note_index
);
    reg break_pending;
    reg extended_pending;
    reg [3:0] decoded_note;
    integer k;

    // 4'hF is used for keys that are not among the 12 musical notes.
    always @(*) begin
        case (scan_code)
            8'h1C: decoded_note = 4'd0;   // A : C
            8'h1D: decoded_note = 4'd1;   // W : C#
            8'h1B: decoded_note = 4'd2;   // S : D
            8'h24: decoded_note = 4'd3;   // E : D#
            8'h23: decoded_note = 4'd4;   // D : E
            8'h2B: decoded_note = 4'd5;   // F : F
            8'h2C: decoded_note = 4'd6;   // T : F#
            8'h34: decoded_note = 4'd7;   // G : G
            8'h35: decoded_note = 4'd8;   // Y : G#
            8'h33: decoded_note = 4'd9;   // H : A
            8'h3C: decoded_note = 4'd10;  // U : A#
            8'h3B: decoded_note = 4'd11;  // J : B
            default: decoded_note = 4'hF;
        endcase
    end

    // Set-2 sends a make code on press, and F0 + code on release.
    // Extended-key E0 sequences are deliberately ignored for this instrument.
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            held_notes      <= 12'b0;
            break_pending   <= 1'b0;
            extended_pending <= 1'b0;
        end else if (scan_valid) begin
            if (scan_code == 8'hE0) begin
                extended_pending <= 1'b1;
            end else if (scan_code == 8'hF0) begin
                break_pending <= 1'b1;
            end else begin
                if (!extended_pending && (decoded_note != 4'hF))
                    held_notes[decoded_note] <= !break_pending;
                break_pending    <= 1'b0;
                extended_pending <= 1'b0;
            end
        end
    end

    // Monophonic output: highest held key has priority.
    // held_notes still tracks all keys, so a polyphonic upgrade is possible.
    always @(*) begin
        note_valid = 1'b0;
        note_index = 4'd0;
        for (k = 0; k < 12; k = k + 1) begin
            if (held_notes[k]) begin
                note_valid = 1'b1;
                note_index = k;
            end
        end
    end
endmodule
