// =============================================================================
// SPI Assertions: SVA properties for SPI protocol behavior
// =============================================================================

module spi_assertions (
  input logic        clk,
  input logic        rst,
  input logic        cs,
  input logic        newd,
  input logic        done,
  input logic [11:0] din,
  input logic [11:0] dout
);

  // -------------------------------------------------------------------------
  // Property 1: CS must go low after newd is asserted
  // When newd pulses (and cs is currently high), cs must drop within
  // one sclk period (~25 clk cycles)
  // -------------------------------------------------------------------------
  property p_cs_low_on_start;
    @(posedge clk) disable iff (rst)
      (newd && cs) |-> ##[1:25] !cs;
  endproperty
  ASSERT_CS_LOW_ON_START: assert property (p_cs_low_on_start)
    else $error("[ASSERT] CS did not go low after newd @ %0t", $time);

  // -------------------------------------------------------------------------
  // Property 2: Data integrity — dout must match din when done rises
  // -------------------------------------------------------------------------
  property p_data_integrity;
    @(posedge clk) disable iff (rst)
      $rose(done) |-> (dout == din);
  endproperty
  ASSERT_DATA_INTEGRITY: assert property (p_data_integrity)
    else $error("[ASSERT] Data mismatch: din=%h dout=%h @ %0t", din, dout, $time);

  // -------------------------------------------------------------------------
  // Property 3: CS must remain low for the entire transfer
  // Once cs falls, it should not rise until done is asserted
  // -------------------------------------------------------------------------
  property p_cs_stable;
    @(posedge clk) disable iff (rst)
      $fell(cs) |-> (!cs throughout (##[1:$] $rose(done)));
  endproperty
  ASSERT_CS_STABLE: assert property (p_cs_stable)
    else $error("[ASSERT] CS rose mid-transfer @ %0t", $time);

  // -------------------------------------------------------------------------
  // Coverage
  // -------------------------------------------------------------------------
  COVER_CS_LOW_ON_START:  cover property (p_cs_low_on_start);
  COVER_DATA_INTEGRITY:   cover property (p_data_integrity);
  COVER_CS_STABLE:        cover property (p_cs_stable);

endmodule
