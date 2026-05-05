// =============================================================================
// Generator: Creates randomized FIFO transactions
// =============================================================================
// Fix: Uses copy() when putting into mailbox
// =============================================================================

class generator;

  transaction tr;
  mailbox #(transaction) mbx;
  int count = 0;
  int i = 0;

  event next;
  event done;

  function new(mailbox #(transaction) mbx);
    this.mbx = mbx;
    tr = new();
  endfunction

  task run();
    repeat (count) begin
      assert (tr.randomize) else $error("[GEN] : Randomization failed");
      i++;
      mbx.put(tr.copy);    // deep copy prevents shared-reference bug
      $display("[GEN] : Oper:%0d data_in:%0d iteration:%0d", tr.oper, tr.data_in, i);
      @(next);
    end
    -> done;
  endtask

endclass
