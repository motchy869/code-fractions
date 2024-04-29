#!/usr/bin/env bash

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

source $SCRIPT_DIR/common.sh

peakrdl regblock $RDL_FILE_PATH -o $RTL_DIR --cpuif $CPUIF_NAME --type-style=$TYPE_STYLE

RDL_FILE_NAME=$(basename $RDL_FILE_PATH)
RTL_FILE_NAME=${RDL_FILE_NAME%.*}.sv
RTL_FILE_PATH=$RTL_DIR/$RTL_FILE_NAME

python3 $SCRIPT_DIR/refactor_sv_code.py $RTL_FILE_PATH
