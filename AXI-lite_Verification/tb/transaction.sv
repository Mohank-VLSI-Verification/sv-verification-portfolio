// =============================================================================
// Transaction: Data packet for AXI4-Lite testbench
// =============================================================================
// Improvements: copy(), display(), wider address constraints (0-127 not just 1)
// =============================================================================

class transaction;

  randc bit         op;          // 0=read, 1=write
  rand  bit [31:0]  awaddr;
  rand  bit [31:0]  wdata;
  rand  bit [31:0]  araddr;
        bit [31:0]  rdata;
        bit [1:0]   wresp;
        bit [1:0]   rresp;

  // Wider range than original (awaddr==1) — tests more addresses
  constraint valid_addr_range { awaddr inside {[0:127]}; araddr inside {[0:127]}; }
  constraint valid_data_range { wdata < 256; }

  function transaction copy();
    copy        = new();
    copy.op     = this.op;
    copy.awaddr = this.awaddr;
    copy.wdata  = this.wdata;
    copy.araddr = this.araddr;
    copy.rdata  = this.rdata;
    copy.wresp  = this.wresp;
    copy.rresp  = this.rresp;
  endfunction

  function void display(input string tag);
    $display("[%0s] : op:%0s awaddr:%0d wdata:%0d araddr:%0d rdata:%0d wresp:%0d rresp:%0d @ %0t",
             tag, (op ? "WR" : "RD"), awaddr, wdata, araddr, rdata, wresp, rresp, $time);
  endfunction

endclass
