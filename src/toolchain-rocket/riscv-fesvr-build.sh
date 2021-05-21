#!/bin/bash

# Copyright (C) 2021 SCARV project <info@scarv.org>
#
# Use of this source code is restricted per the MIT license, a copy of which 
# can be found at https://opensource.org/licenses/MIT (or should be included 
# as LICENSE.txt within the associated archive or repository).

source ${REPO_HOME}/src/toolchain-rocket/share.sh

# =============================================================================

mkdir --parents ${RISCV_ROCKET}

if [ -d ${ROCKET_FESVR_BUILD} ] ; then
    rm --force --recursive ${ROCKET_FESVR_BUILD}
fi

mkdir --parents ${ROCKET_FESVR_BUILD}

export PATH="${RISCV_ROCKET}/bin:${PATH}"

cd ${ROCKET_FESVR_BUILD}
${ROCKET_FESVR_REPO}/configure --prefix="${RISCV_ROCKET}"
make
make install

# =============================================================================

