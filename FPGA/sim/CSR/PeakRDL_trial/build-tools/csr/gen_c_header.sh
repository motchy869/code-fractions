#!/usr/bin/env bash

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

source $SCRIPT_DIR/common.sh

# Assumes that the base name of configuration TOML file and output C header file are equal to that of RDL file.
readonly CFG_FILE_PATH=${RDL_FILE_PATH%.*}.toml
readonly C_HEADER_FILE_NAME=$(basename ${RDL_FILE_PATH%.*}.h)
readonly C_HEADER_FILE_PATH=$C_HEADER_DIR/$C_HEADER_FILE_NAME

mkdir -p $C_HEADER_DIR
peakrdl c-header $RDL_FILE_PATH --peakrdl-cfg $CFG_FILE_PATH --type-style $TYPE_STYLE -o $C_HEADER_FILE_PATH

python3 $SCRIPT_DIR/sub-script/refactor_c_header.py $C_HEADER_FILE_PATH
