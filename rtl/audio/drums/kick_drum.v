module kick_drum (
    input wire clk,
    input wire reset,
    input wire sample_tick,
    input wire trigger,
    output reg signed [15:0] audio_out
);
    reg [15:0] phase;
    reg [15:0] envelope;
    reg playing;

    wire signed [15:0] amplitude;
    assign amplitude = envelope[15] ? 16'sd0 :
                       (envelope >> 1);

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            phase <= 0;
            envelope <= 0;
            playing <= 0;
            audio_out <= 0;
        end else begin
            if (trigger) begin
                phase <= 0;
                envelope <= 16'hFFFF;
                playing <= 1;
            end
            if (sample_tick) begin
                if (playing) begin
                    phase <= phase + 16'd900;
                    audio_out <= phase[15] ? -amplitude : amplitude;
                    if (envelope > 16'd300)
                        envelope <= envelope - 16'd300;
                    else begin
                        envelope <= 0;
                        playing <= 0;
                        audio_out <= 0;
                    end
                end else begin
                    audio_out <= 0;
                end
            end
        end
    end
endmodule
