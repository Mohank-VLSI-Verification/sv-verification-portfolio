// =============================================================================
// tb_top: Top-level — instantiates SPI DUT, clock, and environment
// =============================================================================
// Note: vif.sclk is assigned from internal DUT signal (dut.m1.sclk)
//       This is a cross-module reference — fragile but necessary here
//       since sclk is generated inside the master, not exposed at top level.
// =============================================================================

module tb;

  spi_if vif();

  top dut (
    .clk  (vif.clk),
    .rst  (vif.rst),
    .newd (vif.newd),
    .din  (vif.din),
    .dout (vif.dout),
    .done (vif.done)
  );

  // Clock generation: 20ns period (50MHz)
  initial vif.clk <= 0;
  always #10 vif.clk <= ~vif.clk;

  // Cross-module reference to get internal sclk from master
  assign vif.sclk = dut.m1.sclk;

  environment env;

  initial begin
    env = new(vif);
    env.gen.count = 10;
    env.run();
  end

  initial begin
    $dumpfile("dump.vcd");
    $dumpvars;
  end

endmodule
