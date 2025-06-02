#!/usr/bin/env bash

set -u

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

# You should change the following two variables to match your project.
readonly SRC_DIR=$SCRIPT_DIR/../../src
readonly RDL_DIR=$SRC_DIR/rdl
readonly RTL_DIR=$SRC_DIR/rtl/csr
readonly C_HEADER_DIR=$SRC_DIR/c_cpp/csr
readonly DOC_DIR=$SCRIPT_DIR/../../build-out/doc/addr_map
readonly RDL_FILE_PATH=$RDL_DIR/my_mod_csr.rdl

# flat type is more convenient than non-flat when designers have their own interface written in SV and want to use it.
#CPUIF_NAME=axi4-lite
readonly CPUIF_NAME=axi4-lite-flat

# SystemVerilog struct type naming style.
# behaviour of "lexical" is described in "Generated type naming rules" in "SystemRDL 2.0 Register Description Language"
# "lexical" results in terrible struct type name.
readonly TYPE_STYLE=hier
