# =============================================================================
# Simulation script for SPI verification — Vivado XSIM
# =============================================================================

# Step 1: Compile
xvlog -sv ../rtl/spi.sv ../tb/tb_top.sv ../assertions/spi_assertions.sv

# Step 2: Elaborate
xelab -debug typical tb -s sim_snapshot

# Step 3: Run
xsim sim_snapshot -runall
