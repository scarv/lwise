#!/bin/bash

# Copyright (C) 2019 SCARV project <info@scarv.org>
#
# Use of this source code is restricted per the MIT license, a copy of which
# can be found at https://opensource.org/licenses/MIT (or should be included
# as LICENSE.txt within the associated archive or repository).

if [ -z ${VIVADO_TOOL_DIR} ]; then
    echo "[ERROR]: No VIVADO_TOOL_DIR environment variable defined"
else 
	source $VIVADO_TOOL_DIR/settings64.sh
fi
