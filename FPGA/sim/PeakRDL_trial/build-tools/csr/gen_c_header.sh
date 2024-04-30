#!/usr/bin/env bash

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

source $SCRIPT_DIR/common.sh

# Assumes that the base name of configuration TOML file and output C header file are equal to that of RDL file.
CFG_FILE_PATH=${RDL_FILE_PATH%.*}.toml
C_HEADER_FILE_NAME=$(basename ${RDL_FILE_PATH%.*}.h)
C_HEADER_FILE_PATH=$C_HEADER_DIR/$C_HEADER_FILE_NAME

peakrdl c-header $RDL_FILE_PATH --peakrdl-cfg $CFG_FILE_PATH --type-style=$TYPE_STYLE -o $C_HEADER_FILE_PATH

python3 $SCRIPT_DIR/refactor_c_header.py $C_HEADER_FILE_PATH
