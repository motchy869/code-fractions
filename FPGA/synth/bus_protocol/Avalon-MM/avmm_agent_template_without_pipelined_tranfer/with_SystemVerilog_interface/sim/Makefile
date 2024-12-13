# Makefile for Questa Sim
# Known to work with version Questa Sim Intel FPGA Starter Edition 2023.3
#
# Example
#  $ make -f <path/to/this/Makefile> cmp
#  $ make -f <path/to/this/Makefile> sim
#  $ make -f <path/to/this/Makefile> view &
#  $ make -f <path/to/this/Makefile> clean
#
# Note:
#  1. By default, all simulation output files & directories are created in `<path to Makefile>/sim_result` directory.
#  2. The current directory of the shell which calls this Makefile doesn't affect the result at all.
#
# Typical Usage:
#  1. make -f <path/to/this/Makefile> cmp // Repeat this until all compilation error is resolved.
#  2. make -f <path/to/this/Makefile> sim // Run simulation and create vsim.wlf file which records all signals.
#  3. To view the waveform,
#    3.1. If the GUI is not opened, `make -f <path/to/this/Makefile> view &` to open it. Note that the control immediately returns to the current shell.
#    3.2. If the GUI is already opened, run `dataset restart` in the transcript window to reload the waveform.
#
# Helpful web pages:
# - [The ModelSim commands you need to know](https://vhdlwhiz.com/the-modelsim-commands-you-need-to-know/)
# - [【入門】ModelSimの使い方　＜バッチスクリプト実行＞ ～ModelSim 2021.1　ModelSim Intel Edition, Microsemi Edition, ModelSim DE/PE/SE, QuestaSim対応版　～](https://www.paltek.co.jp/techblog/techinfo/210305_02)
# - vlog command syntax: http://www.pldworld.com/_hdl/2/_ref/se_html/manual_html/c_vcmds188.html

MAKEFILE_DIR := $(abspath $(dir $(lastword $(MAKEFILE_LIST))))

#-------------- Config ------------------------
SHELL := /usr/bin/env bash
QSIM_DIR := /tools/Siemens/intelFPGA/23.1std/questa_fse/bin
VLIB := $(QSIM_DIR)/vlib
VMAP := $(QSIM_DIR)/vmap
VLOG := $(QSIM_DIR)/vlog
VSIM := $(QSIM_DIR)/vsim

SIM_DIR := $(MAKEFILE_DIR)/sim_result
SRC_DIR := $(MAKEFILE_DIR)/../src

SV_SRC_FILES := $(shell find $(SRC_DIR) -type f -name "*.sv" | tr '\n' ' ')
SV_HEADER_FILES := $(shell find $(SRC_DIR) -type f -name "*.svh" | tr '\n' ' ')
INCLUDE_DIRS := $(shell find $(SRC_DIR) -type f -name "*.svh" | sed 's|/[^/]*$$||' | uniq | tr '\n' ' ')
COMPILE_LOG_FILE_PATH := $(SIM_DIR)/compile.log
SIM_LOG_FILE_PATH := $(SIM_DIR)/sim.log

TB_TOP := test_bench

# Pre-defined macros. format: MACRO1_NAME[=MACRO1_VAL][,MACRO2_NAME[=MACRO2_VAL],...]
PRE_DEF_MACROS := ALLOW_NON_SYNTHESIZABLE

# -mfcu is for macro-based include guard.
VLOG_FLAGS := -mfcu -lint=full -incr
VSIM_FLAGS := -c -voptargs="+acc" -do "add wave * -recursive; run -all; quit;"
#---------------------------------------------

#-------------- Auto-generated configs ------------------------
INCLUDE_DIRS_DIRECTIVE := $(foreach dir,$(INCLUDE_DIRS),+incdir+$(dir))
MACROS_DIRECTIVE := $(foreach macro,$(PRE_DEF_MACROS),+define+$(macro))

VLOG_FLAGS += -l $(COMPILE_LOG_FILE_PATH) $(INCLUDE_DIRS_DIRECTIVE) $(MACROS_DIRECTIVE)
VSIM_FLAGS += -l $(SIM_LOG_FILE_PATH)
#---------------------------------------------

#------------ Commands -----------------------
# Run compilation.
cmp: $(SIM_DIR)/work/_info

# Run simulation.
sim: $(SIM_DIR)/vsim.wlf

# View waveform.
view: $(SIM_DIR)/vsim.wlf
	cd $(SIM_DIR) && \
	$(VSIM) -view test=vsim.wlf
# The following way doesn't work.
# view: $(SIM_DIR)/vsim.wlf
# 	bash -c "cd $(SIM_DIR); $(VSIM) -view test=vsim.wlf" &

clean:
	rm -rf $(SIM_DIR)
#---------------------------------------------

#------------ Files --------------------------
$(SIM_DIR):
	mkdir -p $@

$(SIM_DIR)/work: $(SIM_DIR)
	cd $(SIM_DIR) && \
	$(VLIB) work && \
	$(VMAP) work work

# Questa Sim is clever enough to skip already-compiled files.
$(SIM_DIR)/work/_info: $(SIM_DIR)/work $(SV_SRC_FILES) $(SV_HEADER_FILES)
	cd $(SIM_DIR) && \
	$(VLOG) -sv -work work $(VLOG_FLAGS) $(SV_SRC_FILES)

$(SIM_DIR)/vsim.wlf: $(SIM_DIR)/work/_info
	cd $(SIM_DIR) && \
	$(VSIM) -L work $(VSIM_FLAGS) $(TB_TOP)
#---------------------------------------------
