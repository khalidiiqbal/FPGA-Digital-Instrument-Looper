// Milestone 2 audio: live drum presses and sequence-triggered drums
// combine with the PS/2 synthesizer through signed 32-bit mixing.
module drum_audio_engine_looper(
    input  wire               clk,
    input  wire               reset,
    input  wire               sample_tick,
    input  wire [2:0]         buttons_n,
    input  wire [2:0]         playback_triggers,
    input  wire signed [31:0] synth_sample,
    output wire signed [31:0] mixed_sample,
    output wire [2:0]         live_triggers,
    output wire [2:0]         combined_triggers
);
    reg [2:0] pressed_meta;
    reg [2:0] pressed_sync;
    reg [2:0] pressed_prev;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            pressed_meta <= 3'b000;
            pressed_sync <= 3'b000;
            pressed_prev <= 3'b000;
        end else begin
            pressed_meta <= ~buttons_n;
            pressed_sync <= pressed_meta;
            pressed_prev <= pressed_sync;
        end
    end

    assign live_triggers = pressed_sync & ~pressed_prev;
    assign combined_triggers = live_triggers | playback_triggers;

    wire signed [15:0] kick_sample;
    wire signed [15:0] snare_sample;
    wire signed [15:0] hihat_sample;

    kick_drum kick (
        .clk(clk), .reset(reset), .sample_tick(sample_tick),
        .trigger(combined_triggers[0]), .audio_out(kick_sample)
    );
    snare_drum snare (
        .clk(clk), .reset(reset), .sample_tick(sample_tick),
        .trigger(combined_triggers[1]), .audio_out(snare_sample)
    );
    hihat_drum hihat (
        .clk(clk), .reset(reset), .sample_tick(sample_tick),
        .trigger(combined_triggers[2]), .audio_out(hihat_sample)
    );

    wire signed [31:0] kick_scaled =
        $signed({{16{kick_sample[15]}}, kick_sample}) <<< 14;
    wire signed [31:0] snare_scaled =
        $signed({{16{snare_sample[15]}}, snare_sample}) <<< 14;
    wire signed [31:0] hihat_scaled =
        $signed({{16{hihat_sample[15]}}, hihat_sample}) <<< 14;

    // Half-volume synth relative to Milestone 2 package (final lab tuning).
    // The drum gains are unchanged.
    assign mixed_sample = (synth_sample >>> 1) + kick_scaled + snare_scaled + hihat_scaled;
endmodule
