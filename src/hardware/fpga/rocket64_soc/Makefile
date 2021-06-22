
#--------------------------------------------------------------------
# global define
#--------------------------------------------------------------------

ifndef XILINX_VIVADO
$(error Please set environment variable XILINX_VIVADO for Xilinx tools)
endif

ifndef CCI_HOME
$(error Please set environment for Sakura-X board support package)
endif

CCI_HOME ?= $(abspath ../../)
CORE     ?= rocket-chachaise 
TARGET   ?= sakura-x
IMPL     ?= v1

extr_dir ?= $(abspath ../../external)
work_dir ?= $(abspath ../../work)

make_dir  = $(abspath .)
scal_dir  = $(make_dir)/src

core_dir  = $(extr_dir)/rocket-chip

coregen_dir  = $(core_dir)/vsim/generated-src

project_name = $(TARGET)-$(CORE)-imp

VIVADO = cd $(work_dir)/$(project_name) && vivado
UPDMEM = cd $(work_dir)/$(project_name) && updatemem
include $(CCI_HOME)/board/$(TARGET)/script/bsp


#--------------------------------------------------------------------
# Sources
#--------------------------------------------------------------------
rtl_sources = \
	$(work_dir)/$(project_name)/rtl_sources/system_top_wrapper.v \
	$(work_dir)/$(project_name)/rtl_sources/rocketcore.v \
	$(work_dir)/$(project_name)/rtl_sources/plusarg_reader.v \
	$(work_dir)/$(project_name)/rtl_sources/AsyncResetReg.v \
	$(work_dir)/$(project_name)/rtl_sources/cop_ise.v \

prog_mem = $(work_dir)/$(project_name)/prog-bin/prog.mem

#--------------------------------------------------------------------
# Build Verilog
#--------------------------------------------------------------------
ROCKET = freechips.rocketchip.system
MODEL  = SCARVRocketSystem
CONFIG = SCARVRocketCoPConfig
gen-verilog = $(coregen_dir)/$(ROCKET).$(CONFIG).v
$(gen-verilog): $(scal_dir)/*.scala
	$(MAKE) -C $(make_dir)/bootrom all
	cp -f $(make_dir)/bootrom/bootrom.img             $(core_dir)/bootrom/bootrom.img
	ln -s -f $(scal_dir)/SCARVRocketCoPConfig.scala   $(core_dir)/src/main/scala/system/SCARVRocketCoPConfig.scala
	ln -s -f $(scal_dir)/SCARVRocketSystem.scala      $(core_dir)/src/main/scala/system/SCARVRocketSystem.scala
	ln -s -f $(scal_dir)/SCARVRocketTest.scala        $(core_dir)/src/main/scala/system/SCARVRocketTest.scala
	ln -s -f $(scal_dir)/scarv_rocc.scala   		  $(core_dir)/src/main/scala/tile/scarv_rocc.scala
	$(MAKE) -C $(core_dir)/vsim verilog CONFIG=$(CONFIG) MODEL=$(MODEL)
#
verilog: $(gen-verilog) $(make_dir)/system_top_wrapper.v $(CCI_HOME)/rtl/chacha_ise_$(IMPL).v
	mkdir -p $(work_dir)/$(project_name)/rtl_sources
	mkdir -p $(work_dir)/$(project_name)/prog-bin
	cp -f $(make_dir)/system_top_wrapper.v                        $(work_dir)/$(project_name)/rtl_sources/system_top_wrapper.v
	cp -f $(coregen_dir)/$(ROCKET).$(CONFIG).v                    $(work_dir)/$(project_name)/rtl_sources/rocketcore.v
	cp -f $(coregen_dir)/$(ROCKET).$(CONFIG).behav_srams.v        $(work_dir)/$(project_name)/rtl_sources/memcore.v
	cp -f $(core_dir)/src/main/resources/vsrc/plusarg_reader.v    $(work_dir)/$(project_name)/rtl_sources/plusarg_reader.v
	cp -f $(core_dir)/src/main/resources/vsrc/AsyncResetReg.v     $(work_dir)/$(project_name)/rtl_sources/AsyncResetReg.v
	cp -f $(core_dir)/src/main/resources/vsrc/EICG_wrapper.v     $(work_dir)/$(project_name)/rtl_sources/EICG_wrapper.v
	cp -f $(CCI_HOME)/rtl/*.v                               	  $(work_dir)/$(project_name)/rtl_sources/
#	cp -f $(CCI_HOME)/rtl/chacha_ise_$(IMPL).v	              $(work_dir)/$(project_name)/rtl_sources/chacha_ise.v	


.PHONY: verilog

#--------------------------------------------------------------------
# Project generation
#--------------------------------------------------------------------
default: project
.PHONY: default

project = $(work_dir)/$(project_name)/$(project_name).xpr
project: $(project)
$(project): | $(rtl_sources)
	$(shell sed -i 's/CONFIG.PRIM_SOURCE.*/''CONFIG.PRIM_SOURCE {$(clktype)} \\''/g' script/make_project.tcl)
	$(shell sed -i 's/CONFIG.PRIM_IN_FREQ.*/''CONFIG.PRIM_IN_FREQ {$(inclock)} \\''/g' script/make_project.tcl)
	$(shell sed -i 's/set_property verilog_define.*/''set_property verilog_define \[list FPGA $(clktype)\] \[get_filesets sources_1\] ''/g' script/make_project.tcl)
	$(VIVADO) -mode batch -source $(make_dir)/script/make_project.tcl -tclargs $(project_name) $(CCI_HOME) $(work_dir) $(part) $(TARGET) 

vivado: $(project)
	$(VIVADO) $(project) &

bitstream = $(work_dir)/$(project_name)/$(project_name).runs/impl_1/system_top_wrapper.bit
bitstream: $(work_dir)/$(project_name)/prog.mmi
$(bitstream): $(rtl_sources) | $(project)
	$(VIVADO) -mode batch -source $(CCI_HOME)/fpga_soc/script/make_bitstream.tcl -tclargs $(project_name) $(work_dir)

program: $(bitstream)
	$(VIVADO) -mode batch -source $(CCI_HOME)/fpga_soc/script/program.tcl -tclargs $(device) $(bitstream)

.PHONY: project vivado bitstream program

#--------------------------------------------------------------------
# Update Program helper
#--------------------------------------------------------------------

search-ramb: $(work_dir)/$(project_name)/prog.mmi
$(work_dir)/$(project_name)/prog.mmi: $(bitstream)
	$(VIVADO) -mode batch -source $(CCI_HOME)/fpga_soc/script/search_ramb.tcl -tclargs $(project_name) $(work_dir) > $(work_dir)/$(project_name)/search-ramb.info
	python $(CCI_HOME)/fpga_soc/script/mmi_gen.py $(work_dir)/$(project_name)/search-ramb.info $(work_dir)/$(project_name)/prog.mmi 64 32768 $(part)

bit-update: $(work_dir)/$(project_name)/$(project_name).runs/impl_1/system_top_wrapper.new.bit
$(work_dir)/$(project_name)/$(project_name).runs/impl_1/system_top_wrapper.new.bit: $(prog_mem) $(work_dir)/$(project_name)/prog.mmi
	$(UPDMEM) -force -meminfo $(work_dir)/$(project_name)/prog.mmi -data $(prog_mem) -bit $(bitstream) -proc dummy -out $@

program-updated: $(work_dir)/$(project_name)/$(project_name).runs/impl_1/system_top_wrapper.new.bit
	$(VIVADO) -mode batch -source $(CCI_HOME)/fpga_soc/script/program.tcl -tclargs $(device) $(work_dir)/$(project_name)/$(project_name).runs/impl_1/system_top_wrapper.new.bit

.PHONY: search-ramb bit-update program-updated dis_bit

#--------------------------------------------------------------------
# Clean up
#--------------------------------------------------------------------

clean:
	rm -rf $(work_dir)/$(project_name)/*.log $(work_dir)/$(project_name)/*.jou $(junk)
cleanall: clean
	rm -fr $(work_dir)/$(project_name)

.PHONY: clean cleanall
