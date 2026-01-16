`timescale 1ns / 1ps

module top (
    input  logic        clk_100mhz,// 100 MHz system clock
    input  logic        reset_n,// Active low reset
    input  logic [3:0]  btn,// Buttons for pitch up/down, volume up/down
    input  logic [3:0]  sw,// Switches for waveform select, mod enable, etc.
    input  logic        uart_rx,// UART interface
    output logic        uart_tx,// UART interface
    output logic        i2s_mclk,
    output logic        i2s_lrclk,
    output logic        i2s_sclk,// I2S audio clocks
    output logic        i2s_dout,// I2S audio outputs
    output logic [3:0]  led// Status LEDs
);

    logic clk_100, clk_audio, locked;
    clk_wiz_0 clk_gen (.clk_in1(clk_100mhz), .resetn(reset_n), .clk_100(clk_100), .clk_audio(clk_audio), .locked(locked));

    logic uart_tick, rx_ready, tx_done, tx_start;
    logic [7:0] rx_data, tx_data;
    uart_baud_gen #(.CLK_FREQ(100_000_000)) baud_gen (.clk(clk_100), .reset_n(reset_n && locked), .tick(uart_tick));
    uart_rx rx_inst (.clk(clk_100), .reset_n(reset_n && locked), .s_tick(uart_tick), .rx(uart_rx), .rx_done(rx_ready), .dout(rx_data));
    uart_tx tx_inst (.clk(clk_100), .reset_n(reset_n && locked), .s_tick(uart_tick), .din(tx_data), .tx_start(tx_start), .tx_done(tx_done), .tx(uart_tx));

    logic [31:0] uart_car_fcw, uart_mod_fcw;
    logic [15:0] uart_amp, uart_depth;
    logic [1:0]  uart_wave, vol_step;
    logic signed [31:0] pitch_offset, mod_offset;

    uart_parser parser (
        .clk(clk_100), .reset_n(reset_n && locked), .rx_ready(rx_ready), .rx_data(rx_data),
        .phase_inc(uart_car_fcw), .amplitude(uart_amp), .wave_select(uart_wave),
        .mod_phase_inc(uart_mod_fcw), .mod_depth(uart_depth), .update_tick()
    );

    button_ctrl buttons (
        .clk(clk_100), .reset_n(reset_n && locked), .btn(btn), .mode_sel(sw[3]),
        .carrier_offset(pitch_offset), .mod_fcw_offset(mod_offset), .vol_step(vol_step)
    );

    // --- MODULATOR ---
    logic [11:0] mod_phase;
    logic signed [23:0] mod_sine;
    logic [31:0] final_mod_fcw;
    // Explicit signed addition for the modulator freq
    assign final_mod_fcw = $unsigned($signed({1'b0, uart_mod_fcw}) + mod_offset);

    dds_phase_acc mod_acc (.clk(clk_100), .reset_n(reset_n && locked), .phase_inc(final_mod_fcw), .phase_out(mod_phase));
    sine_lut mod_lut (.clk(clk_100), .addr(mod_phase), .dout(mod_sine));

    // --- FM LOGIC (Musical Tuning) ---
    logic signed [39:0] mod_product;
    logic signed [31:0] freq_shift;
    assign mod_product = mod_sine * $signed({1'b0, uart_depth});
    
    // Shifting by 24 for a subtle, professional-sounding vibrato
    assign freq_shift = sw[2] ? (mod_product >>> 24) : 32'sd0;

    // --- CARRIER ---
    logic [11:0] car_phase;
    logic signed [23:0] sine_raw, wave_raw, scaled_audio;
    logic signed [32:0] car_fcw_signed;
    logic [31:0] final_car_fcw;
    
    always_comb begin
        car_fcw_signed = $signed({1'b0, uart_car_fcw}) + pitch_offset + freq_shift;
        if (car_fcw_signed < 0) final_car_fcw = 32'd0;
        else                   final_car_fcw = car_fcw_signed[31:0];
    end

    dds_phase_acc car_acc (.clk(clk_100), .reset_n(reset_n && locked), .phase_inc(final_car_fcw), .phase_out(car_phase));
    sine_lut car_lut (.clk(clk_100), .addr(car_phase), .dout(sine_raw));
    waveform_gen wave_mux (.phase(car_phase), .sine_in(sine_raw), .sel(sw[1:0]), .wave_out(wave_raw));

    // --- VOLUME ---
    logic [15:0] hw_vol;
    always_comb case(vol_step) 2'd0: hw_vol=16'hFFFF; 2'd1: hw_vol=16'h7FFF; 2'd2: hw_vol=16'h3FFF; default: hw_vol=0; endcase
    logic [31:0] combined_gain;
    assign combined_gain = (uart_amp[15:8] * hw_vol[15:8]);
    logic signed [39:0] vol_product;
    assign vol_product = wave_raw * $signed({1'b0, combined_gain[15:0]});
    assign scaled_audio = vol_product[38:15];

    // --- OUTPUTS ---
    i2s_master i2s (.clk_audio(clk_audio), .reset_n(reset_n && locked), .data_l(scaled_audio), .data_r(scaled_audio), .i2s_sclk(i2s_sclk), .i2s_lrclk(i2s_lrclk), .i2s_dout(i2s_dout));

    logic lrclk_prev, lrclk_tick;
    always_ff @(posedge clk_100) begin lrclk_prev <= i2s_lrclk; lrclk_tick <= (i2s_lrclk && !lrclk_prev); end
    visualizer_tx viz (.clk(clk_100), .reset_n(reset_n && locked), .sample_tick(lrclk_tick), .audio_data(scaled_audio), .tx_done(tx_done), .uart_din(tx_data), .uart_tx_start(tx_start));

    assign i2s_mclk = clk_audio;
    assign led = { (vol_step == 3), sw[3], sw[2], locked };

endmodule