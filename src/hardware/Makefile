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
  $(error "set RISCV_ROCKET environment variable to point at Rocket Chip toolchain installation")
endif

# =============================================================================

include ${REPO_HOME}/src/hardware/rocketchip/Makefile.in
include ${REPO_HOME}/src/hardware/verilator/Makefile.in
include ${REPO_HOME}/src/hardware/yosys_synth/Makefile.in

# =============================================================================

ifndef ARCH
export ARCH     = rv64
endif
ifndef IMP
export IMP      = rv64
endif

export EMU_HAL  = ${REPO_HOME}/src/hardware/verilator/hal
export SOFTWARE = ${REPO_HOME}/src/software
export INCLUDES = ${SOFTWARE}/ ${SOFTWARE}/arch/${ARCH} ${SOFTWARE}/imp/${IMP}

export SOURCES  = $(wildcard ${SOFTWARE}/*.c ${SOFTWARE}/arch/${ARCH}/*.c ${SOFTWARE}/imp/${IMP}/*.c ${EMU_HAL}/*.c)
export SOURCES += $(wildcard ${SOFTWARE}/*.S ${SOFTWARE}/arch/${ARCH}/*.S ${SOFTWARE}/imp/${IMP}/*.S ${EMU_HAL}/*.S)
export HEADERS  = $(wildcard ${SOFTWARE}/*.h ${SOFTWARE}/arch/${ARCH}/*.h ${SOFTWARE}/imp/${IMP}/*.h)

MABI       = $(findstring i,$(ARCH:rv32=i))lp$(ARCH:rv%=%)
GCC_FLAGS  = -march=$(ARCH)imac -mabi=$(MABI)  -DPREALLOCATE=1 -mcmodel=medany
GCC_FLAGS += -fno-builtin-printf -static -nostartfiles -T  $(EMU_HAL)/test.ld
GCC_PATHS += -I${EMU_HAL}
GCC_PREFIX = ${RISCV_ROCKET}/bin/riscv64-unknown-elf

export EMULATOR = ${REPO_HOME}/build/emulator$(subst rv,,$(ARCH))
export TARGET   = ${REPO_HOME}/build/driver_emu
# -----------------------------------------------------------------------------

${TARGET}.elf : ${SOURCES} ${HEADERS}
	${GCC_PREFIX}-gcc ${CONF} ${GCC_FLAGS} ${GCC_PATHS} $(addprefix -I ,${INCLUDES}) -std='gnu99' -O2 -o ${@} $(filter %.c, ${^}) $(filter %.S, ${^}) ${GCC_LIBS}

${TARGET}.asm : ${TARGET}.elf
	${GCC_PREFIX}-objdump --disassemble-all ${<} > ${@}

emulate: ${EMULATOR} ${TARGET}.elf
	${EMULATOR} -c -m 2100000 ${TARGET}.elf
emulate-debug : ${EMULATOR} ${TARGET}.elf
	${EMULATOR} -c -x 50000 -v ${REPO_HOME}/build/emu32_eval.vcd -m 2100000 ${<}

all   : ${TARGET}.elf ${TARGET}.asm

clean : 
	@rm --force ${TARGET}.elf
	@rm --force ${TARGET}.asm

# =============================================================================
