// =============================================================================
// tb_top: Top-level — instantiates FIFO DUT, clock, and environment
// =============================================================================

`include "transaction.sv"
`include "generator.sv"
`include "driver.sv"
`include "monitor.sv"
`include "scoreboard.sv"
`include "environment.sv"

module tb;

  fifo_if fif();

  FIFO dut (
    .clk      (fif.clock),
    .rst      (fif.rst),
    .wr       (fif.wr),
    .rd       (fif.rd),
    .din      (fif.data_in),
    .dout     (fif.data_out),
    .empty    (fif.empty),
    .full     (fif.full)
  );

  // Clock generation: 20ns period (50MHz)
  initial fif.clock <= 0;
  always #10 fif.clock <= ~fif.clock;

  // Test execution
  environment env;

  initial begin
    env = new(fif);
    env.gen.count = 30;
    env.run();
  end

  // Waveform dump
  initial begin
    $dumpfile("dump.vcd");
    $dumpvars;
  end

endmodule
