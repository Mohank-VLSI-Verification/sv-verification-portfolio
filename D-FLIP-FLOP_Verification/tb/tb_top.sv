// =============================================================================
// tb_top: Top-level module — instantiates DUT, clock, and environment
// =============================================================================

module tb;

  dff_if vif();

  dff dut(vif);

  // Clock generation: 20ns period (50MHz)
  initial vif.clk <= 0;
  always #10 vif.clk <= ~vif.clk;

  // Test execution
  environment env;

  initial begin
    env = new(vif);
    env.gen.count = 30;
    env.run();
  end

  // Waveform dump for debugging
  initial begin
    $dumpfile("dump.vcd");
    $dumpvars;
  end

endmodule
