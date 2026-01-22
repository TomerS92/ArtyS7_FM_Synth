# Clock Signal (100 MHz)
set_property -dict { PACKAGE_PIN R2    IOSTANDARD SSTL135 } [get_ports { clk_100mhz }];
create_clock -add -name sys_clk_pin -period 10.000 -waveform {0 5.000} [get_ports { clk_100mhz }];

# Reset Button (Mapped to ck_rst / C18)
set_property -dict { PACKAGE_PIN C18   IOSTANDARD LVCMOS33 } [get_ports { reset_n }];

# UART Interface (USB-UART Bridge)
set_property -dict { PACKAGE_PIN V12   IOSTANDARD LVCMOS33 } [get_ports { uart_rx }];
set_property -dict { PACKAGE_PIN R12   IOSTANDARD LVCMOS33 } [get_ports { uart_tx }];

# Pmod Header JB (Used for Pmod I2S2)
set_property -dict { PACKAGE_PIN P17   IOSTANDARD LVCMOS33 } [get_ports { i2s_mclk }];  # JB Pin 1
set_property -dict { PACKAGE_PIN P18   IOSTANDARD LVCMOS33 } [get_ports { i2s_lrclk }]; # JB Pin 2
set_property -dict { PACKAGE_PIN R18   IOSTANDARD LVCMOS33 } [get_ports { i2s_sclk }];  # JB Pin 3
set_property -dict { PACKAGE_PIN T18   IOSTANDARD LVCMOS33 } [get_ports { i2s_dout }];  # JB Pin 4

# User LED's
set_property -dict { PACKAGE_PIN E18   IOSTANDARD LVCMOS33 } [get_ports { led[0] }];
set_property -dict { PACKAGE_PIN F13   IOSTANDARD LVCMOS33 } [get_ports { led[1] }];
set_property -dict { PACKAGE_PIN E13   IOSTANDARD LVCMOS33 } [get_ports { led[2] }];
set_property -dict { PACKAGE_PIN H15   IOSTANDARD LVCMOS33 } [get_ports { led[3] }];

# Configuration
set_property BITSTREAM.CONFIG.CONFIGRATE 50 [current_design]
set_property CONFIG_VOLTAGE 3.3 [current_design]
set_property CFGBVS VCCO [current_design]
set_property BITSTREAM.CONFIG.SPI_BUSWIDTH 4 [current_design]
set_property CONFIG_MODE SPIx4 [current_design]

# Required setting for Bank 34 to use M5 (SW3) as a general IO
set_property INTERNAL_VREF 0.675 [get_iobanks 34]

# Switches
set_property -dict { PACKAGE_PIN H14   IOSTANDARD LVCMOS33 } [get_ports { sw[0] }];
set_property -dict { PACKAGE_PIN H18   IOSTANDARD LVCMOS33 } [get_ports { sw[1] }];
set_property -dict { PACKAGE_PIN G18   IOSTANDARD LVCMOS33 } [get_ports { sw[2] }];
set_property -dict { PACKAGE_PIN M5   IOSTANDARD LVCMOS33 } [get_ports { sw[3] }];
# Buttons
set_property -dict { PACKAGE_PIN G15   IOSTANDARD LVCMOS33 } [get_ports { btn[0] }];
set_property -dict { PACKAGE_PIN K16   IOSTANDARD LVCMOS33 } [get_ports { btn[1] }];
set_property -dict { PACKAGE_PIN J16   IOSTANDARD LVCMOS33 } [get_ports { btn[2] }];
set_property -dict { PACKAGE_PIN H13   IOSTANDARD LVCMOS33 } [get_ports { btn[3] }];