`timescale 1ns / 1ps

module uart_tx (
    input  logic        clk,
    input  logic        reset_n,
    input  logic        s_tick,     // 16x oversampling tick
    input  logic        tx_start,   // Trigger transmission
    input  logic [7:0]  din,        // Data to send
    output logic        tx_done,    // High when finished
    output logic        tx          // Physical TX line
);

    typedef enum logic [1:0] {IDLE, START, DATA, STOP} state_t;
    state_t state_reg, state_next;

    logic [3:0] s_reg, s_next;
    logic [2:0] n_reg, n_next;
    logic [7:0] b_reg, b_next;
    logic       tx_reg, tx_next;

    always_ff @(posedge clk) begin
        if (!reset_n) begin
            state_reg <= IDLE;
            s_reg <= 0;
            n_reg <= 0;
            b_reg <= 0;
            tx_reg <= 1'b1;
        end else begin
            state_reg <= state_next;
            s_reg <= s_next;
            n_reg <= n_next;
            b_reg <= b_next;
            tx_reg <= tx_next;
        end
    end

    always_comb begin
        state_next = state_reg;
        s_next = s_reg;
        n_next = n_reg;
        b_next = b_reg;
        tx_next = tx_reg;
        tx_done = 1'b0;

        case (state_reg)
            IDLE: begin
                tx_next = 1'b1;
                if (tx_start) begin
                    state_next = START;
                    s_next = 0;
                    b_next = din;
                end
            end
            START: begin
                tx_next = 1'b0;
                if (s_tick) begin
                    if (s_reg == 15) begin
                        state_next = DATA;
                        s_next = 0;
                        n_next = 0;
                    end else s_next = s_reg + 1;
                end
            end
            DATA: begin
                tx_next = b_reg[0];
                if (s_tick) begin
                    if (s_reg == 15) begin
                        s_next = 0;
                        b_next = b_reg >> 1;
                        if (n_reg == 7) state_next = STOP;
                        else n_next = n_reg + 1;
                    end else s_next = s_reg + 1;
                end
            end
            STOP: begin
                tx_next = 1'b1;
                if (s_tick) begin
                    if (s_reg == 15) begin
                        state_next = IDLE;
                        tx_done = 1'b1;
                    end else s_next = s_reg + 1;
                end
            end
        endcase
    end

    assign tx = tx_reg;

endmodule