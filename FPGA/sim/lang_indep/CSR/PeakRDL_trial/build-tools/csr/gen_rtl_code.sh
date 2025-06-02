#!/usr/bin/env bash

set -u

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

source $SCRIPT_DIR/common.sh

# ---------- Generate CSR ----------
mkdir -p $RTL_DIR
peakrdl regblock $RDL_FILE_PATH -o $RTL_DIR --cpuif $CPUIF_NAME --type-style $TYPE_STYLE

readonly RDL_FILE_NAME=$(basename $RDL_FILE_PATH)
readonly CSR_RTL_FILE_NAME=${RDL_FILE_NAME%.*}.sv
readonly CSR_RTL_FILE_PATH=$RTL_DIR/$CSR_RTL_FILE_NAME

python3 $SCRIPT_DIR/sub-script/refactor_csr.py $CSR_RTL_FILE_PATH
python3 $SCRIPT_DIR/sub-script/gen_csr_header.py $CSR_RTL_FILE_PATH
# --------------------

# ---------- Generate UVM Register Model ----------
readonly UVM_REG_MODEL_RTL_FILE_NAME=${RDL_FILE_NAME%.*}_uvm_reg_model_pkg.svh
readonly UVM_REG_MODEL_RTL_FILE_PATH=$RTL_DIR/$UVM_REG_MODEL_RTL_FILE_NAME

mkdir -p $RTL_DIR
peakrdl uvm $RDL_FILE_PATH -o $UVM_REG_MODEL_RTL_FILE_PATH --type-style $TYPE_STYLE --use-factory

python3 $SCRIPT_DIR/sub-script/refactor_uvm_reg_model.py $UVM_REG_MODEL_RTL_FILE_PATH
# --------------------
