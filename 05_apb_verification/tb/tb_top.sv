// =============================================================================
// tb_top: Top-level — instantiates I2C DUT, clock, and environment
// =============================================================================

`include "transaction.sv"
`include "generator.sv"
`include "driver.sv"
`include "monitor.sv"
`include "scoreboard.sv"
`include "environment.sv"

module tb;

  i2c_if vif();

  i2c_top dut (
    .clk     (vif.clk),
    .rst     (vif.rst),
    .newd    (vif.newd),
    .op      (vif.op),
    .addr    (vif.addr),
    .din     (vif.din),
    .dout    (vif.dout),
    .busy    (vif.busy),
    .ack_err (vif.ack_err),
    .done    (vif.done)
  );

  // Clock generation: 10ns period (100MHz) — faster clock for I2C timing
  initial vif.clk <= 0;
  always #5 vif.clk <= ~vif.clk;

  environment env;

  initial begin
    env = new(vif);
    env.gen.count = 20;
    env.run();
  end

  initial begin
    $dumpfile("dump.vcd");
    $dumpvars;
  end

endmodule
