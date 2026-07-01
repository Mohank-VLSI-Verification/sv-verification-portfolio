////////////////////////////////////////////////////////////////////////////////
// axi_if  —  interface with 5 SVA assertions
////////////////////////////////////////////////////////////////////////////////
interface axi_if();
  
  // Write address channel (AW)
  logic        awvalid, awready;
  logic [3:0]  awid, awlen;
  logic [2:0]  awsize;
  logic [31:0] awaddr;
  logic [1:0]  awburst;
  
  // Write data channel (W)
  logic        wvalid, wready;
  logic [3:0]  wid;
  logic [31:0] wdata;
  logic [3:0]  wstrb;
  logic        wlast;
  
  // Write response channel (B)
  logic        bready, bvalid;
  logic [3:0]  bid;
  logic [1:0]  bresp;
  
  // Read address channel (AR)
  logic        arvalid, arready;
  logic [3:0]  arid, arlen;
  logic [2:0]  arsize;
  logic [31:0] araddr;
  logic [1:0]  arburst;
  
  // Read data channel (R)
  logic        rvalid, rready;
  logic [3:0]  rid;
  logic [31:0] rdata;
  logic [3:0]  rstrb;
  logic        rlast;
  logic [1:0]  rresp;
  
  // Clock and reset (active-low)
  logic clk;
  logic resetn;
  
  // White-box hooks (driven from DUT internals in TB top)
  logic [31:0] next_addrwr;
  logic [31:0] next_addrrd;
  
  // ==========================================================================
  // SVA-1 — AWVALID + AWADDR stability: once AWVALID is asserted, it must
  //         remain high and AWADDR must stay stable until AWREADY handshake
  //         (AXI4 spec — VALID/READY handshake rule)
  // ==========================================================================
  property p_awvalid_stable;
    @(posedge clk) disable iff (!resetn)
      (awvalid && !awready) |=> awvalid && $stable(awaddr);
  endproperty
  a_awvalid_stable: assert property(p_awvalid_stable)
    else $error("SVA-1: awvalid dropped or awaddr changed before awready handshake");
  
  // ==========================================================================
  // SVA-2 — WVALID stability: once WVALID is asserted, it must remain high
  //         until WREADY handshake completes (master may not retract a beat)
  // ==========================================================================
  property p_wvalid_stable;
    @(posedge clk) disable iff (!resetn)
      (wvalid && !wready) |=> wvalid;
  endproperty
  a_wvalid_stable: assert property(p_wvalid_stable)
    else $error("SVA-2: wvalid dropped before wready handshake");
  
  // ==========================================================================
  // SVA-3 — BVALID stability: once slave asserts BVALID, it must hold until
  //         master accepts via BREADY handshake
  // ==========================================================================
  property p_bvalid_stable;
    @(posedge clk) disable iff (!resetn)
      (bvalid && !bready) |=> bvalid;
  endproperty
  a_bvalid_stable: assert property(p_bvalid_stable)
    else $error("SVA-3: bvalid dropped before bready handshake");
  
  // ==========================================================================
  // SVA-4 — RVALID stability: once slave asserts RVALID, it must hold until
  //         master accepts via RREADY handshake
  // ==========================================================================
  property p_rvalid_stable;
    @(posedge clk) disable iff (!resetn)
      (rvalid && !rready) |=> rvalid;
  endproperty
  a_rvalid_stable: assert property(p_rvalid_stable)
    else $error("SVA-4: rvalid dropped before rready handshake");
  
  // ==========================================================================
  // SVA-5 — AWBURST must be a valid (non-reserved) burst type when AWVALID
  //         (FIXED=2'b00, INCR=2'b01, WRAP=2'b10; 2'b11 is RESERVED per spec)
  // ==========================================================================
  property p_awburst_valid;
    @(posedge clk) disable iff (!resetn)
      awvalid |-> (awburst inside {2'b00, 2'b01, 2'b10});
  endproperty
  a_awburst_valid: assert property(p_awburst_valid)
    else $error("SVA-5: awburst is reserved value (2'b11) while awvalid asserted");
  
endinterface