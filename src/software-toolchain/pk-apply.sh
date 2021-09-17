#!/bin/bash

# Copyright (C) 2021 SCARV project <info@scarv.org>
#
# Use of this source code is restricted per the MIT license, a copy of which 
# can be found at https://opensource.org/licenses/MIT (or should be included 
# as LICENSE.txt within the associated archive or repository).

source ${REPO_HOME}/src/software-toolchain/share.sh

# =============================================================================

cd ${PK_REPO}

if [ -s ${PK_PATCH} ] ; then
  git apply ${PK_PATCH}
  git add --all
fi

# =============================================================================
