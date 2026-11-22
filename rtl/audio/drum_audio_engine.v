// Three independent percussion voices mixed in parallel with a 32-bit synth.
// Instantiates kick_drum, snare_drum and hihat_drum.
// KEY[1], KEY[2], KEY[3] are active-low drum buttons on the DE1-SoC.
module drum_audio_engine (
    input  wire               clk,
    input  wire               reset,
    input  wire               sample_tick,
    input  wire [2:0]         buttons_n,
    input  wire signed [31:0] synth_sample,
    output wire signed [31:0] mixed_sample,
    output wire [2:0]         trigger_pulses
);
    reg [2:0] pressed_meta;
    reg [2:0] pressed_sync;
    reg [2:0] pressed_previous;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            pressed_meta     <= 3'b000;
            pressed_sync     <= 3'b000;
            pressed_previous <= 3'b000;
        end else begin
            pressed_meta     <= ~buttons_n;
            pressed_sync     <= pressed_meta;
            pressed_previous <= pressed_sync;
        end
    end

    assign trigger_pulses = pressed_sync & ~pressed_previous;

    wire signed [15:0] kick_sample;
    wire signed [15:0] snare_sample;
    wire signed [15:0] hihat_sample;

    kick_drum kick (
        .clk(clk), .reset(reset), .sample_tick(sample_tick),
        .trigger(trigger_pulses[0]), .audio_out(kick_sample)
    );
    snare_drum snare (
        .clk(clk), .reset(reset), .sample_tick(sample_tick),
        .trigger(trigger_pulses[1]), .audio_out(snare_sample)
    );
    hihat_drum hihat (
        .clk(clk), .reset(reset), .sample_tick(sample_tick),
        .trigger(trigger_pulses[2]), .audio_out(hihat_sample)
    );

    // Drum samples are sign-extended and shifted to match the 32-bit
    // synthesizer's scale; the maximum combined amplitude fits in 32 bits.
    wire signed [31:0] kick_scaled  =
        $signed({{16{kick_sample[15]}}, kick_sample}) <<< 14;
    wire signed [31:0] snare_scaled =
        $signed({{16{snare_sample[15]}}, snare_sample}) <<< 14;
    wire signed [31:0] hihat_scaled =
        $signed({{16{hihat_sample[15]}}, hihat_sample}) <<< 14;

    assign mixed_sample = synth_sample + kick_scaled + snare_scaled + hihat_scaled;
endmodule
