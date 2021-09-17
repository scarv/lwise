#!/bin/bash

# Copyright (C) 2021 SCARV project <info@scarv.org>
#
# Use of this source code is restricted per the MIT license, a copy of which 
# can be found at https://opensource.org/licenses/MIT (or should be included 
# as LICENSE.txt within the associated archive or repository).

source ${REPO_HOME}/src/hw/rocketchip/share.sh

# =============================================================================

if [ ! -d ${ROCKETCHIP_REPO} ] ; then
  git clone https://github.com/chipsalliance/rocket-chip.git ${ROCKETCHIP_REPO}
fi

cd ${ROCKETCHIP_REPO}
git fetch origin ${ROCKETCHIP_COMMIT}:${BRANCH}
git checkout ${BRANCH}
git submodule update --init

# =============================================================================
