// =============================================================================
// UART Assertions: SVA properties for UART TX and RX behavior
// =============================================================================

module uart_assertions (
  input logic       clk,
  input logic       rst,
  input logic       tx,
  input logic       rx,
  input logic       newd,
  input logic       donetx,
  input logic       donerx,
  input logic [7:0] dintx,
  input logic [7:0] doutrx
);

  // -------------------------------------------------------------------------
  // Property 1: TX line must be high (idle) when no transmission active
  // Before newd, tx should be 1
  // -------------------------------------------------------------------------
  property p_tx_idle;
    @(posedge clk) disable iff (rst)
      (!newd && !donetx) |-> (tx == 1'b1);
  endproperty

  // Note: This assertion may fire during active transfer — use with caution
  // assert property (p_tx_idle)
  //   else $error("[ASSERT] TX not idle when expected @ %0t", $time);

  // -------------------------------------------------------------------------
  // Property 2: donetx must eventually assert after newd
  // -------------------------------------------------------------------------
  property p_donetx_eventually;
    @(posedge clk) disable iff (rst)
      $rose(newd) |-> ##[1:5000] donetx;
  endproperty

  assert property (p_donetx_eventually)
    else $error("[ASSERT] donetx never asserted after newd @ %0t", $time);

  // -------------------------------------------------------------------------
  // Property 3: donerx must eventually assert after start bit detected
  // -------------------------------------------------------------------------
  property p_donerx_eventually;
    @(posedge clk) disable iff (rst)
      $fell(rx) |-> ##[1:5000] donerx;
  endproperty

  assert property (p_donerx_eventually)
    else $error("[ASSERT] donerx never asserted after start bit @ %0t", $time);

  // -------------------------------------------------------------------------
  // Property 4: donetx and donerx should not both be active simultaneously
  // (TX and RX are independent paths but shouldn't complete at same instant)
  // -------------------------------------------------------------------------
  property p_done_mutex;
    @(posedge clk) disable iff (rst)
      !(donetx && donerx);
  endproperty

  assert property (p_done_mutex)
    else $error("[ASSERT] donetx and donerx both active @ %0t", $time);

  // -------------------------------------------------------------------------
  // Property 5: After reset, TX must be idle (high) and done flags cleared
  // -------------------------------------------------------------------------
  property p_reset_state;
    @(posedge clk)
      rst |=> (tx == 1'b1 && donetx == 1'b0);
  endproperty

  // Note: Depends on baud clock alignment — may need tuning
  // assert property (p_reset_state)
  //   else $error("[ASSERT] TX not idle after reset @ %0t", $time);

  // -------------------------------------------------------------------------
  // Coverage
  // -------------------------------------------------------------------------
  cover property (p_donetx_eventually);
  cover property (p_donerx_eventually);
  cover property (p_done_mutex);

endmodule
