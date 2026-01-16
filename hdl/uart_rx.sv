`timescale 1ns / 1ps

module uart_rx (
    input  logic        clk,
    input  logic        reset_n,
    input  logic        s_tick,     // 16x oversampling tick
    input  logic        rx,         // UART RX line
    output logic        rx_done,    // High for one cycle when byte is ready
    output logic [7:0]  dout        // Received byte
);

    // FSM States
    typedef enum logic [1:0] {
        IDLE  = 2'b00,
        START = 2'b01,
        DATA  = 2'b10,
        STOP  = 2'b11
    } state_t;

    state_t state_reg, state_next;
    
    // Internal registers
    logic [3:0] s_reg, s_next;     // Oversampling counter (0-15)
    logic [2:0] n_reg, n_next;     // Data bit counter (0-7)
    logic [7:0] b_reg, b_next;     // Shift register

    // State Register
    always_ff @(posedge clk) begin
        if (!reset_n) begin
            state_reg <= IDLE;
            s_reg     <= 4'b0;
            n_reg     <= 3'b0;
            b_reg     <= 8'b0;
        end else begin
            state_reg <= state_next;
            s_reg     <= s_next;
            n_reg     <= n_next;
            b_reg     <= b_next;
        end
    end

    // Next State Logic
    always_comb begin
        state_next = state_reg;
        s_next     = s_reg;
        n_next     = n_reg;
        b_next     = b_reg;
        rx_done    = 1'b0;

        case (state_reg)
            IDLE: begin
                if (~rx) begin          // Start bit detected (line goes low)
                    state_next = START;
                    s_next     = 0;
                end
            end

            START: begin
                if (s_tick) begin
                    if (s_reg == 7) begin // Reach the middle of start bit
                        state_next = DATA;
                        s_next     = 0;
                        n_next     = 0;
                    end else begin
                        s_next = s_reg + 1;
                    end
                end
            end

            DATA: begin
                if (s_tick) begin
                    if (s_reg == 15) begin // Reach the middle of a data bit
                        s_next = 0;
                        b_next = {rx, b_reg[7:1]}; // Shift in (LSB first)
                        if (n_reg == 7)
                            state_next = STOP;
                        else
                            n_next = n_reg + 1;
                    end else begin
                        s_next = s_reg + 1;
                    end
                end
            end

            STOP: begin
                if (s_tick) begin
                    if (s_reg == 15) begin // Reach the middle of stop bit
                        state_next = IDLE;
                        rx_done    = 1'b1;
                    end else begin
                        s_next = s_reg + 1;
                    end
                end
            end
        endcase
    end

    assign dout = b_reg;

endmodule