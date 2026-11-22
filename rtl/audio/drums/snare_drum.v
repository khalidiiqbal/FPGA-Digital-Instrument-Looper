module snare_drum (
    input wire clk,
    input wire reset,
    input wire sample_tick,
    input wire trigger,
    output reg signed [15:0] audio_out
);
    reg [15:0] lfsr;
    reg [15:0] envelope;
    reg playing;
    wire feedback;
    assign feedback =
        lfsr[15] ^ lfsr[13] ^
        lfsr[12] ^ lfsr[10];

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            lfsr <= 16'hACE1;
            envelope <= 0;
            playing <= 0;
            audio_out <= 0;
        end else begin
            if (trigger) begin
                envelope <= 16'hFFFF;
                playing <= 1;
            end
            if (sample_tick) begin
                if (playing) begin
                    lfsr <= {lfsr[14:0], feedback};
                    audio_out <= lfsr[0] ?
                        $signed({1'b0, envelope[14:0]}) :
                        -$signed({1'b0, envelope[14:0]});
                    if (envelope > 16'd500)
                        envelope <= envelope - 16'd500;
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
