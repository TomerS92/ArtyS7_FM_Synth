`timescale 1ns / 1ps

module sine_lut (
    input  logic        clk,
    input  logic [11:0] addr, // 12-bit phase from NCO (0 to 4095)
    output logic [23:0] dout  // 24-bit signed amplitude
);

    // We define a memory array: 4096 entries, each 24 bits wide
    logic [23:0] rom [0:4095];

    // MATHEMATICAL INITIALIZATION
    // Vivado allows us to use an 'initial' block to pre-calculate values.
    // This happens during the "Synthesis" stage on your PC, not on the FPGA.
    // The resulting numbers are baked into the bitstream.
    initial begin
        real s;
        integer i;
        for (i = 0; i < 4096; i = i + 1) begin
            // 1. Calculate the angle in radians (0 to 2*pi)
            // 2. Calculate the sine of that angle
            // 3. Scale it to fit a 24-bit signed integer range
            //    Max positive: 2^23 - 1 = 8,388,607
            s = $sin(2.0 * 3.14159265 * i / 4096.0);
            rom[i] = $rtoi(s * 8388607.0);
        end
    end

    // Memory Read Logic
    // In BRAM, it is best practice to register the output to improve timing.
    always_ff @(posedge clk) begin
        dout <= rom[addr];
    end

endmodule