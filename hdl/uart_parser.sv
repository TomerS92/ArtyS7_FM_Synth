`timescale 1ns / 1ps

module uart_parser (
    input  logic        clk,
    input  logic        reset_n,
    input  logic        rx_ready,
    input  logic [7:0]  rx_data,
    output logic [31:0] phase_inc,    // F: Carrier Frequency
    output logic [15:0] amplitude,    // A: Volume
    output logic [1:0]  wave_select,  // W: Waveform
    output logic [31:0] mod_phase_inc,// M: Modulator Frequency
    output logic [15:0] mod_depth,    // D: Modulation Depth
    output logic        update_tick
);

    typedef enum logic { IDLE, DATA } state_t;
    state_t state = IDLE;

    logic [7:0]  current_cmd;
    logic [31:0] shift_reg;
    logic [3:0]  char_cnt;

    // Default Values
    logic [31:0] f_reg = 32'd18898; // 440 Hz
    logic [15:0] a_reg = 16'hFFFF;  // Max Vol
    logic [1:0]  w_reg = 2'b00;     // Sine
    logic [31:0] m_reg = 32'd215;   // ~5 Hz (Slow Vibrato)
    logic [15:0] d_reg = 16'h0200;  // Subtle Depth

    logic [4:0] hex_val;
    always_comb begin
        if (rx_data >= 8'h30 && rx_data <= 8'h39)      hex_val = {1'b1, rx_data[3:0]};
        else if (rx_data >= 8'h41 && rx_data <= 8'h46) hex_val = {1'b1, rx_data[3:0] + 4'd9};
        else if (rx_data >= 8'h61 && rx_data <= 8'h66) hex_val = {1'b1, rx_data[3:0] + 4'd9};
        else                                           hex_val = 5'h0;
    end

    always_ff @(posedge clk) begin
        if (!reset_n) begin
            state <= IDLE;
            f_reg <= 32'd18898; a_reg <= 16'hFFFF; w_reg <= 2'b00;
            m_reg <= 32'd215;   d_reg <= 16'h0200;
            update_tick <= 1'b0;
        end else begin
            update_tick <= 1'b0;
            if (rx_ready) begin
                // New Headers: F, A, W, M, D
                if (rx_data == "F" || rx_data == "f" || rx_data == "A" || rx_data == "a" || 
                    rx_data == "W" || rx_data == "w" || rx_data == "M" || rx_data == "m" || 
                    rx_data == "D" || rx_data == "d") begin
                    current_cmd <= rx_data;
                    char_cnt <= 0;
                    shift_reg <= 0;
                    state <= DATA;
                end else if (state == DATA && hex_val[4]) begin
                    shift_reg <= {shift_reg[27:0], hex_val[3:0]};
                    if (char_cnt == 7) begin
                        state <= IDLE;
                        update_tick <= 1'b1;
                        case (current_cmd)
                            "F", "f": f_reg <= {shift_reg[27:0], hex_val[3:0]};
                            "A", "a": a_reg <= shift_reg[15:0];
                            "W", "w": w_reg <= shift_reg[1:0];
                            "M", "m": m_reg <= {shift_reg[27:0], hex_val[3:0]};
                            "D", "d": d_reg <= shift_reg[15:0];
                        endcase
                    end else char_cnt <= char_cnt + 1'b1;
                end
            end
        end
    end

    assign phase_inc     = f_reg;
    assign amplitude     = a_reg;
    assign wave_select   = w_reg;
    assign mod_phase_inc = m_reg;
    assign mod_depth     = d_reg;

endmodule