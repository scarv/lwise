#!/bin/bash

# Copyright (C) 2021 SCARV project <info@scarv.org>
#
# Use of this source code is restricted per the MIT license, a copy of which 
# can be found at https://opensource.org/licenses/MIT (or should be included 
# as LICENSE.txt within the associated archive or repository).

source ${REPO_HOME}/src/rocket-toolchain/share.sh

# =============================================================================

cd ${ROCKET_FESVR_REPO}
git reset HEAD
git checkout .
git clean --force -d 

# =============================================================================
