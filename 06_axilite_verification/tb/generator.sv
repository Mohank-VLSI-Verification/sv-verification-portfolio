// =============================================================================
// Generator: Creates randomized AXI-Lite transactions
// =============================================================================
// Fix: Uses tr.copy() when putting into mailbox
// =============================================================================

class generator;

  transaction tr;
  mailbox #(transaction) mbxgd;
  event done;
  event sconext;
  int count = 0;

  function new(mailbox #(transaction) mbxgd);
    this.mbxgd = mbxgd;
    tr = new();
  endfunction

  task run();
    for (int i = 0; i < count; i++) begin
      assert (tr.randomize) else $error("[GEN] : Randomization Failed");
      $display("[GEN] : op:%0s awaddr:%0d wdata:%0d araddr:%0d",
               (tr.op ? "WR" : "RD"), tr.awaddr, tr.wdata, tr.araddr);
      mbxgd.put(tr.copy);      // deep copy — original had shared-reference bug
      @(sconext);
    end
    -> done;
  endtask

endclass
