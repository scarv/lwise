# Xilinx Vivado script
# Version: Vivado 2018.2
# Function:
#   Generate a vivado project for the rocketchip SoC on sakura X board

set project_name [lindex $argv 0]
set orig_dir 	 [lindex $argv 1]
set work_dir 	 [lindex $argv 2]
set board		 [lindex $argv 3]
set part		 [lindex $argv 4]


# Set the directory path for the original project from where this script was exported
set orig_proj_dir [file normalize $work_dir/$project_name]

# Create project
create_project $project_name $work_dir/$project_name

# Set the directory path for the new project
set proj_dir [get_property directory [current_project]]

# Set project properties
set obj [get_projects $project_name]
set_property "default_lib" "xil_defaultlib" $obj
#set_property "board_part" "Sasebo" $obj
set_property "PART" $part $obj 
set_property "simulator_language" "Mixed" $obj

# Create 'sources_1' fileset (if not found)
if {[string equal [get_filesets -quiet sources_1] ""]} {
  create_fileset -srcset sources_1
}

# Set 'sources_1' fileset object
set files [list]
set vfiles [glob -directory $work_dir/$project_name/rtl_sources/ *.v]
foreach item $vfiles {
	lappend files [file normalize $item]
}
add_files -norecurse -fileset [get_filesets sources_1] $files

set_property verilog_define [list FPGA Differential_clock_capable_pin] [get_filesets sources_1] 

# Set 'sources_1' fileset properties
set_property "top" "system_top_wrapper" [get_filesets sources_1]

# Clock generator
create_ip -name clk_wiz -vendor xilinx.com -library ip -version 6.0 -module_name clk_wiz_0
set_property -dict [list \
                        CONFIG.PRIMITIVE {MMCM} \
						CONFIG.PRIM_SOURCE {Differential_clock_capable_pin} \
						CONFIG.PRIM_IN_FREQ {200.000} \
						CONFIG.MMCM_COMPENSATION {ZHOLD} \
						CONFIG.MMCM_DIVCLK_DIVIDE {1} \
						CONFIG.RESET_TYPE {ACTIVE_HIGH} \
						CONFIG.RESET_PORT {reset} \
						CONFIG.CLKOUT1_DRIVES {BUFG} \
						CONFIG.CLKOUT1_REQUESTED_OUT_FREQ {50.000}] \
    [get_ips clk_wiz_0]
generate_target {instantiation_template} [get_files $proj_dir/$project_name.srcs/sources_1/ip/clk_wiz_0_1/clk_wiz_0.xci]

# AXI PROTOCOL CONVERTER
create_ip -name axi_protocol_converter -vendor xilinx.com -library ip -version 2.1 -module_name axi_protocol_converter_0
set_property -dict [list \
                        CONFIG.SI_PROTOCOL {AXI4} \
						CONFIG.MI_PROTOCOL {AXI4LITE} \
						CONFIG.ADDR_WIDTH {31} \
                        CONFIG.DATA_WIDTH {32} \
						CONFIG.ID_WIDTH {4} \
                        CONFIG.READ_WRITE_MODE {READ_WRITE} \
                        CONFIG.TRANSLATION_MODE {2}] \
    [get_ips axi_protocol_converter_0]
generate_target {instantiation_template} [get_files $proj_dir/$project_name.srcs/sources_1/ip/axi_protocol_converter_0/axi_protocol_converter_0.xci]

# AXI CROSS-BAR
create_ip -name axi_crossbar -vendor xilinx.com -library ip -version 2.1 -module_name axi_crossbar_0
set_property -dict [list \
                        CONFIG.NUM_SI {1} \
                        CONFIG.NUM_MI {3} \
                        CONFIG.PROTOCOL {AXI4LITE} \
						CONFIG.ADDR_WIDTH {32} \
                        CONFIG.DATA_WIDTH {32} \
                        CONFIG.ADDR_RANGES {1} \
						CONFIG.M00_A00_BASE_ADDR {0x0000000060000000} \
                        CONFIG.M00_A00_ADDR_WIDTH {15} \
                        CONFIG.M01_A00_BASE_ADDR {0x0000000070000000} \
						CONFIG.M01_A00_ADDR_WIDTH {16} \
                        CONFIG.M02_A00_BASE_ADDR {0x0000000070600000} \
                        CONFIG.M02_A00_ADDR_WIDTH {16}] \
    [get_ips axi_crossbar_0]
generate_target {instantiation_template} [get_files $proj_dir/$project_name.srcs/sources_1/ip/axi_crossbar_0/axi_crossbar_0.xci]

#BRAM Controller
create_ip -name axi_bram_ctrl -vendor xilinx.com -library ip -version 4.0 -module_name axi_bram_ctrl_0
set_property -dict [list \
                        CONFIG.DATA_WIDTH {32} \
						CONFIG.MEM_DEPTH {8192} \
                        CONFIG.PROTOCOL {AXI4LITE} \
                        CONFIG.BMG_INSTANCE {EXTERNAL} \
                        CONFIG.SINGLE_PORT_BRAM {1} \
                        CONFIG.SUPPORTS_NARROW_BURST {0} \
                        CONFIG.ECC_TYPE {0}] \
	[get_ips axi_bram_ctrl_0]
generate_target {instantiation_template} [get_files $proj_dir/$project_name.srcs/sources_1/ip/axi_bram_ctrl_0/axi_bram_ctrl_0.xci]

#GPIO-Trigger
create_ip -name axi_gpio -vendor xilinx.com -library ip -version 2.0 -module_name axi_gpio_0
set_property -dict [list \
                        CONFIG.C_ALL_INPUTS {0} \
                        CONFIG.C_ALL_OUTPUTS {1} \
						CONFIG.C_GPIO_WIDTH {1} \
						CONFIG.C_IS_DUAL {0} \
						CONFIG.C_INTERRUPT_PRESENT {0}] \
	[get_ips axi_gpio_0]
generate_target {instantiation_template} [get_files $proj_dir/$project_name.srcs/sources_1/ip/axi_gpio_0/axi_gpio_0.xci]

#UART
create_ip -name axi_uartlite -vendor xilinx.com -library ip -version 2.0 -module_name axi_uartlite_0
set_property -dict [list \
						CONFIG.C_S_AXI_ACLK_FREQ_HZ_d {50} \
						CONFIG.C_BAUDRATE {115200} \
						CONFIG.C_DATA_BITS {8} \
						CONFIG.C_USE_PARITY {0}] \
	[get_ips axi_uartlite_0]
generate_target {instantiation_template} [get_files $proj_dir/$project_name.srcs/sources_1/ip/axi_uartlite_0/axi_uartlite_0.xci]




# Create 'constrs_1' fileset (if not found)
if {[string equal [get_filesets -quiet constrs_1] ""]} {
  create_fileset -constrset constrs_1
}

# Set 'constrs_1' fileset object
set obj [get_filesets constrs_1]

# Add/Import constrs file and set constrs file properties
set file "[file normalize "$orig_dir/board/$board/constraint/ioportmap.xdc"]"
set file_added [add_files -norecurse -fileset $obj $file]

# generate all IP source code
generate_target all [get_ips]

# force create the synth_1 path (need to make soft link in Makefile)
launch_runs -scripts_only synth_1


# suppress some not very useful messages
# warning partial connection
set_msg_config -id "\[Synth 8-350\]" -suppress
# info do synthesis
set_msg_config -id "\[Synth 8-256\]" -suppress
set_msg_config -id "\[Synth 8-638\]" -suppress
# BRAM mapped to LUT due to optimization
set_msg_config -id "\[Synth 8-3969\]" -suppress
# BRAM with no output register
set_msg_config -id "\[Synth 8-4480\]" -suppress
# DSP without input pipelining
set_msg_config -id "\[Drc 23-20\]" -suppress
# Update IP version
set_msg_config -id "\[Netlist 29-345\]" -suppress


# do not flatten design
set_property STEPS.SYNTH_DESIGN.ARGS.FLATTEN_HIERARCHY none [get_runs synth_1]
