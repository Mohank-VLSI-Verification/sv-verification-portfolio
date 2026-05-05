// =============================================================================
// Monitor: Passively captures DUT output, sends to scoreboard
// =============================================================================
// FIX: Creates a new transaction object each iteration to prevent
// shared-reference corruption when putting into mailbox.
// =============================================================================

class monitor;

  transaction tr;
  mailbox #(transaction) mbx;
  virtual dff_if vif;

  function new(mailbox #(transaction) mbx);
    this.mbx = mbx;
  endfunction

  task run();
    forever begin
      tr = new();                       // fresh object each iteration (bug fix)
      @(posedge vif.clk);              // wait one cycle (aligned with driver)
      tr.dout = vif.dout;
      mbx.put(tr);
      tr.display("MON");
    end
  endtask

endclass
