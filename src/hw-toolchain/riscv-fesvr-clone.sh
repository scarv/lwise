#!/bin/bash

# Copyright (C) 2021 SCARV project <info@scarv.org>
#
# Use of this source code is restricted per the MIT license, a copy of which 
# can be found at https://opensource.org/licenses/MIT (or should be included 
# as LICENSE.txt within the associated archive or repository).

source ${REPO_HOME}/src/hw-toolchain/share.sh

# =============================================================================

if [ ! -d ${ROCKET_FESVR_REPO} ] ; then
  git clone https://github.com/riscvarchive/riscv-fesvr.git ${ROCKET_FESVR_REPO}
fi

cd ${ROCKET_FESVR_REPO}
git fetch origin ${ROCKET_FESVR_COMMIT}:${BRANCH}
git checkout ${BRANCH}
git submodule update --init

# =============================================================================
