#!/bin/bash

# Copyright (C) 2021 SCARV project <info@scarv.org>
#
# Use of this source code is restricted per the MIT license, a copy of which 
# can be found at https://opensource.org/licenses/MIT (or should be included 
# as LICENSE.txt within the associated archive or repository).

# =============================================================================

export PK_REPO="${REPO_HOME}/build/sw-toolchain/${ALG}-riscv-pk"
export PK_BUILD="${PK_REPO}/build"
export PK_COMMIT="7ae86fb97b792586493255f935f2f12ff068b13f"
export PK_PATCH="${REPO_HOME}/src/sw-toolchain/pk.patch_${ALG}"
export PK_INSTALL="${REPO_HOME}/build/sw-toolchain/${ALG}"

export SPIKE_REPO="${REPO_HOME}/build/sw-toolchain/${ALG}-riscv-isa-sim"
export SPIKE_BUILD="${SPIKE_REPO}/build"
export SPIKE_COMMIT="9bfa0940d8f5434e8e7eb3c88f159d609834ee67"
export SPIKE_PATCH="${REPO_HOME}/src/sw-toolchain/spike.patch_${ALG}"
export SPIKE_INSTALL="${REPO_HOME}/build/sw-toolchain/${ALG}"

export BRANCH="scarv/alzette"

# =============================================================================
