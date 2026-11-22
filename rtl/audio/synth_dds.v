// 12-note direct digital synthesizer (DDS), PCM output at 48,000 samples/s.
// User-selectable octave: 0=C3..B3, 1=C4..B4, 2=C5..B5, 3=C6..B6.
// waveform_triangle=0 selects a square wave; 1 selects a triangle wave.
// sample_tick must pulse for EVERY accepted output audio sample.
module synth_dds (
    input  wire               clk,
    input  wire               reset,
    input  wire               sample_tick,
    input  wire               note_valid,
    input  wire [3:0]         note_index,
    input  wire [1:0]         octave,
    input  wire               waveform_triangle,
    output wire signed [31:0] audio_sample
);
    reg [31:0] phase;
    reg [3:0] last_note;
    reg [1:0] last_octave;
    reg       last_valid;
    reg [31:0] base_increment;

    // round(frequency * 2^32 / 48000) for C3 through B3.
    // The octave switch doubles this increment for each octave increase.
    always @(*) begin
        case (note_index)
            4'd0:  base_increment = 32'd11704930; // C
            4'd1:  base_increment = 32'd12400941; // C#
            4'd2:  base_increment = 32'd13138339; // D
            4'd3:  base_increment = 32'd13919586; // D#
            4'd4:  base_increment = 32'd14747287; // E
            4'd5:  base_increment = 32'd15624207; // F
            4'd6:  base_increment = 32'd16553270; // F#
            4'd7:  base_increment = 32'd17537579; // G
            4'd8:  base_increment = 32'd18580418; // G#
            4'd9:  base_increment = 32'd19685267; // A
            4'd10: base_increment = 32'd20855814; // A#
            4'd11: base_increment = 32'd22095965; // B
            default: base_increment = 32'd0;
        endcase
    end

    wire [31:0] phase_increment = base_increment << octave;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            phase        <= 32'd0;
            last_note    <= 4'd0;
            last_octave  <= 2'd0;
            last_valid   <= 1'b0;
        end else begin
            last_note   <= note_index;
            last_octave <= octave;
            last_valid  <= note_valid;
            if (!note_valid || !last_valid || note_index != last_note || octave != last_octave)
                phase <= 32'd0; // Start each new note cleanly.
            else if (sample_tick)
                phase <= phase + phase_increment;
        end
    end

    // A square wave is determined by the top bit of the phase accumulator.
    wire signed [31:0] square_sample = phase[31] ?
        -32'sd200000000 : 32'sd200000000;

    // Fold the phase into a triangle, center it around zero and scale to PCM.
    wire [14:0] folded_phase = phase[31] ? ~phase[30:16] : phase[30:16];
    wire signed [16:0] centered_triangle =
        $signed({2'b00, folded_phase}) - 17'sd16384;
    wire signed [31:0] triangle_sample =
        {{15{centered_triangle[16]}}, centered_triangle} <<< 13;

    assign audio_sample = !note_valid ? 32'sd0 :
                          waveform_triangle ? triangle_sample : square_sample;
endmodule
