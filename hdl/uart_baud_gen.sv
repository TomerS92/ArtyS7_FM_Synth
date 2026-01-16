`timescale 1ns / 1ps

module uart_baud_gen #(
    parameter int CLK_FREQ  = 100_000_000,
    parameter int BAUD_RATE = 115_200,
    parameter int OVERSAMPLE = 16
)(
    input  logic clk,
    input  logic reset_n,
    output logic tick       // High for one clk cycle at OVERSAMPLE * BAUD_RATE
);

    // Calculate the divisor: 100MHz / (115200 * 16) ≈ 54.25
    // As a HW engineer, we use an integer counter. 
    // 100 / 1.8432 = 54.253...
    // We will count to 54.
    localparam int DIVISOR = CLK_FREQ / (BAUD_RATE * OVERSAMPLE);
    
    logic [$clog2(DIVISOR)-1:0] count;

    always_ff @(posedge clk) begin
        if (!reset_n) begin
            count <= '0;
            tick  <= 1'b0;
        end else begin
            if (count == DIVISOR - 1) begin
                count <= '0;
                tick  <= 1'b1;
            end else begin
                count <= count + 1'b1;
                tick  <= 1'b0;
            end
        end
    end

endmodule