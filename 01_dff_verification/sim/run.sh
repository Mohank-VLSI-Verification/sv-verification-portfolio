# =============================================================================
# Simulation script for Vivado XSIM
# =============================================================================
# Usage: 
#   cd sim/
#   source run.sh       (Linux/Mac)
#   Or run commands manually in Vivado Tcl console
# =============================================================================

# Step 1: Compile all SystemVerilog sources
xvlog -sv ../rtl/dff.sv ../tb/tb_top.sv ../assertions/dff_assertions.sv

# Step 2: Elaborate the design
xelab -debug typical tb -s sim_snapshot

# Step 3: Run simulation
xsim sim_snapshot -runall

# Step 4: (Optional) Open waveform viewer
# xsim sim_snapshot -gui
