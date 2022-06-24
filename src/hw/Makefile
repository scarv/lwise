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

export PORT ?= /dev/ttyUSB0
export ALG  ?= sparkle
export API  ?= aead
export ARCH ?= rv32
export IMP  ?= rv32
export ISE  ?= xalu

# =============================================================================
include ${REPO_HOME}/src/hw/fpga/Makefile.in
include ${REPO_HOME}/src/hw/rocketchip/Makefile.in
include ${REPO_HOME}/src/hw/verilator/Makefile.in
include ${REPO_HOME}/src/hw/yosys_synth/Makefile.in
# =============================================================================


