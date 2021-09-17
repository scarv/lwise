#!/bin/bash

# Copyright (C) 2021 SCARV project <info@scarv.org>
#
# Use of this source code is restricted per the MIT license, a copy of which 
# can be found at https://opensource.org/licenses/MIT (or should be included 
# as LICENSE.txt within the associated archive or repository).

source ${REPO_HOME}/src/toolchain-hardware/share.sh

# =============================================================================

if [ ! -d ${ROCKET_GNU_REPO} ] ; then
  git clone https://github.com/riscv/riscv-gnu-toolchain.git ${ROCKET_GNU_REPO}
fi

cd ${ROCKET_GNU_REPO}
git fetch origin ${ROCKET_GNU_COMMIT}:${BRANCH}
git checkout ${BRANCH}
git submodule update --init

# =============================================================================
