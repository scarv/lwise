
set_property PACKAGE_PIN AB2 [get_ports k_clk_osc0_clk_p]
set_property PACKAGE_PIN AC2 [get_ports k_clk_osc0_clk_n]


set_property IOSTANDARD DIFF_HSTL_I [get_ports k_clk_osc0_clk_n]
set_property IOSTANDARD DIFF_HSTL_I [get_ports k_clk_osc0_clk_p]


set_property PACKAGE_PIN L23 [get_ports k_resetb]

set_property PACKAGE_PIN D19 [get_ports uart_rtl_0_rxd]
set_property PACKAGE_PIN N17 [get_ports uart_rtl_0_txd]

set_property PACKAGE_PIN P24 [get_ports {gpio_tri_o[0]}]
set_property PACKAGE_PIN G20 [get_ports {gpio_led[0]}]

set_property IOSTANDARD LVCMOS25 [get_ports {gpio_tri_o[0]}]
set_property IOSTANDARD LVCMOS25 [get_ports {gpio_led[0]}]

set_property IOSTANDARD LVCMOS25 [get_ports uart_rtl_0_txd]
set_property DRIVE 12 [get_ports uart_rtl_0_txd]
set_property SLEW SLOW [get_ports uart_rtl_0_txd]

set_property IOSTANDARD LVCMOS25 [get_ports uart_rtl_0_rxd]

set_property IOSTANDARD LVCMOS25 [get_ports k_resetb]





#set_property WRITE_WIDTH_A 4 [get_cells ram_reg_0_0]
