`timescale 1ns / 1ps

module i2s_master (
    input  logic        clk_audio,  // 12.288 MHz
    input  logic        reset_n,
    input  logic [23:0] data_l,     // Left channel data
    input  logic [23:0] data_r,     // Right channel data
    
    // Physical I2S Pins
    output logic        i2s_sclk,
    output logic        i2s_lrclk,
    output logic        i2s_dout
);

    // 8-bit counter (0 to 255) to track the 256 cycles per sample
    logic [7:0] cnt = 0;
    
    // Internal registers to "freeze" the data so it doesn't change mid-transmission
    logic [23:0] left_reg, right_reg;

    always_ff @(posedge clk_audio) begin
        if (!reset_n) begin
            cnt <= 0;
            i2s_lrclk <= 0;
            i2s_sclk  <= 0;
            i2s_dout  <= 0;
        end else begin
            cnt <= cnt + 1;

            // 1. Generate LRCLK (Toggles every 128 cycles for 48kHz)
            // 0-127: Left Channel, 128-255: Right Channel
            i2s_lrclk <= cnt[7];

            // 2. Generate SCLK (Bit Clock)
            // We want 32 SCLK pulses per channel (64 total).
            // 256 / 64 = 4. So SCLK toggles every 2 audio clock cycles.
            i2s_sclk <= cnt[1];

            // 3. Serial Data Transmission (MSB First)
            // We latch the input data at the start of the frame
            if (cnt == 255) begin
                left_reg  <= data_l;
                right_reg <= data_r;
            end

            // I2S Standard: Data is shifted out starting at cycle 1 of the LRCLK phase
            // We use a case statement to pick the bit based on the counter
            if (cnt[7] == 0) begin // Left Phase
                // Bits 1 to 24 shift out the 24 bits of left_reg
                if (cnt[6:2] >= 1 && cnt[6:2] <= 24)
                    i2s_dout <= left_reg[24 - cnt[6:2]];
                else
                    i2s_dout <= 0;
            end else begin // Right Phase
                if (cnt[6:2] >= 1 && cnt[6:2] <= 24)
                    i2s_dout <= right_reg[24 - cnt[6:2]];
                else
                    i2s_dout <= 0;
            end
        end
    end

endmodule