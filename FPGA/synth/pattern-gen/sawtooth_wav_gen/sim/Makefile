# Makefile for Vivado Simulator
# Known to work with Vivado 2024.1.
# Based on [Vivado Simulator(xsim)でのロジックシミュレーションおよびデバッグ](https://qiita.com/vega77/items/be284e1fc955381d0dae), but modified.
#
# Example
#  $ make -f <path/to/this/Makefile> elab
#  $ make -f <path/to/this/Makefile> dump
#  $ make -f <path/to/this/Makefile> view
#  $ make -f <path/to/this/Makefile> covRpt
#
# Note:
#  1. All simulation output files & directories are created in `<path to Makefile>/sim_result` directory.
#  2. The current directory of the shell which calls this Makefile doesn't affect the result at all.
#
# Typical Usage:
#  1. make -f <path/to/this/Makefile> elab // Repeat this until all compilation error is resolved.
#  2. make -f <path/to/this/Makefile> dump // Run simulation and create .wdb file which records all signals.
#  3. To view waveform
#    3.1. If waveform viewer is not opened, `make -f <path/to/this/Makefile> view` to open it.
#    3.2. If waveform viewer is already opened, Flow -> Open Static Simulation, then open all.wdb.
#  4. To debug
#    4.1. modify source files
#    4.2. File -> Close Simulation
#    4.3. Go to step 1.

MAKEFILE_DIR := $(abspath $(dir $(lastword $(MAKEFILE_LIST))))

# ---------- config ----------
SHELL := /usr/bin/env bash
VIVADO_DIR := /tools/Xilinx/Vivado/2024.1
XVLOG := $(VIVADO_DIR)/bin/xvlog
XELAB := $(VIVADO_DIR)/bin/xelab
XSIM := $(VIVADO_DIR)/bin/xsim
XCRG := $(VIVADO_DIR)/bin/xcrg

SIM_DIR := $(MAKEFILE_DIR)/sim_result
SRC_DIR := $(MAKEFILE_DIR)/../src
# This defines an empty string.
INCLUDE_DIR :=

SIM_CONSOLE_LOG_FILE_PATH := $(SIM_DIR)/sim_console.log
SV_SRC_FILES := $(shell find $(SRC_DIR) -type f -name "*.sv" | tr '\n' ' ')

TB_TOP := test_bench

DEFAULT_TIME_SCALE := 1ns/1ps

XVLOG_FLAGS := --incr --define UNDER_SIMULATION --define ALLOW_NON_SYNTHESIZABLE
XELAB_FLAGS := --incr
XSIM_FLAGS := -stats

# 0/1: not/use
USE_UVM := 0
UVM_TESTNAME :=
ifeq ($(USE_UVM), 1)
	XVLOG_FLAGS += -L uvm -uvm_version 1.2
	XELAB_FLAGS += -L uvm -uvm_version 1.2
# XSIM_FLAGS += --testplusarg "UVM_CONFIG_DB_TRACE"
	XSIM_FLAGS += --testplusarg "UVM_TESTNAME=$(UVM_TESTNAME)"
	XSIM_FLAGS += --testplusarg "UVM_VERBOSITY=UVM_MEDIUM"
endif

# Code coverage options
# s: statement, b: branch, c: condition, t: toggle
CODE_COV_TYPE := sbct
# --------------------

# ---------- auto-generated configs ----------
INCLUDE_DIR_DIRECTIVE = $(shell [ ! -z "$(INCLUDE_DIR)" ] && echo "--include $(INCLUDE_DIR)")
CODE_COV_TYPE_DIRECTIVE = $(shell [ ! -z "$(CODE_COV_TYPE)" ] && echo "--cc_type $(CODE_COV_TYPE)")

XVLOG_FLAGS += $(INCLUDE_DIR_DIRECTIVE)
XELAB_FLAGS += $(CODE_COV_TYPE_DIRECTIVE)
# --------------------

# ---------- commands ----------
run: alone

# Run parsing and elaboration.
elab: $(SIM_DIR)/xsim.dir/debug/xsimk

# Run simulation and dump all waveforms.
dump: $(SIM_DIR)/all.wdb

# Open waveform viewer.
view: $(SIM_DIR)/all.wdb
	cd $(SIM_DIR) && \
	$(XSIM) $(XSIM_FLAGS) all.wdb -gui &

# Run parsing, elaboration and simulation with GUI.
gui: $(SIM_DIR)/xsim.dir/debug/xsimk
	cd $(SIM_DIR) && \
	$(XSIM) $(XSIM_FLAGS) debug -gui &

# Run parsing, elaboration and simulation.
once:
	cd $(SIM_DIR) && \
	$(XVLOG) $(XVLOG_FLAGS) -sv $(SV_SRC_FILES) $(INCLUDE_DIR_DIRECTIVE) && \
	$(XELAB) $(TB_TOP) -timescale $(DEFAULT_TIME_SCALE) $(XELAB_FLAGS) -runall

# Run parsing, elaboration, then run stand-alone simulation executable.
alone: $(SIM_DIR)/xsim.dir/alone/axsim
	cd $(SIM_DIR) && \
	./axsim.sh

# Generate code coverage report.
covRpt: $(SIM_DIR)/xsim.codeCov/debug
	cd $(SIM_DIR) && \
	$(XCRG) -db_name debug -cc_db debug -report_dir $(SIM_DIR) -report_format html

clean:
	rm -rf $(SIM_DIR)

help: $(SIM_DIR)/help.txt
	cat $<
# --------------------

# ---------- files ----------
$(SIM_DIR):
	mkdir -p $@

$(SIM_DIR)/xsim.dir/debug/xsimk: $(SIM_DIR) $(SV_SRC_FILES)
	cd $(SIM_DIR) && \
	$(XVLOG) $(XVLOG_FLAGS) -sv $(SV_SRC_FILES) && \
	$(XELAB) $(TB_TOP) -timescale $(DEFAULT_TIME_SCALE) $(XELAB_FLAGS) -snapshot debug -debug all

$(SIM_DIR)/dump_all.tcl:
	cd $(SIM_DIR) && \
	echo 'log_wave -r * -verbose' > $@
	echo 'run all' >> $@
	echo 'quit' >> $@

$(SIM_DIR)/all.wdb: $(SIM_DIR)/xsim.dir/debug/xsimk $(SIM_DIR)/dump_all.tcl
	cd $(SIM_DIR) && \
	$(XSIM) $(XSIM_FLAGS) debug -tclbatch ./dump_all.tcl -wdb all.wdb | tee $(SIM_CONSOLE_LOG_FILE_PATH)

$(SIM_DIR)/xsim.dir/alone/axsim: $(SIM_DIR) $(SV_SRC_FILES)
	cd $(SIM_DIR) && \
	$(XVLOG) $(XVLOG_FLAGS) -sv $(SV_SRC_FILES) && \
	$(XELAB) $(TB_TOP) -timescale $(DEFAULT_TIME_SCALE) $(XELAB_FLAGS) -snapshot alone -standalone

$(SIM_DIR)/xsim.codeCov/debug: $(SIM_DIR)/all.wdb

$(SIM_DIR)/help.txt:
	cd $(SIM_DIR) && \
	$(XVLOG) -help > $@
	$(XELAB) -help >> $@
	$(XSIM) -help >> $@
	$(XCRG) -help >> $@
# --------------------
