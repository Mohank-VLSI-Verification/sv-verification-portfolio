# UART UVM Testbench Makefile
# Vivado XSIM 2025.2 + UVM 1.2, Git Bash on Windows

RTL      = ../rtl/uart_rtl.sv
SVA      = ../assertions/uart_sva.sv
TB       = ../tb/uart_tb.sv

SIM      = uart_sim
COV_DIR  = cov_db
COV_NAME = uart_cov
REPORT   = cov_report

.PHONY: all compile elab sim cov clean

all: compile elab sim cov

compile:
	xvlog --sv -L uvm $(SVA) $(RTL) $(TB)

elab:
	xelab tb -L uvm --debug typical --timescale 1ns/1ps -cov_db_dir $(COV_DIR) -cov_db_name $(COV_NAME) -s $(SIM)

sim:
	xsim $(SIM) --tclbatch run.tcl

cov:
	xcrg -dir $(COV_DIR) -report_dir $(REPORT) -report_format html

clean:
	rm -rf xsim.dir $(COV_DIR) $(REPORT) *.jou *.log *.pb *.wdb