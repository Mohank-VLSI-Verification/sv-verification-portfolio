# ============================================================
# AXI UVM runtime script for Vivado XSIM
# ============================================================

# Log full hierarchy to WDB for post-sim waveform debug
log_wave -recursive *

# Run until UVM run_phase drops all objections (or $finish hit)
run -all

# Banner for log scanning
puts "============================================"
puts " AXI Simulation complete - check UVM summary"
puts "============================================"

quit