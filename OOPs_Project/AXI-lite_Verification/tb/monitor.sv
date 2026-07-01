// =============================================================================
// Monitor: Captures AXI4-Lite responses from DUT
// =============================================================================
// Gets operation context from driver via mbxdm, then captures:
//   Write: waits for bvalid, records wresp
//   Read:  waits for rvalid, records rdata and rresp
// Fix: Fresh transaction per iteration
// =============================================================================

class monitor;

  virtual axi_if vif;
  transaction tr, trd;
  mailbox #(transaction) mbxms;
  mailbox #(transaction) mbxdm;     // from driver (operation context)

  function new(mailbox #(transaction) mbxms, mailbox #(transaction) mbxdm);
    this.mbxms = mbxms;
    this.mbxdm = mbxdm;
  endfunction

  task run();
    forever begin
      tr = new();                   // fresh object each iteration
      @(posedge vif.clk);
      mbxdm.get(trd);              // get operation context from driver

      if (trd.op == 1) begin
        // Write: capture response
        tr.op     = trd.op;
        tr.awaddr = trd.awaddr;
        tr.wdata  = trd.wdata;
        @(posedge vif.bvalid);
        tr.wresp  = vif.wresp;
        @(negedge vif.bvalid);
        $display("[MON] : WRITE awaddr:%0d wdata:%0d wresp:%0d @ %0t",
                 tr.awaddr, tr.wdata, tr.wresp, $time);
        mbxms.put(tr);
      end else begin
        // Read: capture data and response
        tr.op     = trd.op;
        tr.araddr = trd.araddr;
        @(posedge vif.rvalid);
        tr.rdata  = vif.rdata;
        tr.rresp  = vif.rresp;
        @(negedge vif.rvalid);
        $display("[MON] : READ araddr:%0d rdata:%0d rresp:%0d @ %0t",
                 tr.araddr, tr.rdata, tr.rresp, $time);
        mbxms.put(tr);
      end
    end
  endtask

endclass
