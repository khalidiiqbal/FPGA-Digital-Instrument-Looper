// Standalone synthesizer top for the DE1-SoC.
module synth_only_top (
    input  wire        CLOCK_50,
    input  wire [0:0]  KEY,
    input  wire [2:0]  SW,
    inout  wire        PS2_CLK,
    inout  wire        PS2_DAT,
    inout  wire        FPGA_I2C_SDAT,
    output wire        FPGA_I2C_SCLK,
    input  wire        AUD_ADCDAT,
    inout  wire        AUD_BCLK,
    inout  wire        AUD_ADCLRCK,
    inout  wire        AUD_DACLRCK,
    output wire        AUD_DACDAT,
    output wire        AUD_XCK,
    output wire [7:0]  VGA_R,
    output wire [7:0]  VGA_G,
    output wire [7:0]  VGA_B,
    output wire        VGA_HS,
    output wire        VGA_VS,
    output wire        VGA_BLANK_N,
    output wire        VGA_SYNC_N,
    output wire        VGA_CLK,
    output wire [9:0]  LEDR
);
    wire reset = ~KEY[0];

    wire [7:0] scan_code;
    wire scan_valid;
    wire [11:0] held_notes;
    wire note_valid;
    wire [3:0] note_index;
    wire signed [31:0] audio_sample;
    wire audio_out_allowed;

    PS2_Controller keyboard (
        .CLOCK_50(CLOCK_50), .reset(reset),
        .PS2_CLK(PS2_CLK), .PS2_DAT(PS2_DAT),
        .received_data(scan_code), .received_data_en(scan_valid),
        .the_command(8'h00), .send_command(1'b0),
        .command_was_sent(), .error_communication_timed_out()
    );

    ps2_note_decoder decoder (
        .clk(CLOCK_50), .reset(reset),
        .scan_code(scan_code), .scan_valid(scan_valid),
        .held_notes(held_notes), .note_valid(note_valid),
        .note_index(note_index)
    );

    synth_dds synthesizer (
        .clk(CLOCK_50), .reset(reset),
        .sample_tick(audio_out_allowed),
        .note_valid(note_valid), .note_index(note_index),
        .octave(SW[1:0]), .waveform_triangle(SW[2]),
        .audio_sample(audio_sample)
    );

    Audio_Controller audio (
        .CLOCK_50(CLOCK_50), .reset(reset),
        .clear_audio_in_memory(1'b0), .read_audio_in(1'b0),
        .clear_audio_out_memory(1'b0),
        .left_channel_audio_out(audio_sample),
        .right_channel_audio_out(audio_sample),
        .write_audio_out(audio_out_allowed),
        .audio_out_allowed(audio_out_allowed),
        .audio_in_available(),
        .left_channel_audio_in(), .right_channel_audio_in(),
        .AUD_ADCDAT(AUD_ADCDAT), .AUD_BCLK(AUD_BCLK),
        .AUD_ADCLRCK(AUD_ADCLRCK), .AUD_DACLRCK(AUD_DACLRCK),
        .AUD_DACDAT(AUD_DACDAT), .AUD_XCK(AUD_XCK)
    );

    avconf codec_config (
        .CLOCK_50(CLOCK_50), .reset(reset),
        .FPGA_I2C_SDAT(FPGA_I2C_SDAT),
        .FPGA_I2C_SCLK(FPGA_I2C_SCLK)
    );

    wire [7:0] px;
    wire [6:0] py;
    wire [2:0] pixel_colour;
    wire pixel_plot;

    vga_note_display keyboard_graphics (
        .clk(CLOCK_50), .reset(reset), .held_notes(held_notes),
        .x(px), .y(py), .colour(pixel_colour), .plot(pixel_plot)
    );

    vga_adapter #(
        .RESOLUTION("160x120"),
        .MONOCHROME("FALSE"),
        .BITS_PER_COLOUR_CHANNEL(1),
        .BACKGROUND_IMAGE("rtl/video/black.mif")
    ) VGA (
        .resetn(~reset), .clock(CLOCK_50),
        .colour(pixel_colour), .x(px), .y(py), .plot(pixel_plot),
        .VGA_R(VGA_R), .VGA_G(VGA_G), .VGA_B(VGA_B),
        .VGA_HS(VGA_HS), .VGA_VS(VGA_VS),
        .VGA_BLANK(VGA_BLANK_N), .VGA_SYNC(VGA_SYNC_N),
        .VGA_CLK(VGA_CLK)
    );

    assign LEDR[9:0] = held_notes[9:0];
endmodule
