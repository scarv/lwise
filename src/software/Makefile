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

export INCLUDES = ./share ./share/arch/${ARCH} ./${ALG} ./${ALG}/arch/${ARCH} ./${ALG}/imp/${IMP}

export SOURCES  = $(wildcard $(addsuffix /*.c, ${INCLUDES}))
export SOURCES += $(wildcard $(addsuffix /*.S, ${INCLUDES}))
export HEADERS  = $(wildcard $(addsuffix /*.h, ${INCLUDES}))

export TARGET   = ${REPO_HOME}/build/driver_${ALG}

# -----------------------------------------------------------------------------

include ./share/arch/${ARCH}/Makefile.in

${TARGET}.elf : ${SOURCES} ${HEADERS}
	${GCC_PREFIX}-gcc ${CONF} ${GCC_FLAGS} ${GCC_PATHS} $(addprefix -I ,${INCLUDES}) -std='gnu99' -Wall -O3 -o ${@} $(filter %.c, ${^}) $(filter %.S, ${^}) ${GCC_LIBS}

${TARGET}.asm : ${TARGET}.elf
	${GCC_PREFIX}-objdump --disassemble-all ${<} > ${@}

build : ${TARGET}.elf ${TARGET}.asm

run   : ${TARGET}.run

clean : 
	@rm --force ${TARGET}.elf
	@rm --force ${TARGET}.asm
	@rm --force ${TARGET}.run

# =============================================================================
