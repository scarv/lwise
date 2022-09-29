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

export ALG  ?= sparkle

export API  ?= aead
export ARCH ?= generic
export IMP  ?= nist
export ISE  ?= xalu

export CONF ?=

# -----------------------------------------------------------------------------

sw-toolchain-build :
	@make --directory="${REPO_HOME}/src/sw-toolchain" clone 
	@make --directory="${REPO_HOME}/src/sw-toolchain" apply 
	@make --directory="${REPO_HOME}/src/sw-toolchain" build
sw-toolchain-clean :
	@make --directory="${REPO_HOME}/src/sw-toolchain" clean

sw-build :
	@make --directory="${REPO_HOME}/src/sw" build
sw-run   :
	@make --directory="${REPO_HOME}/src/sw" run
sw-scan  :
	@make --directory="${REPO_HOME}/src/sw" scan
sw-clean :
	@make --directory="${REPO_HOME}/src/sw" clean

# -----------------------------------------------------------------------------

hw-toolchain-build :
	@make --directory="${REPO_HOME}/src/hw-toolchain" clone 
	@make --directory="${REPO_HOME}/src/hw-toolchain" build
hw-toolchain-clean :
	@make --directory="${REPO_HOME}/src/hw-toolchain" clean

hw-get-rocketchip :
	@make --directory="${REPO_HOME}/src/hw" rocketchip-clone
	@make --directory="${REPO_HOME}/src/hw" rocketchip-apply

fpga-hw : 
	@make --directory="${REPO_HOME}/src/hw" fpga-verilog
	@make --directory="${REPO_HOME}/src/hw" bitstream

fpga-update : 
	@make --directory="${REPO_HOME}/src/hw" update-bistream

fpga-run :
	@make --directory="${REPO_HOME}/src/hw" program-fpga
	@make --directory="${REPO_HOME}/src/hw" fpga-swclean fpga-run	

fpga-scan :
	@make --directory="${REPO_HOME}/src/hw" fpga-scan
# -----------------------------------------------------------------------------

clean :
	@rm --force --recursive ${REPO_HOME}/build/*

# =============================================================================
