// Milestone 2 top level for Terasic DE1-SoC / Cyclone V 5CSEMA5F31C6.
// Live PS/2 keyboard synthesizer + 16-step recorded drum loop + VGA grid.
// External University of Toronto controllers: PS2_Controller, Audio_Controller,
// avconf, vga_adapter (obtain separately; not redistributed here).
module digital_instrument_ms2_top (
    input  wire        CLOCK_50,
    input  wire [3:0]  KEY,
    input  wire [9:0]  SW,
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
    reg [9:0] switches_meta, switches_sync;
    reg clear_was_high;

    always @(posedge CLOCK_50 or posedge reset) begin
        if (reset) begin
            switches_meta <= 10'b0;
            switches_sync <= 10'b0;
            clear_was_high <= 1'b0;
        end else begin
            switches_meta <= SW;
            switches_sync <= switches_meta;
            clear_was_high <= switches_sync[5];
        end
    end

    wire run = switches_sync[3];
    wire record_enable = switches_sync[4];
    wire clear_pulse = switches_sync[5] && !clear_was_high;
    wire [3:0] tempo_sel = switches_sync[9:6];

    wire [7:0] scan_code;
    wire scan_valid;
    PS2_Controller keyboard (
        .CLOCK_50(CLOCK_50), .reset(reset),
        .PS2_CLK(PS2_CLK), .PS2_DAT(PS2_DAT),
        .received_data(scan_code), .received_data_en(scan_valid),
        .the_command(8'h00), .send_command(1'b0),
        .command_was_sent(), .error_communication_timed_out()
    );

    wire [11:0] held_notes;
    wire note_valid;
    wire [3:0] note_index;
    ps2_note_decoder note_decoder (
        .clk(CLOCK_50), .reset(reset),
        .scan_code(scan_code), .scan_valid(scan_valid),
        .held_notes(held_notes), .note_valid(note_valid),
        .note_index(note_index)
    );

    wire audio_out_allowed;
    wire signed [31:0] synth_sample, mixed_sample;
    synth_dds synthesizer (
        .clk(CLOCK_50), .reset(reset),
        .sample_tick(audio_out_allowed),
        .note_valid(note_valid), .note_index(note_index),
        .octave(switches_sync[1:0]),
        .waveform_triangle(switches_sync[2]),
        .audio_sample(synth_sample)
    );

    wire [3:0] step_index;
    wire step_tick;
    drum_step_clock #(.CLK_HZ(50000000)) beat_clock (
        .clk(CLOCK_50), .reset(reset), .run(run),
        .tempo_sel(tempo_sel), .step_index(step_index),
        .step_tick(step_tick)
    );

    wire [15:0] kick_pattern, snare_pattern, hihat_pattern;
    wire [2:0] live_triggers, playback_triggers, combined_triggers;
    drum_pattern_memory recorder (
        .clk(CLOCK_50), .reset(reset),
        .run(run), .record_enable(record_enable),
        .clear_pulse(clear_pulse),
        .step_index(step_index), .step_tick(step_tick),
        .live_triggers(live_triggers),
        .kick_pattern(kick_pattern),
        .snare_pattern(snare_pattern),
        .hihat_pattern(hihat_pattern),
        .playback_triggers(playback_triggers)
    );

    drum_audio_engine_looper drums (
        .clk(CLOCK_50), .reset(reset),
        .sample_tick(audio_out_allowed),
        .buttons_n(KEY[3:1]),
        .playback_triggers(playback_triggers),
        .synth_sample(synth_sample),
        .mixed_sample(mixed_sample),
        .live_triggers(live_triggers),
        .combined_triggers(combined_triggers)
    );

    Audio_Controller audio (
        .CLOCK_50(CLOCK_50), .reset(reset),
        .clear_audio_in_memory(1'b0), .read_audio_in(1'b0),
        .clear_audio_out_memory(1'b0),
        .left_channel_audio_out(mixed_sample),
        .right_channel_audio_out(mixed_sample),
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
    vga_looper_display sequencer_visualization (
        .clk(CLOCK_50), .reset(reset),
        .held_notes(held_notes),
        .kick_pattern(kick_pattern),
        .snare_pattern(snare_pattern),
        .hihat_pattern(hihat_pattern),
        .step_index(step_index),
        .running(run),
        .recording(record_enable && run),
        .tempo_sel(tempo_sel),
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

    assign LEDR[3:0] = step_index;
    assign LEDR[4] = run;
    assign LEDR[5] = run && record_enable;
    assign LEDR[6] = switches_sync[5];
    assign LEDR[7] = kick_pattern[step_index];
    assign LEDR[8] = snare_pattern[step_index];
    assign LEDR[9] = hihat_pattern[step_index];
endmodule
