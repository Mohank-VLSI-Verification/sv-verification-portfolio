# ============================================================
# I2C UVM Verification Flow - Vivado XSIM
# ============================================================

# --- User-overridable ---
TEST          ?= test
SEED          ?= 1
UVM_VERBOSITY ?= UVM_LOW

# --- Paths (relative to sim/) ---
RTL_DIR := ../rtl
SVA_DIR := ../assertions
TB_DIR  := ../tb

# --- File lists ---
RTL_FILES := $(RTL_DIR)/i2c_rtl.sv
SVA_FILES := $(SVA_DIR)/i2c_sva.sv
TB_FILES  := $(TB_DIR)/i2c_tb.sv

TOP := tb

# ============================================================
.PHONY: all compile elab run cov clean help

all: compile elab run cov

compile:
	xvlog -sv -L uvm $(RTL_FILES) $(SVA_FILES) $(TB_FILES)

elab:
	xelab -L uvm --relax -debug typical \
	  -cc_type bcst -cov_db_dir ./cov_db -cov_db_name i2c_cov \
	  -timescale 1ns/1ps \
	  $(TOP) -s i2c_sim

run:
	xsim i2c_sim --tclbatch run.tcl

cov:
	xcrg -report_format html -report_dir ./cov_report -dir ./cov_db

clean:
	rmdir /s /q xsim.dir 2>nul
	rmdir /s /q cov_db 2>nul
	rmdir /s /q cov_report 2>nul
	del /q *.jou *.log *.pb *.wdb 2>nul

help:
	@echo "Targets : all | compile | elab | run | cov | clean"
	@echo "Example : make all"