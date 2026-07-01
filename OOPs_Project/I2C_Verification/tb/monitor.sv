// =============================================================================
// Monitor: Captures I2C transaction results after done asserts
// =============================================================================
// Fix: Fresh transaction per iteration
// =============================================================================

class monitor;

  virtual i2c_if vif;
  transaction tr;
  mailbox #(transaction) mbxms;

  function new(mailbox #(transaction) mbxms);
    this.mbxms = mbxms;
  endfunction

  task run();
    forever begin
      tr = new();                   // fresh object each iteration (bug fix)
      @(posedge vif.done);
      tr.din  = vif.din;
      tr.addr = vif.addr;
      tr.op   = vif.op;
      tr.dout = vif.dout;
      repeat (5) @(posedge vif.clk);
      mbxms.put(tr);
      $display("[MON] : op:%0s addr:%0d din:%0d dout:%0d @ %0t",
               (tr.op ? "RD" : "WR"), tr.addr, tr.din, tr.dout, $time);
    end
  endtask

endclass
