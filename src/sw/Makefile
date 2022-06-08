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

# include build-related content for algorithm
include ./${ALG}/Makefile.in

# include build-related content for architecture
include ./share/arch/${ARCH}/Makefile.in

# parameterise source code using environment variables
ifeq "${API}" "aead"
GCC_FLAGS += -DAPI_AEAD
endif
ifeq "${API}" "hash"
GCC_FLAGS += -DAPI_HASH
endif
ifeq "${IMP}" "nist"
GCC_FLAGS += -DAPI="\"${API}\"" -DALG="\"${ALG}\"" ${CONF} -DARCH="\"${ARCH}\"" -DIMP="\"${IMP}\""
else
GCC_FLAGS += -DAPI="\"${API}\"" -DALG="\"${ALG}\"" ${CONF} -DARCH="\"${ARCH}\"" -DIMP="\"${IMP}\"" -DLWISE
endif

# -----------------------------------------------------------------------------

ifeq "${IMP}" "nist"
export LWISE_INCLUDES += ${REPO_HOME}/build/${ALG} ./share ./share/nist ./share/arch/${ARCH}
else
export LWISE_INCLUDES += ${REPO_HOME}/build/${ALG} ./share ./share/nist ./share/arch/${ARCH} ./${ALG}/arch/${ARCH} ./${ALG}/imp/${IMP} ./${ALG}/imp/share
endif

export LWISE_SOURCES  += $(wildcard $(addsuffix /*.c,   ${LWISE_INCLUDES})) 
export LWISE_SOURCES  += $(wildcard $(addsuffix /*.cpp, ${LWISE_INCLUDES})) 
export LWISE_SOURCES  += $(wildcard $(addsuffix /*.s,   ${LWISE_INCLUDES}))
export LWISE_SOURCES  += $(wildcard $(addsuffix /*.S,   ${LWISE_INCLUDES}))
export LWISE_HEADERS  += $(wildcard $(addsuffix /*.h,   ${LWISE_INCLUDES}))

export       INCLUDES := ${LWISE_INCLUDES} ${NIST_INCLUDES}

export       SOURCES  := ${LWISE_SOURCES}  ${NIST_SOURCES} ${REPO_HOME}/build/${ALG}/kat.c 
export       HEADERS  := ${LWISE_HEADERS}  ${NIST_HEADERS} ${REPO_HOME}/build/${ALG}/kat.h 

export       TARGETS  += ${REPO_HOME}/build/${ALG}
export       TARGETS  += ${REPO_HOME}/build/${ALG}/kat.h
export       TARGETS  += ${REPO_HOME}/build/${ALG}/kat.c
export       TARGETS  += ${REPO_HOME}/build/${ALG}/driver-${ARCH}_${IMP}.elf
export       TARGETS  += ${REPO_HOME}/build/${ALG}/driver-${ARCH}_${IMP}.asm

# -----------------------------------------------------------------------------

${REPO_HOME}/build/${ALG}       :
	@mkdir --parents ${@}

${REPO_HOME}/build/${ALG}/kat.h : ${NIST_KAT}
	@python3 ./share/kat.py --api="${API}" --header < ${<} > ${@}
${REPO_HOME}/build/${ALG}/kat.c : ${NIST_KAT}
	@python3 ./share/kat.py --api="${API}" --source < ${<} > ${@}

${REPO_HOME}/build/${ALG}/driver-${ARCH}_${IMP}.elf : ${SOURCES} 
	@${GCC_PREFIX}-gcc ${GCC_FLAGS} ${GCC_PATHS} $(addprefix -I ,${INCLUDES}) -std='gnu99' -O3 -o ${@} $(filter %.c, ${^}) $(filter %.cpp, ${^}) $(filter %.S, ${^}) ${GCC_LIBS}

${REPO_HOME}/build/${ALG}/driver-${ARCH}_${IMP}.asm : ${REPO_HOME}/build/${ALG}/driver-${ARCH}_${IMP}.elf
	@${GCC_PREFIX}-objdump --disassemble-all ${<} > ${@}

# -----------------------------------------------------------------------------

.PHONY : run debug scan

dump  :
	@echo "API        = ${API}"
	@echo "ALG        = ${ALG}"
	@echo "ARCH       = ${ARCH}"
	@echo "IMP        = ${IMP}"

	@echo "CONF       = ${CONF}"

	@echo "NIST_HOME  = ${NIST_HOME}"
	@echo "NIST_IMP   = ${NIST_IMP}"
	@echo "NIST_KAT   = ${NIST_KAT}"

	@echo "GCC_PREFIX = ${GCC_PREFIX}"
	@echo "GCC_PATHS  = ${GCC_PATHS}"
	@echo "GCC_FLAGS  = ${GCC_FLAGS}"
	@echo "GCC_LIBS   = ${GCC_LIBS}"

	@echo "INCLUDES   = ${INCLUDES}"
	@echo "SOURCES    = ${SOURCES}"
	@echo "HEADERS    = ${HEADERS}"
	@echo "TARGETS    = ${TARGETS}"

build : ${TARGETS}

clean : 
	@rm --force --recursive ${TARGETS}

# =============================================================================
