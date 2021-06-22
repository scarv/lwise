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

export ALG  ?= alzette

export ARCH ?= rv32
export IMP  ?= rv32
export CONF ?=

# -----------------------------------------------------------------------------

toolchain :
	@make --directory="${REPO_HOME}/src/toolchain" clone 
	@make --directory="${REPO_HOME}/src/toolchain" apply 
	@make --directory="${REPO_HOME}/src/toolchain" build

software  :
	@make --directory="${REPO_HOME}/src//software" build
	@make --directory="${REPO_HOME}/src//software" run

clean     :
	@rm --force --recursive ${REPO_HOME}/build/*

# =============================================================================
