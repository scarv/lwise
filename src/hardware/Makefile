# Copyright (C) 2021 SCARV project <info@scarv.org>
#
# Use of this source code is restricted per the MIT license, a copy of which 
# can be found at https://opensource.org/licenses/MIT (or should be included 
# as LICENSE.txt within the associated archive or repository).

ifndef REPO_HOME
  $(error "execute 'source ./bin/conf.sh' to configure environment")
endif
ifndef REPO_VERSION
  $(error "execute 'source ./bin/conf.sh' to configure environment")
endif

ifndef RISCV_ROCKET
  $(error "set RISCV_ROCKET environment variable to point at the Rocket Chip toolchain installation")
endif

#ROCKETCHIP_REPO = ${REPO_HOME}/build/rocketchip
ifndef ROCKETCHIP_REPO
  $(error "set ROCKETCHIP_REPO environment variable to point at the Rocket Chip reposistory")
endif

export ALG  ?= alzette

export ARCH ?= rv32
export IMP  ?= rv32
export ISE  ?= cop
export CONF ?=

# =============================================================================
include ${REPO_HOME}/src/hardware/fpga/Makefile.in
include ${REPO_HOME}/src/hardware/rocketchip/Makefile.in
include ${REPO_HOME}/src/hardware/verilator/Makefile.in
include ${REPO_HOME}/src/hardware/yosys_synth/Makefile.in
# =============================================================================

export EMU_HAL  = ${REPO_HOME}/src/hardware/verilator/hal
export SOFTWARE = ${REPO_HOME}/src/software
export INCLUDES = ${SOFTWARE}/share ${SOFTWARE}/share/arch/${ARCH} ${SOFTWARE}/${ALG} ${SOFTWARE}/${ALG}/arch/${ARCH} ${SOFTWARE}/${ALG}/imp/${IMP} ${EMU_HAL}

export SOURCES  = $(wildcard $(addsuffix /*.c, ${INCLUDES}))
export SOURCES += $(wildcard $(addsuffix /*.S, ${INCLUDES}))
export HEADERS  = $(wildcard $(addsuffix /*.h, ${INCLUDES}))

MABI       = $(findstring i,$(ARCH:rv32=i))lp$(ARCH:rv%=%)
GCC_FLAGS  = -march=$(ARCH)imac -mabi=$(MABI)  -DPREALLOCATE=1 -mcmodel=medany
GCC_FLAGS += -fno-builtin-printf -static -nostartfiles -T  $(EMU_HAL)/test.ld
GCC_PREFIX = ${RISCV_ROCKET}/bin/riscv64-unknown-elf

export TARGET   = ${REPO_HOME}/build/driver_emu
# -----------------------------------------------------------------------------

${TARGET}.elf : ${SOURCES} ${HEADERS}
	${GCC_PREFIX}-gcc ${CONF} ${GCC_FLAGS} ${GCC_PATHS} $(addprefix -I ,${INCLUDES}) -std='gnu99' -O2 -o ${@} $(filter %.c, ${^}) $(filter %.S, ${^}) ${GCC_LIBS}

${TARGET}.asm : ${TARGET}.elf
	${GCC_PREFIX}-objdump --disassemble-all ${<} > ${@}

emulate: ${EMULATOR} ${TARGET}.elf
	${EMULATOR} -c -m 2100000 ${TARGET}.elf
emulate-debug : ${EMULATOR} ${TARGET}.elf
	${EMULATOR} -c -x 700000 -v ${REPO_HOME}/build/emu32_eval.vcd -m 2100000 ${<}

all   : ${TARGET}.elf ${TARGET}.asm

clean : 
	@rm --force ${TARGET}.elf
	@rm --force ${TARGET}.asm

# =============================================================================
