// =============================================================================
// tb_top: Top-level — instantiates UART DUT, clock, and environment
// =============================================================================
// Cross-module references used for internal baud clocks (uclktx, uclkrx)
// =============================================================================

`include "transaction.sv"
`include "generator.sv"
`include "driver.sv"
`include "monitor.sv"
`include "scoreboard.sv"
`include "environment.sv"

module tb;

  uart_if vif();

  uart_top #(1000000, 9600) dut (
    .clk    (vif.clk),
    .rst    (vif.rst),
    .rx     (vif.rx),
    .dintx  (vif.dintx),
    .newd   (vif.newd),
    .tx     (vif.tx),
    .doutrx (vif.doutrx),
    .donetx (vif.donetx),
    .donerx (vif.donerx)
  );

  // Clock generation: 20ns period (50MHz)
  initial vif.clk <= 0;
  always #10 vif.clk <= ~vif.clk;

  // Cross-module references to internal baud clocks
  assign vif.uclktx = dut.utx.uclk;
  assign vif.uclkrx = dut.rtx.uclk;

  environment env;

  initial begin
    env = new(vif);
    env.gen.count = 5;
    env.run();
  end

  initial begin
    $dumpfile("dump.vcd");
    $dumpvars;
  end

endmodule
