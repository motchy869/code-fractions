# Based on [Vivado Simulator(xsim)でのロジックシミュレーションおよびデバッグ](https://qiita.com/vega77/items/be284e1fc955381d0dae), but modified.
#
# Example
#  $ make -f <path/to/this/Makefile> dump view
#
# Note:
#  1. All simulation output files & directories are created in 'sim' directory.
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

SIM_DIR := $(MAKEFILE_DIR)
SRC_DIR := $(SIM_DIR)/../src
SRC_FILES := $(shell find $(SRC_DIR) -type f -name "*.sv" | tr '\n' ' ')

TB_TOP := test_bench
#---------------------------------------------

#------------ Commands -----------------------
run: alone

# Run parsing and elaboration.
elab: $(SIM_DIR)/xsim.dir/debug/xsimk

# Run simulation and dump all waveforms.
dump: $(SIM_DIR)/xsim.dir/debug/xsimk $(SIM_DIR)/dump_all.tcl
	cd $(SIM_DIR) && \
	$(XSIM) debug -t ./dump_all.tcl -wdb all.wdb

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
	$(XVLOG) -sv $(SRC_FILES) && \
	$(XELAB) $(TB_TOP) -R

# Run parsing, elaboration, then run stand-alone simulation executable.
alone: $(SIM_DIR)/xsim.dir/alone/axsim
	cd $(SIM_DIR) && \
	./axsim.sh

help: $(SIM_DIR)/help.txt
	cat $<

clean:
	cd $(SIM_DIR) && \
	rm -rf *.log *.jou *.pb xsim.dir *.sh *.wdb .Xil
#---------------------------------------------

#------------ Files --------------------------
$(SIM_DIR)/xsim.dir/alone/axsim: $(SRC_FILES)
	cd $(SIM_DIR) && \
	$(XVLOG) -sv $(SRC_FILES) && \
	$(XELAB) $(TB_TOP) -snapshot alone -standalone

$(SIM_DIR)/xsim.dir/debug/xsimk: $(SRC_FILES)
	cd $(SIM_DIR) && \
	$(XVLOG) -sv $(SRC_FILES) && \
	$(XELAB) $(TB_TOP) -snapshot debug -debug all

$(SIM_DIR)/dump_all.tcl:
	cd $(SIM_DIR) && \
	echo 'log_wave -r *' > $@
	echo 'run all' >> $@
	echo 'quit' >> $@

$(SIM_DIR)/help.txt:
	cd $(SIM_DIR) && \
	$(XVLOG) --help > $@
	$(XELAB) --help >> $@
	$(XSIM) --help >> $@
#---------------------------------------------
