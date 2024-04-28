#!/usr/bin/env bash

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

source $SCRIPT_DIR/common.sh

peakrdl regblock $RDL_FILE_PATH -o $RTL_DIR --cpuif $CPUIF_NAME --type-style=$TYPE_STYLE
