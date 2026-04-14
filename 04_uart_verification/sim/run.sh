# =============================================================================
# Simulation script for UART verification — Vivado XSIM
# =============================================================================
# Note: UART sim takes longer due to baud rate clock division

# Step 1: Compile
xvlog -sv ../rtl/uart.sv ../tb/tb_top.sv ../assertions/uart_assertions.sv

# Step 2: Elaborate
xelab -debug typical tb -s sim_snapshot

# Step 3: Run
xsim sim_snapshot -runall
