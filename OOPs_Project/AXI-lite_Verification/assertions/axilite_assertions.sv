// =============================================================================
// AXI4-Lite Assertions: SVA properties for AXI protocol compliance
// =============================================================================

module axilite_assertions (
  input logic        clk,
  input logic        resetn,
  input logic        awvalid, awready,
  input logic        wvalid, wready,
  input logic        bvalid, bready,
  input logic        arvalid, arready,
  input logic        rvalid, rready,
  input logic [1:0]  wresp, rresp
);

  // -------------------------------------------------------------------------
  // Property 1: awready must assert within N cycles of awvalid
  // -------------------------------------------------------------------------
  property p_awready_response;
    @(posedge clk) disable iff (!resetn)
      $rose(awvalid) |-> ##[0:5] awready;
  endproperty

  assert property (p_awready_response)
    else $error("[ASSERT] awready did not respond to awvalid @ %0t", $time);

  // -------------------------------------------------------------------------
  // Property 2: wready must assert within N cycles of wvalid
  // -------------------------------------------------------------------------
  property p_wready_response;
    @(posedge clk) disable iff (!resetn)
      $rose(wvalid) |-> ##[0:10] wready;
  endproperty

  assert property (p_wready_response)
    else $error("[ASSERT] wready did not respond to wvalid @ %0t", $time);

  // -------------------------------------------------------------------------
  // Property 3: bvalid must eventually assert after a write
  // -------------------------------------------------------------------------
  property p_bvalid_after_write;
    @(posedge clk) disable iff (!resetn)
      $fell(wready) |-> ##[1:20] bvalid;
  endproperty

  assert property (p_bvalid_after_write)
    else $error("[ASSERT] bvalid not asserted after write @ %0t", $time);

  // -------------------------------------------------------------------------
  // Property 4: arready must assert within N cycles of arvalid
  // -------------------------------------------------------------------------
  property p_arready_response;
    @(posedge clk) disable iff (!resetn)
      $rose(arvalid) |-> ##[0:5] arready;
  endproperty

  assert property (p_arready_response)
    else $error("[ASSERT] arready did not respond to arvalid @ %0t", $time);

  // -------------------------------------------------------------------------
  // Property 5: rvalid must eventually assert after arready
  // -------------------------------------------------------------------------
  property p_rvalid_after_read;
    @(posedge clk) disable iff (!resetn)
      $fell(arready) |-> ##[1:20] rvalid;
  endproperty

  assert property (p_rvalid_after_read)
    else $error("[ASSERT] rvalid not asserted after read address @ %0t", $time);

  // -------------------------------------------------------------------------
  // Property 6: After reset, all outputs must be deasserted
  // -------------------------------------------------------------------------
  property p_reset_outputs;
    @(posedge clk)
      !resetn |=> (!awready && !wready && !bvalid && !arready && !rvalid);
  endproperty

  assert property (p_reset_outputs)
    else $error("[ASSERT] Outputs not cleared after reset @ %0t", $time);

  // -------------------------------------------------------------------------
  // Property 7: wresp OKAY (00) for valid address, DECERR (11) for invalid
  // -------------------------------------------------------------------------
  property p_wresp_valid;
    @(posedge clk) disable iff (!resetn)
      $rose(bvalid) |-> (wresp == 2'b00 || wresp == 2'b11);
  endproperty

  assert property (p_wresp_valid)
    else $error("[ASSERT] Invalid wresp value @ %0t", $time);

  // -------------------------------------------------------------------------
  // Coverage
  // -------------------------------------------------------------------------
  cover property (p_awready_response);
  cover property (p_wready_response);
  cover property (p_bvalid_after_write);
  cover property (p_arready_response);
  cover property (p_rvalid_after_read);
  cover property (p_reset_outputs);
  cover property (p_wresp_valid);

endmodule
