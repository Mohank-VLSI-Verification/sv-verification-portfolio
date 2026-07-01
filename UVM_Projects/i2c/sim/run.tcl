# ============================================================
# I2C UVM runtime script for Vivado XSIM
# ============================================================

log_wave -recursive *

run -all

puts "============================================"
puts " I2C Simulation complete - check UVM summary"
puts "============================================"

quit