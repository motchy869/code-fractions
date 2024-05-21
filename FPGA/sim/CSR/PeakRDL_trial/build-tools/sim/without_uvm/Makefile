# Makefile for Vivado Simulator
# Known to work with Vivado 2023.2.
# Based on [Vivado Simulator(xsim)でのロジックシミュレーションおよびデバッグ](https://qiita.com/vega77/items/be284e1fc955381d0dae), but modified.
#
# Example
#  $ make -f <path/to/this/Makefile> dump view
#
# Note:
#  1. All simulation output files & directories are created in `<path to Makefile>/sim_result` directory.
#  2. The current directory of the shell which calls this Makefile doesn't affect the result at all.
#
# Typical Usage:
#  1. make -f <path/to/this/Makefile> elab // Repeat this until all compilation error is resolved.
#  2. make -f <path/to/this/Makefile> dump // Run simulation and create .wdb file which records all signals.
#  3. To view waveform
#    3.1. If waveform viewer is not opened, `make -f <path/to/this/Makefile> wave` to open it.
#    3.2. If waveform viewer is already opened, Flow -> Open Static Simulation, then open all.wdb.
#  4. To debug
#    4.1. modify source files
#    4.2. File -> Close Simulation
#    4.3. Go to step 1.

MAKEFILE_DIR := $(abspath $(dir $(lastword $(MAKEFILE_LIST))))

#-------------- Config ------------------------
SHELL := /usr/bin/env bash
VIVADO_DIR := /tools/Xilinx/Vivado/2023.2
XVLOG := $(VIVADO_DIR)/bin/xvlog
XELAB := $(VIVADO_DIR)/bin/xelab
XSIM := $(VIVADO_DIR)/bin/xsim

WORKSPACE_DIR := $(MAKEFILE_DIR)/../../../
SIM_DIR := $(WORKSPACE_DIR)/build-out/sim
SRC_DIR := $(WORKSPACE_DIR)/src/rtl
# This defines an empty string.
INCLUDE_DIR :=

SIM_CONSOLE_LOG_FILE_PATH := $(SIM_DIR)/sim_console.log

SV_SRC_FILES = $(shell find $(SRC_DIR) -not -path '$(SRC_DIR)/tb/with_uvm/*' -type f -name "*.sv" | tr '\n' ' ')

TB_TOP := test_bench

DEFAULT_TIME_SCALE := 1ns/1ps

XVLOG_FLAGS := --incr --define ALLOW_NON_SYNTHESIZABLE
XELAB_FLAGS := --incr
#---------------------------------------------

#------------ Commands -----------------------
run: alone

# Run parsing and elaboration.
elab: $(SIM_DIR)/xsim.dir/debug/xsimk

# Run simulation and dump all waveforms.
dump: $(SIM_DIR)/xsim.dir/debug/xsimk $(SIM_DIR)/dump_all.tcl $(SIM_DIR)/all.wdb

# Open waveform viewer.
view: $(SIM_DIR)/all.wdb
	cd $(SIM_DIR) && \
	$(XSIM) all.wdb -gui &

# Run parsing, elaboration and simulation with GUI.
gui: $(SIM_DIR)/xsim.dir/debug/xsimk
	cd $(SIM_DIR) && \
	$(XSIM) debug -gui &

# Run parsing, elaboration and simulation.
once:
	cd $(SIM_DIR) && \
	$(XVLOG) $(XVLOG_FLAGS) -sv $(SV_SRC_FILES) $(shell [ ! -z "$(INCLUDE_DIR)" ] && echo "--include $(INCLUDE_DIR)") && \
	$(XELAB) $(TB_TOP) -timescale $(DEFAULT_TIME_SCALE) $(XELAB_FLAGS) -runall

# Run parsing, elaboration, then run stand-alone simulation executable.
alone: $(SIM_DIR)/xsim.dir/alone/axsim
	cd $(SIM_DIR) && \
	./axsim.sh

help: $(SIM_DIR)/help.txt
	cat $<

clean:
	rm -rf $(SIM_DIR)
#---------------------------------------------

#------------ Files --------------------------
$(SIM_DIR):
	mkdir -p $@

$(SIM_DIR)/xsim.dir/debug/xsimk: $(SIM_DIR) $(SV_SRC_FILES)
	cd $(SIM_DIR) && \
	$(XVLOG) $(XVLOG_FLAGS) -sv $(SV_SRC_FILES) $(shell [ ! -z "$INCLUDE_DIR" ] && echo "--include $INCLUDE_DIR") && \
	$(XELAB) $(TB_TOP) -timescale $(DEFAULT_TIME_SCALE) $(XELAB_FLAGS) -snapshot debug -debug all

$(SIM_DIR)/dump_all.tcl:
	cd $(SIM_DIR) && \
	echo 'log_wave -r * -verbose' > $@
	echo 'run all' >> $@
	echo 'quit' >> $@

$(SIM_DIR)/all.wdb: $(SIM_DIR)/xsim.dir/debug/xsimk $(SIM_DIR)/dump_all.tcl
	cd $(SIM_DIR) && \
	$(XSIM) debug -stats -tclbatch ./dump_all.tcl -wdb all.wdb

$(SIM_DIR)/xsim.dir/alone/axsim: $(SIM_DIR) $(SV_SRC_FILES)
	cd $(SIM_DIR) && \
	$(XVLOG) $(XVLOG_FLAGS) -sv $(SV_SRC_FILES) $(shell [ ! -z "$INCLUDE_DIR" ] && echo "--include $INCLUDE_DIR") && \
	$(XELAB) $(TB_TOP) -timescale $(DEFAULT_TIME_SCALE) $(XELAB_FLAGS) -snapshot alone -standalone

$(SIM_DIR)/help.txt:
	cd $(SIM_DIR) && \
	$(XVLOG) --help > $@
	$(XELAB) --help >> $@
	$(XSIM) --help >> $@
#---------------------------------------------
