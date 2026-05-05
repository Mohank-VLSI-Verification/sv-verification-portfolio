// =============================================================================
// FIFO Assertions: SVA properties for FIFO behavior
// =============================================================================

module fifo_assertions (
  input logic       clk,
  input logic       rst,
  input logic       wr,
  input logic       rd,
  input logic       full,
  input logic       empty,
  input logic [7:0] din,
  input logic [7:0] dout
);

  // -------------------------------------------------------------------------
  // Property 1: No write when full
  // If FIFO is full and write is asserted, data should NOT be accepted
  // (pointer and count should not change — checked via full staying high)
  // -------------------------------------------------------------------------
  property p_no_write_when_full;
    @(posedge clk) disable iff (rst)
      (full && wr && !rd) |=> full;
  endproperty

  assert property (p_no_write_when_full)
    else $error("[ASSERT] Write accepted when FIFO was full @ %0t", $time);

  // -------------------------------------------------------------------------
  // Property 2: No read when empty
  // If FIFO is empty and read is asserted, empty should remain high
  // -------------------------------------------------------------------------
  property p_no_read_when_empty;
    @(posedge clk) disable iff (rst)
      (empty && rd && !wr) |=> empty;
  endproperty

  assert property (p_no_read_when_empty)
    else $error("[ASSERT] Read accepted when FIFO was empty @ %0t", $time);

  // -------------------------------------------------------------------------
  // Property 3: Full and empty are mutually exclusive
  // FIFO cannot be both full and empty simultaneously
  // -------------------------------------------------------------------------
  property p_full_empty_mutex;
    @(posedge clk)
      !(full && empty);
  endproperty

  assert property (p_full_empty_mutex)
    else $error("[ASSERT] FIFO is both full and empty @ %0t", $time);

  // -------------------------------------------------------------------------
  // Property 4: After reset, FIFO must be empty and not full
  // -------------------------------------------------------------------------
  property p_reset_state;
    @(posedge clk)
      rst |=> (empty && !full);
  endproperty

  assert property (p_reset_state)
    else $error("[ASSERT] FIFO not empty after reset @ %0t", $time);

  // -------------------------------------------------------------------------
  // Property 5: Empty deasserts after a successful write
  // -------------------------------------------------------------------------
  property p_empty_clears_on_write;
    @(posedge clk) disable iff (rst)
      (empty && wr) |=> !empty;
  endproperty

  assert property (p_empty_clears_on_write)
    else $error("[ASSERT] FIFO still empty after write @ %0t", $time);

  // -------------------------------------------------------------------------
  // Property 6: Full deasserts after a successful read
  // -------------------------------------------------------------------------
  property p_full_clears_on_read;
    @(posedge clk) disable iff (rst)
      (full && rd && !wr) |=> !full;
  endproperty

  assert property (p_full_clears_on_read)
    else $error("[ASSERT] FIFO still full after read @ %0t", $time);

  // -------------------------------------------------------------------------
  // Coverage: Track assertion pass/fail
  // -------------------------------------------------------------------------
  cover property (p_no_write_when_full);
  cover property (p_no_read_when_empty);
  cover property (p_full_empty_mutex);
  cover property (p_reset_state);
  cover property (p_empty_clears_on_write);
  cover property (p_full_clears_on_read);

endmodule
