// =============================================================================
// SPI Assertions: SVA properties for SPI protocol behavior
// =============================================================================

module spi_assertions (
  input logic        clk,
  input logic        sclk,
  input logic        rst,
  input logic        cs,
  input logic        mosi,
  input logic        newd,
  input logic        done,
  input logic [11:0] din,
  input logic [11:0] dout
);

  // -------------------------------------------------------------------------
  // Property 1: CS must go low before data transmission starts
  // When newd is asserted, cs must go low within a few sclk cycles
  // -------------------------------------------------------------------------
  property p_cs_low_on_start;
    @(posedge sclk) disable iff (rst)
      newd |-> ##[0:3] !cs;
  endproperty

  assert property (p_cs_low_on_start)
    else $error("[ASSERT] CS did not go low after newd @ %0t", $time);

  // -------------------------------------------------------------------------
  // Property 2: CS must return high after transmission completes
  // When done is asserted, cs should be high (or go high soon)
  // -------------------------------------------------------------------------
  property p_cs_high_on_done;
    @(posedge sclk) disable iff (rst)
      done |-> ##[0:3] cs;
  endproperty

  assert property (p_cs_high_on_done)
    else $error("[ASSERT] CS did not go high after done @ %0t", $time);

  // -------------------------------------------------------------------------
  // Property 3: Done must assert after a complete 12-bit transfer
  // After cs goes low, done should eventually assert
  // -------------------------------------------------------------------------
  property p_done_eventually;
    @(posedge sclk) disable iff (rst)
      $fell(cs) |-> ##[1:50] done;
  endproperty

  assert property (p_done_eventually)
    else $error("[ASSERT] Done never asserted after transfer started @ %0t", $time);

  // -------------------------------------------------------------------------
  // Property 4: Data integrity — dout must match din after transfer
  // -------------------------------------------------------------------------
  property p_data_integrity;
    @(posedge sclk) disable iff (rst)
      $rose(done) |-> (dout == din);
  endproperty

  assert property (p_data_integrity)
    else $error("[ASSERT] Data mismatch: din=%0d dout=%0d @ %0t", din, dout, $time);

  // -------------------------------------------------------------------------
  // Property 5: MOSI must be 0 when CS is high (idle state)
  // -------------------------------------------------------------------------
  property p_mosi_idle;
    @(posedge sclk) disable iff (rst)
      cs |-> (mosi == 1'b0);
  endproperty

  assert property (p_mosi_idle)
    else $error("[ASSERT] MOSI not idle when CS high @ %0t", $time);

  // -------------------------------------------------------------------------
  // Coverage
  // -------------------------------------------------------------------------
  cover property (p_cs_low_on_start);
  cover property (p_cs_high_on_done);
  cover property (p_done_eventually);
  cover property (p_data_integrity);
  cover property (p_mosi_idle);

endmodule
