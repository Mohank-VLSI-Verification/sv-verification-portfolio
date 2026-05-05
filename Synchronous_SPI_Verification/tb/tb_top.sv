// =============================================================================
// tb_top: Top-level — instantiates SPI DUT, clock, environment, and assertions
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

  // Bind assertion module to DUT (top)
  bind top spi_assertions u_assert (
    .clk  (clk),
    .rst  (rst),
    .cs   (cs),
    .newd (newd),
    .done (done),
    .din  (din),
    .dout (dout)
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

endmodule