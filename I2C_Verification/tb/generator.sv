// =============================================================================
// Generator: Creates randomized I2C transactions (read/write)
// =============================================================================
// Fix: Uses tr.copy() when putting into mailbox
// =============================================================================

class generator;

  transaction tr;
  mailbox #(transaction) mbxgd;
  event done;
  event drvnext;
  event sconext;
  int count = 0;

  function new(mailbox #(transaction) mbxgd);
    this.mbxgd = mbxgd;
    tr = new();
  endfunction

  task run();
    repeat (count) begin
      assert (tr.randomize) else $error("[GEN] : Randomization Failed");
      mbxgd.put(tr.copy);    // deep copy — original had shared-reference bug
      $display("[GEN] : op:%0s addr:%0d din:%0d", (tr.op ? "RD" : "WR"), tr.addr, tr.din);
      @(drvnext);
      @(sconext);
    end
    -> done;
  endtask

endclass
