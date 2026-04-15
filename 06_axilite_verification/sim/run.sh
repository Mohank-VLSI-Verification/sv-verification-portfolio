# =============================================================================
# Simulation script for Vivado XSIM
# =============================================================================
# Only 2 files needed: rtl/axilite.sv and tb/tb_top.sv
# tb_top.sv is self-contained (all classes defined inside)
# =============================================================================

# Step 1: Compile (only 2 files)
xvlog -sv ../rtl/axilite.sv ../tb/tb_top.sv

# Step 2: Elaborate
xelab -debug typical tb -s sim_snapshot

# Step 3: Run
xsim sim_snapshot -runall
