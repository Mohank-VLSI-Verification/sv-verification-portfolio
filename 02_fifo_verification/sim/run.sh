# =============================================================================
# Simulation script for FIFO verification — Vivado XSIM
# =============================================================================

# Step 1: Compile
xvlog -sv ../rtl/fifo.sv ../tb/tb_top.sv ../assertions/fifo_assertions.sv

# Step 2: Elaborate
xelab -debug typical tb -s sim_snapshot

# Step 3: Run
xsim sim_snapshot -runall
