`timescale 1ns / 1ps

module button_ctrl (
    input  logic        clk,
    input  logic        reset_n,
    input  logic [3:0]  btn,
    input  logic        mode_sel,      // SW3
    output logic signed [31:0] carrier_offset,
    output logic signed [31:0] mod_fcw_offset,
    output logic [1:0]  vol_step
);

    // 1. Synchronizers (to prevent metastability)
    logic [3:0] btn_sync_0, btn_sync_1;
    always_ff @(posedge clk) begin
        btn_sync_0 <= btn;
        btn_sync_1 <= btn_sync_0;
    end

    // 2. Debounce Logic for general buttons (1ms @ 100MHz)
    logic [16:0] count;
    logic [3:0]  btn_debounced;
    always_ff @(posedge clk) begin
        if (count < 17'd100_000) count <= count + 1;
        else begin
            count <= 0;
            btn_debounced <= btn_sync_1;
        end
    end

    // 3. Pitch/Mod Slide Clock
    logic [18:0] slide_clk;
    always_ff @(posedge clk) slide_clk <= slide_clk + 1;

    // 4. Offset Logic with "Fast-Track" Reset
    always_ff @(posedge clk) begin
        if (!reset_n) begin
            carrier_offset <= 32'sd0;
            mod_fcw_offset <= 32'sd0;
        end else begin
            // PRIORITY: If BTN3 is pressed (using sync signal directly for speed)
            if (btn_sync_1[3]) begin
                carrier_offset <= 32'sd0;
                mod_fcw_offset <= 32'sd0;
            end 
            // Otherwise, handle sliding
            else if (slide_clk == 0) begin
                if (mode_sel == 0) begin
                    if (btn_debounced[0])      carrier_offset <= carrier_offset + 32'sd20;
                    else if (btn_debounced[1]) carrier_offset <= carrier_offset - 32'sd20;
                end else begin
                    if (btn_debounced[0])      mod_fcw_offset <= mod_fcw_offset + 32'sd5;
                    else if (btn_debounced[1]) mod_fcw_offset <= mod_fcw_offset - 32'sd5;
                end
            end
        end
    end

    // 5. Volume Step Logic (Pulse Detection on BTN2)
    logic btn2_prev;
    always_ff @(posedge clk) begin
        if (!reset_n) begin
            vol_step <= 0;
            btn2_prev <= 0;
        end else begin
            btn2_prev <= btn_debounced[2];
            if (btn_debounced[2] && !btn2_prev) begin
                vol_step <= vol_step + 1;
            end
        end
    end

endmodule