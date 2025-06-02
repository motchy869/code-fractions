#!/usr/bin/env bash

set -u

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

source $SCRIPT_DIR/common.sh

mkdir -p $DOC_DIR
peakrdl html $RDL_FILE_PATH -o $DOC_DIR
