#!/bin/bash

# Copyright (C) 2021 SCARV project <info@scarv.org>
#
# Use of this source code is restricted per the MIT license, a copy of which 
# can be found at https://opensource.org/licenses/MIT (or should be included 
# as LICENSE.txt within the associated archive or repository).

source ${REPO_HOME}/src/sw-toolchain/share.sh

# =============================================================================

if [ ! -d ${SPIKE_REPO} ] ; then
  git clone https://github.com/riscv/riscv-isa-sim.git ${SPIKE_REPO}
fi

cd ${SPIKE_REPO}
git fetch origin ${SPIKE_COMMIT}:${BRANCH}
git checkout ${BRANCH}

# =============================================================================
