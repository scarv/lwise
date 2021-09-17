#!/bin/bash

# Copyright (C) 2021 SCARV project <info@scarv.org>
#
# Use of this source code is restricted per the MIT license, a copy of which 
# can be found at https://opensource.org/licenses/MIT (or should be included 
# as LICENSE.txt within the associated archive or repository).

source ${REPO_HOME}/src/sw-toolchain/share.sh

# =============================================================================

if [ ! -d ${PK_REPO} ] ; then
  git clone https://github.com/riscv/riscv-pk.git ${PK_REPO}
fi

cd ${PK_REPO}
git fetch origin ${PK_COMMIT}:${BRANCH}
git checkout ${BRANCH}

# =============================================================================
