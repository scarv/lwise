# Copyright (C) 2021 SCARV project <info@scarv.org>
#
# Use of this source code is restricted per the MIT license, a copy of which 
# can be found at https://opensource.org/licenses/MIT (or should be included 
# as LICENSE.txt within the associated archive or repository).

ifndef REPO_HOME
  $(error "execute 'source ./bin/conf.sh' to configure environment")
endif

ROCKETCHIP_REPO = ${REPO_HOME}/build/rocketchip

ifndef RISCV_ROCKET
    $(error "The RISCV_ROCKET environment variable must be set to a valid toolchain.")
endif
export LD_LIBRARY_PATH = $(RISCV_ROCKET)/lib

FPGA       ?= $(REPO_HOME)/hardware/fpga
FPGA_BUILD ?= $(REPO_HOME)/build/fpga

SOC		?= rocket32_soc
BOARD	?= sakura-x

# building a SoC with Vivado for Xilinx FPGA, verifying and evaluating on FPGA platform
prog_mem = $(FPGA_BUILD)/$(TARGET)-$(SOC)-imp/prog-bin/prog.mem

verilog:
	$(MAKE) -C $(FPGA)/$(SOC) verilog          work_dir=$(FPGA_BUILD) extr_dir=$(REPO_HOME)/external
project-soc:
	$(MAKE) -C $(FPGA)/$(SOC) project          work_dir=$(FPGA_BUILD) TARGET=$(BOARD)
vivado:
	$(MAKE) -C $(FPGA)/$(SOC) vivado           work_dir=$(FPGA_BUILD) 
bitstream:
	$(MAKE) -C $(FPGA)/$(SOC) bitstream        work_dir=$(FPGA_BUILD)
bit-update:
	$(MAKE) -C $(FPGA)/$(SOC) bit-update       work_dir=$(FPGA_BUILD)
program-fpga:
	$(MAKE) -C $(FPGA)/$(SOC) program-updated  work_dir=$(FPGA_BUILD)
.PHONY: project-soc vivado bitstream verilog acquisition-firmware bit-update program-fpga


# compiling programs to run on FPGA
helloworld:
	$(MAKE) -C $(REPO_HOME)/csrc/helloworld all CORE=$(SOC) hal_dir=$(FPGA)/$(SOC)/hal work_dir=$(FPGA_BUILD)/helloworld
	{ echo '@00000000'; cat $(FPGA_BUILD)/helloworld/helloworld-$(SOC).hex;} >$(prog_mem)
led-flash:
	$(MAKE) -C $(REPO_HOME)/csrc/led_flash all CORE=$(SOC) hal_dir=$(FPGA)/$(SOC)/hal work_dir=$(FPGA_BUILD)/led_flash
	{ echo '@00000000'; cat $(FPGA_BUILD)/led_flash/led_flash-$(SOC).hex;} >$(prog_mem)

run_verify:
	$(MAKE) -C $(REPO_HOME)/csrc/run_verify all CORE=$(SOC) hal_dir=$(FPGA)/$(SOC)/hal work_dir=$(FPGA_BUILD)/run_verify
	{ echo '@00000000'; cat $(FPGA_BUILD)/run_verify/run_verify-$(SOC).hex;} >$(prog_mem)

run_eval:
	$(MAKE) -C $(REPO_HOME)/csrc/run_eval all CORE=$(SOC) hal_dir=$(FPGA)/$(SOC)/hal work_dir=$(FPGA_BUILD)/run_eval
	{ echo '@00000000'; cat $(FPGA_BUILD)/run_eval/run_eval-$(SOC).hex;} >$(prog_mem)

run32_eval:
	$(MAKE) -C $(REPO_HOME)/csrc/run32_eval all CORE=$(SOC) hal_dir=$(FPGA)/$(SOC)/hal work_dir=$(FPGA_BUILD)/run32_eval
	{ echo '@00000000'; cat $(FPGA_BUILD)/run32_eval/run32_eval-$(SOC).hex;} >$(prog_mem)

.PHONY: helloworld led-flash 

#--------------------------------------------------------------------
# Clean up
#--------------------------------------------------------------------
clean: clean-soft clean-proj
clean-soft:

clean-proj:
	$(MAKE) -C $(FPGA)/$(SOC) clean
clean-hard:
	$(MAKE) -C $(FPGA)/$(SOC) cleanall
cleanall: clean clean-hard
.PHONY: clean clean-soft clean-proj clean-hard cleanall
