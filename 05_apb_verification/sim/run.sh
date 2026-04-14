# =============================================================================
# Simulation script for I2C verification — Vivado XSIM
# =============================================================================
# Note: I2C simulation is slowest due to 100kHz I2C clock vs 40MHz system clock

# Step 1: Compile
xvlog -sv ../rtl/i2c.sv ../tb/tb_top.sv ../assertions/i2c_assertions.sv

# Step 2: Elaborate
xelab -debug typical tb -s sim_snapshot

# Step 3: Run
xsim sim_snapshot -runall
