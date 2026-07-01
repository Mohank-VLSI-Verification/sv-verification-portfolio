# ============================================================
# SPI UVM runtime script for Vivado XSIM
# ============================================================

log_wave -recursive *

run -all

puts "============================================"
puts " SPI Simulation complete - check UVM summary"
puts "============================================"

quit