set_property PACKAGE_PIN E3 	 [get_ports k_clk_osc0_clk]
set_property IOSTANDARD LVCMOS33 [get_ports k_clk_osc0_clk]

#BTN[0] reset active high
set_property PACKAGE_PIN D9 	 [get_ports k_resetb]
set_property IOSTANDARD LVCMOS33 [get_ports k_resetb]

#IO0 on J4 header
set_property PACKAGE_PIN V15     [get_ports {gpio_tri_o[0]}]	
set_property IOSTANDARD LVCMOS33 [get_ports {gpio_tri_o[0]}]

#Led LD4
set_property PACKAGE_PIN H5 	 [get_ports {gpio_led[0]}]		
set_property IOSTANDARD LVCMOS33 [get_ports {gpio_led[0]}]

set_property PACKAGE_PIN D10 [get_ports uart_rtl_0_txd]
set_property PACKAGE_PIN A9  [get_ports uart_rtl_0_rxd]
set_property IOSTANDARD LVCMOS33 [get_ports uart_rtl_0_txd]
set_property IOSTANDARD LVCMOS33 [get_ports uart_rtl_0_rxd]



