RTL      = ../rtl/spi_rtl.sv
SVA      = ../assertions/spi_sva.sv
TB       = ../tb/spi_tb.sv

SIM      = spi_sim
COV_DIR  = cov_db
COV_NAME = spi_cov
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