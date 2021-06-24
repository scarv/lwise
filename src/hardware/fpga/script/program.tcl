# Xilinx Vivado script
# Version: Vivado 2015.4, able to run 18.2
# Function:
#   Download bitstream to FPGA

set bit [lindex $argv 1]
set device [lindex $argv 0]

puts "BITSTREAM: $bit"
puts "DEVICE: $device"

open_hw
connect_hw_server
set board ""
#foreach { target } [get_hw_targets] {
#    current_hw_target $target
open_hw_target
#    if { [get_hw_devices] == $device } {
#        set board [current_hw_target]
#        break
#    }

#}
#if { $board == "" } {
#    puts "Did not find board"
#    exit 1
#}
current_hw_device $device
set_property PROGRAM.FILE $bit [current_hw_device]
program_hw_devices [current_hw_device]
close_hw_target
