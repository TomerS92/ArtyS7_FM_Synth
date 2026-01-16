`timescale 1ns / 1ps

module waveform_gen (
    input  logic [11:0] phase,
    input  logic signed [23:0] sine_in, // Explicitly signed
    input  logic [1:0]  sel,
    output logic signed [23:0] wave_out
);

    // 1. Sawtooth
    logic signed [23:0] saw_wave;
    assign saw_wave = $signed({1'b0, phase, 11'b0}) - 24'sd8388608;

    // 2. Square: High (+Max) for first half, Low (-Max) for second half
    logic signed [23:0] sq_wave;
    // Using explicit decimal signed values for clarity
    assign sq_wave = (phase[11] == 0) ? 24'sd8388607 : -24'sd8388608;

    // 3. Triangle
    logic signed [23:0] tri_wave;
    always_comb begin
        if (phase[11] == 0)
            tri_wave = $signed({1'b0, phase[10:0], 12'b0}) - 24'sd4194304;
        else
            tri_wave = 24'sd4194304 - $signed({1'b0, phase[10:0], 12'b0});
    end

    // Mux
    always_comb begin
        case (sel)
            2'b00:   wave_out = sine_in;
            2'b01:   wave_out = saw_wave;
            2'b10:   wave_out = sq_wave;
            2'b11:   wave_out = tri_wave;
            default: wave_out = sine_in;
        endcase
    end

endmodule