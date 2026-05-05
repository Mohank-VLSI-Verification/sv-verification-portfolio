// =============================================================================
// I2C Assertions: SVA properties for I2C protocol behavior
// =============================================================================

module i2c_assertions (
  input logic       clk,
  input logic       rst,
  input logic       newd,
  input logic       done,
  input logic       busy,
  input logic       ack_err,
  input logic       op
);

  // -------------------------------------------------------------------------
  // Property 1: Busy must assert after newd
  // -------------------------------------------------------------------------
  property p_busy_after_newd;
    @(posedge clk) disable iff (rst)
      $rose(newd) |-> ##[1:10] busy;
  endproperty

  assert property (p_busy_after_newd)
    else $error("[ASSERT] Busy did not assert after newd @ %0t", $time);

  // -------------------------------------------------------------------------
  // Property 2: Done must eventually assert after busy goes high
  // -------------------------------------------------------------------------
  property p_done_eventually;
    @(posedge clk) disable iff (rst)
      $rose(busy) |-> ##[1:100000] done;
  endproperty

  assert property (p_done_eventually)
    else $error("[ASSERT] Done never asserted after busy @ %0t", $time);

  // -------------------------------------------------------------------------
  // Property 3: Busy must deassert when done asserts
  // -------------------------------------------------------------------------
  property p_not_busy_on_done;
    @(posedge clk) disable iff (rst)
      $rose(done) |-> ##[0:5] !busy;
  endproperty

  assert property (p_not_busy_on_done)
    else $error("[ASSERT] Busy still high after done @ %0t", $time);

  // -------------------------------------------------------------------------
  // Property 4: Done and newd should not overlap
  // -------------------------------------------------------------------------
  property p_done_newd_mutex;
    @(posedge clk) disable iff (rst)
      !(done && newd);
  endproperty

  assert property (p_done_newd_mutex)
    else $error("[ASSERT] Done and newd both active @ %0t", $time);

  // -------------------------------------------------------------------------
  // Coverage
  // -------------------------------------------------------------------------
  cover property (p_busy_after_newd);
  cover property (p_done_eventually);
  cover property (p_not_busy_on_done);
  cover property (p_done_newd_mutex);

endmodule
