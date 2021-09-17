#!/bin/bash

# Copyright (C) 2021 SCARV project <info@scarv.org>
#
# Use of this source code is restricted per the MIT license, a copy of which 
# can be found at https://opensource.org/licenses/MIT (or should be included 
# as LICENSE.txt within the associated archive or repository).

source ${REPO_HOME}/src/toolchain-hardware/share.sh

# =============================================================================

mkdir --parents ${RISCV_ROCKET}

if [ -d ${ROCKET_GNU_BUILD} ] ; then
    rm --force --recursive ${ROCKET_GNU_BUILD}
fi

mkdir --parents ${ROCKET_GNU_BUILD}

cd ${ROCKET_GNU_BUILD}
${ROCKET_GNU_REPO}/configure --prefix="${RISCV_ROCKET}" --enable-multilib --with-cmodel=medany
make -j4
# =============================================================================

