// Three 16-bit patterns = 48 bits of user-recordable events.
// Store button hits at the current step when RUN and RECORD are active.
// Playback retriggers drums at the stored steps; no PCM/audio is recorded.
module drum_pattern_memory(
    input  wire        clk,
    input  wire        reset,
    input  wire        run,
    input  wire        record_enable,
    input  wire        clear_pulse,
    input  wire [3:0]  step_index,
    input  wire        step_tick,
    input  wire [2:0]  live_triggers,
    output reg  [15:0] kick_pattern,
    output reg  [15:0] snare_pattern,
    output reg  [15:0] hihat_pattern,
    output wire [2:0]  playback_triggers
);
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            kick_pattern  <= 16'b0;
            snare_pattern <= 16'b0;
            hihat_pattern <= 16'b0;
        end else if (clear_pulse) begin
            kick_pattern  <= 16'b0;
            snare_pattern <= 16'b0;
            hihat_pattern <= 16'b0;
        end else if (run && record_enable) begin
            if (live_triggers[0]) kick_pattern[step_index]  <= 1'b1;
            if (live_triggers[1]) snare_pattern[step_index] <= 1'b1;
            if (live_triggers[2]) hihat_pattern[step_index] <= 1'b1;
        end
    end

    assign playback_triggers = (run && step_tick && !clear_pulse) ?
        {hihat_pattern[step_index], snare_pattern[step_index], kick_pattern[step_index]} :
        3'b000;
endmodule
