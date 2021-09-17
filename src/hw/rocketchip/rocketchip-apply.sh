#!/bin/bash

# Copyright (C) 2021 SCARV project <info@scarv.org>
#
# Use of this source code is restricted per the MIT license, a copy of which 
# can be found at https://opensource.org/licenses/MIT (or should be included 
# as LICENSE.txt within the associated archive or repository).

source ${REPO_HOME}/src/hw/rocketchip/share.sh

# =============================================================================

cd ${ROCKETCHIP_REPO}
git apply ${ROCKETCHIP_PATCH}
git add --all

# =============================================================================

