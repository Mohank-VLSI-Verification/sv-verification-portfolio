// =============================================================================
// DFF Assertions: SVA properties to verify D flip-flop behavior
// =============================================================================
// These assertions run continuously during simulation and flag violations
// at the exact cycle they occur — no waiting for the scoreboard.
// =============================================================================

module dff_assertions (
  input logic clk,
  input logic rst,
  input logic din,
  input logic dout
);

  // -------------------------------------------------------------------------
  // Property 1: Normal operation
  // When reset is not active, dout must equal the previous cycle's din
  // -------------------------------------------------------------------------
  property p_dff_normal;
    @(posedge clk) disable iff (rst)
      1'b1 |=> (dout == $past(din));
  endproperty

  assert property (p_dff_normal)
    else $error("[ASSERT] DFF output mismatch: dout=%0b, expected=%0b @ %0t",
                dout, $past(din), $time);

  // -------------------------------------------------------------------------
  // Property 2: Reset behavior
  // When reset is asserted, dout must be 0 on the next clock edge
  // -------------------------------------------------------------------------
  property p_dff_reset;
    @(posedge clk) rst |=> (dout == 1'b0);
  endproperty

  assert property (p_dff_reset)
    else $error("[ASSERT] DFF did not reset: dout=%0b, expected=0 @ %0t",
                dout, $time);

  // -------------------------------------------------------------------------
  // Property 3: Output stability
  // When reset is not active and din is stable, dout should remain stable
  // after capturing (checked 2 cycles: capture + hold)
  // -------------------------------------------------------------------------
  property p_dff_stable;
    @(posedge clk) disable iff (rst)
      (!rst && $stable(din)) |=> $stable(dout);
  endproperty

  assert property (p_dff_stable)
    else $error("[ASSERT] DFF output unstable when din is stable @ %0t", $time);

  // -------------------------------------------------------------------------
  // Coverage: Track assertion pass/fail for reporting
  // -------------------------------------------------------------------------
  cover property (p_dff_normal);
  cover property (p_dff_reset);
  cover property (p_dff_stable);

endmodule
