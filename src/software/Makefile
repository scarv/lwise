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

# =============================================================================

ifndef ARCH
export ARCH     = generic
endif
ifndef IMP
export IMP      = generic
endif

export INCLUDES = ./ ./arch/${ARCH} ./imp/${IMP}

export SOURCES  = $(wildcard ./*.c ./arch/${ARCH}/*.c ./imp/${IMP}/*.c)
export SOURCES += $(wildcard ./*.S ./arch/${ARCH}/*.S ./imp/${IMP}/*.S)
export HEADERS  = $(wildcard ./*.h ./arch/${ARCH}/*.h ./imp/${IMP}/*.h)

export TARGET   = ${REPO_HOME}/build/driver

include ./arch/${ARCH}/Makefile.in

# -----------------------------------------------------------------------------

${TARGET}.elf : ${SOURCES} ${HEADERS}
	@${GCC_PREFIX}-gcc ${CONF} ${GCC_FLAGS} ${GCC_PATHS} $(addprefix -I ,${INCLUDES}) -std='gnu99' -Wall -O3 -o ${@} $(filter %.c, ${^}) $(filter %.S, ${^}) ${GCC_LIBS}

${TARGET}.asm : ${TARGET}.elf
	@${GCC_PREFIX}-objdump --disassemble-all ${<} > ${@}

all   : ${TARGET}.elf ${TARGET}.asm

clean : 
	@rm --force ${TARGET}.elf
	@rm --force ${TARGET}.asm

# =============================================================================
