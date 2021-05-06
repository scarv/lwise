#!/bin/bash

# Copyright (C) 2021 SCARV project <info@scarv.org>
#
# Use of this source code is restricted per the MIT license, a copy of which 
# can be found at https://opensource.org/licenses/MIT (or should be included 
# as LICENSE.txt within the associated archive or repository).

source ${REPO_HOME}/src/toolchain/share.sh

# =============================================================================

mkdir --parents ${RISCV_ALZETTE}

if [ -d ${SPIKE_BUILD} ] ; then
    rm --force --recursive ${SPIKE_BUILD}
fi

mkdir --parents ${SPIKE_BUILD}

export PATH="${RISCV}/bin:${PATH}"

cd ${SPIKE_BUILD}
${SPIKE_REPO}/configure --prefix="${RISCV_ALZETTE}" --target="riscv64-unknown-elf" --with-isa="rv32gc"
make
make install

# =============================================================================

