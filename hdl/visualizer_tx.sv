`timescale 1ns / 1ps

module visualizer_tx (
    input  logic        clk,
    input  logic        reset_n,
    input  logic        sample_tick,
    input  logic signed [23:0] audio_data, 
    input  logic        tx_done,
    output logic [7:0]  uart_din,
    output logic        uart_tx_start
);

    logic [3:0] sub_sample_cnt;
    
    // Convert signed audio to 8-bit unsigned.
    // We add an offset to center the wave at 128.
    logic [7:0] sample_byte;
    // Slicing bits [23:16] gives us the most significant 8 bits.
    // Flipping the sign bit (23) centers the audio.
    assign sample_byte = {~audio_data[23], audio_data[22:16]};

    always_ff @(posedge clk) begin
        if (!reset_n) begin
            sub_sample_cnt <= 0;
            uart_tx_start <= 0;
            uart_din <= 8'h80;
        end else begin
            uart_tx_start <= 0;
            if (sample_tick) begin
                if (sub_sample_cnt == 9) begin
                    sub_sample_cnt <= 0;
                    if (tx_done || uart_tx_start == 0) begin
                        uart_din <= sample_byte;
                        uart_tx_start <= 1'b1;
                    end
                end else sub_sample_cnt <= sub_sample_cnt + 1;
            end
        end
    end

endmodule