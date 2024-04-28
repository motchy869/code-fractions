#!/usr/bin/env bash

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

# You should change the following two variables to match your project.
RDL_DIR=$SCRIPT_DIR/../../src/rdl
DOC_DIR=$SCRIPT_DIR/../../build-out/doc/addr_map
RDL_FILE_PATH=$RDL_DIR/my_mod_csr.rdl
CPUIF_NAME=axi4-lite

# SystemVerilog struct type naming style.
# behaviour of "lexical" is described in "Generated type naming rules" in "SystemRDL 2.0 Register Description Language"
# "lexical" results in terrible struct type name.
TYPE_STYLE=hier