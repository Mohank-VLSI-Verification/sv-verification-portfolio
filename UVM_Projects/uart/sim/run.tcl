# ============================================================
# UART UVM runtime script for Vivado XSIM
# ============================================================

log_wave -recursive *

run -all

puts "============================================"
puts " UART Simulation complete - check UVM summary"
puts "============================================"

quit