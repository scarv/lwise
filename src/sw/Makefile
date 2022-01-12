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

# include build-related content for architecture
include ./share/arch/${ARCH}/Makefile.in

# include build-related content for algorithm
include ./${ALG}/Makefile.in

# pass-through environment variable as macros for use in source code
ifeq "${IMP}" "nist"
GCC_FLAGS += -DALG="\"${ALG}\"" -DARCH="\"${ARCH}\"" -DIMP="\"${IMP}\""
else
GCC_FLAGS += -DALG="\"${ALG}\"" -DARCH="\"${ARCH}\"" -DIMP="\"${IMP}\"" -DLWISE
endif

# -----------------------------------------------------------------------------

export INCLUDES  = ./share ./share/nist ./share/arch/${ARCH} ./${ALG} ./${ALG}/arch/${ARCH} ./${ALG}/imp/${IMP} ${REPO_HOME}/build/${ALG} ${NIST_INCLUDES}

export SOURCES   = $(wildcard $(addsuffix /*.c, ${INCLUDES})) ${REPO_HOME}/build/${ALG}/kat.c ${NIST_SOURCES}
export SOURCES  += $(wildcard $(addsuffix /*.S, ${INCLUDES}))
export HEADERS   = $(wildcard $(addsuffix /*.h, ${INCLUDES})) ${REPO_HOME}/build/${ALG}/kat.h ${NIST_HEADERS}

export TARGETS  += ${REPO_HOME}/build/${ALG}
export TARGETS  += ${REPO_HOME}/build/${ALG}/kat.h
export TARGETS  += ${REPO_HOME}/build/${ALG}/kat.c
export TARGETS  += ${REPO_HOME}/build/${ALG}/driver-${ARCH}_${IMP}.elf
export TARGETS  += ${REPO_HOME}/build/${ALG}/driver-${ARCH}_${IMP}.asm

# -----------------------------------------------------------------------------

${REPO_HOME}/build/${ALG}       :
	@mkdir --parents ${@}

${REPO_HOME}/build/${ALG}/kat.h : ${NIST_KAT}
	@python3 ./share/kat.py --header < ${<} > ${@}
${REPO_HOME}/build/${ALG}/kat.c : ${NIST_KAT}
	@python3 ./share/kat.py --source < ${<} > ${@}

${REPO_HOME}/build/${ALG}/driver-${ARCH}_${IMP}.elf : ${SOURCES} 
	@${GCC_PREFIX}-gcc ${CONF} ${GCC_FLAGS} ${GCC_PATHS} $(addprefix -I ,${INCLUDES}) -std='gnu99' -Wall -O3 -o ${@} $(filter %.c, ${^}) $(filter %.S, ${^}) ${GCC_LIBS}

${REPO_HOME}/build/${ALG}/driver-${ARCH}_${IMP}.asm : ${REPO_HOME}/build/${ALG}/driver-${ARCH}_${IMP}.elf
	@${GCC_PREFIX}-objdump --disassemble-all ${<} > ${@}

build : ${TARGETS}

clean : 
	@rm --force --recursive ${TARGETS}

# =============================================================================
