# Makefile for Questa Sim
# Known to work with version Questa Sim Intel FPGA Starter Edition 2023.3
#
# Example
#  $ make -f <path/to/this/Makefile> elab
#  // TODO
#
# Note:
#  1. By default, all simulation output files & directories are created in `<path to Makefile>/sim_result` directory.
#  2. The current directory of the shell which calls this Makefile doesn't affect the result at all.
#
# Typical Usage:
#  1. make -f <path/to/this/Makefile> elab // Repeat this until all compilation error is resolved.
#  // TODO
#
# Helpful web pages:
# - [The ModelSim commands you need to know](https://vhdlwhiz.com/the-modelsim-commands-you-need-to-know/)
# - [ModelSim/QuestaSim シミュレーションバッチ実行のすすめ](https://www.paltek.co.jp/techblog/techinfo/240531_01)
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
INCLUDE_DIRS := $(shell find $(SRC_DIR) -type f -name "*.svh" | sed 's|/[^/]*$$||' | uniq | tr '\n' ' ')

TB_TOP := test_bench

# format: MACRO1_NAME[=MACRO1_VAL][,MACRO2_NAME[=MACRO2_VAL],...]
XVLOG_MACROS := ALLOW_NON_SYNTHESIZABLE

# -mfcu is for macro-based include guard.
XVLOG_FLAGS := -mfcu -lint=full -incr
#---------------------------------------------

#-------------- Auto-generated configs ------------------------
INCLUDE_DIRS_DIRECTIVE := $(foreach dir,$(INCLUDE_DIRS),+incdir+$(dir))
MACROS_DIRECTIVE := $(foreach macro,$(XVLOG_MACROS),+define+$(macro))

XVLOG_FLAGS += $(INCLUDE_DIRS_DIRECTIVE) $(MACROS_DIRECTIVE)
#---------------------------------------------

#------------ Commands -----------------------
# Runs compilation.
elab: $(SIM_DIR)/work/_info

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

$(SIM_DIR)/work/_info: $(SIM_DIR)/work $(SV_SRC_FILES)
	cd $(SIM_DIR) && \
	$(VLOG) -sv -work work $(XVLOG_FLAGS) $(SV_SRC_FILES)
#---------------------------------------------
