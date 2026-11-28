// 16-step (sixteenth-note) clock for the 50 MHz DE1-SoC.
// Tempo: 0000 = 60 BPM, 0001 = 68 BPM, ... 1111 = 180 BPM.
// START emits step 0 immediately; STOP resets playback position to step 0.
module drum_step_clock #(
    parameter integer CLK_HZ = 50000000
)(
    input  wire       clk,
    input  wire       reset,
    input  wire       run,
    input  wire [3:0] tempo_sel,
    output reg  [3:0] step_index,
    output reg        step_tick
);
    reg [23:0] counter;
    reg was_running;
    reg [23:0] cycles_per_step;

    // Sixteenth note = 15/BPM seconds. Rounded to the nearest clock.
    always @(*) begin
        case (tempo_sel)
            4'd0:  cycles_per_step = (CLK_HZ*15+30)/60;
            4'd1:  cycles_per_step = (CLK_HZ*15+34)/68;
            4'd2:  cycles_per_step = (CLK_HZ*15+38)/76;
            4'd3:  cycles_per_step = (CLK_HZ*15+42)/84;
            4'd4:  cycles_per_step = (CLK_HZ*15+46)/92;
            4'd5:  cycles_per_step = (CLK_HZ*15+50)/100;
            4'd6:  cycles_per_step = (CLK_HZ*15+54)/108;
            4'd7:  cycles_per_step = (CLK_HZ*15+58)/116;
            4'd8:  cycles_per_step = (CLK_HZ*15+62)/124;
            4'd9:  cycles_per_step = (CLK_HZ*15+66)/132;
            4'd10: cycles_per_step = (CLK_HZ*15+70)/140;
            4'd11: cycles_per_step = (CLK_HZ*15+74)/148;
            4'd12: cycles_per_step = (CLK_HZ*15+78)/156;
            4'd13: cycles_per_step = (CLK_HZ*15+82)/164;
            4'd14: cycles_per_step = (CLK_HZ*15+86)/172;
            4'd15: cycles_per_step = (CLK_HZ*15+90)/180;
            default: cycles_per_step = (CLK_HZ*15+60)/120;
        endcase
    end

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            step_index  <= 4'd0;
            step_tick   <= 1'b0;
            counter     <= 24'd0;
            was_running <= 1'b0;
        end else begin
            step_tick   <= 1'b0;
            was_running <= run;
            if (!run) begin
                step_index <= 4'd0;
                counter <= 24'd0;
            end else if (!was_running) begin
                step_index <= 4'd0;
                counter <= 24'd0;
                step_tick <= 1'b1;
            end else if (counter >= cycles_per_step - 24'd1) begin
                counter <= 24'd0;
                step_index <= step_index + 4'd1;
                step_tick <= 1'b1;
            end else begin
                counter <= counter + 24'd1;
            end
        end
    end
endmodule
