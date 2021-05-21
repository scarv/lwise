#!/bin/bash

# Copyright (C) 2021 SCARV project <info@scarv.org>
#
# Use of this source code is restricted per the MIT license, a copy of which 
# can be found at https://opensource.org/licenses/MIT (or should be included 
# as LICENSE.txt within the associated archive or repository).

# =============================================================================

export ROCKET_GNU_REPO="${REPO_HOME}/build/rocketchip-toolchain/riscv-gnu-toolchain"
export ROCKET_GNU_COMMIT="b468107e701433e1caca3dbc8aef8d40e0c967ed"
export ROCKET_GNU_PATCH="${REPO_HOME}/src/toolchain-rocket/riscv-gnu.patch"
export ROCKET_GNU_BUILD="${ROCKET_GNU_REPO}/build"

export ROCKET_FESVR_REPO="${REPO_HOME}/build/rocketchip-toolchain/riscv-fesvr"
export ROCKET_FESVR_COMMIT="21e48156e8dc2d0ac53bee50c72b022f95529651"
export ROCKET_FESVR_PATCH="${REPO_HOME}/src/toolchain-rocket/riscv-fesvr.patch"
export ROCKET_FESVR_BUILD="${ROCKET_FESVR_REPO}/build"

export BRANCH="scarv/alzette"

# =============================================================================
