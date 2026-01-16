`timescale 1ns / 1ps

module dds_phase_acc (
    input  logic        clk,        // System Clock (100MHz)
    input  logic        reset_n,    // Active Low Reset
    input  logic [31:0] phase_inc,  // Frequency Control Word (Step Size)
    output logic [11:0] phase_out   // Top 12 bits (Phase for the LUT)
);

    // 32-bit register to hold the current phase
    logic [31:0] phase_acc_reg;

    always_ff @(posedge clk) begin
        if (!reset_n) begin
            phase_acc_reg <= 32'h0;
        end else begin
            // Every clock cycle, we add the increment
            // The addition will naturally wrap around (overflow) back to 0
            phase_acc_reg <= phase_acc_reg + phase_inc;
        end
    end

    // PHASE TRUNCATION:
    // We don't need all 32 bits to look up a value in a table.
    // We take the top 12 bits (the Most Significant Bits).
    // This represents 2^12 = 4096 distinct angles on our circle.
    assign phase_out = phase_acc_reg[31:20];

endmodule