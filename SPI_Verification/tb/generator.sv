// =============================================================================
// Generator: Creates randomized SPI transactions
// =============================================================================

class generator;

  transaction tr;
  mailbox #(transaction) mbx;
  event done;
  event drvnext;
  event sconext;
  int count = 0;

  function new(mailbox #(transaction) mbx);
    this.mbx = mbx;
    tr = new();
  endfunction

  task run();
    repeat (count) begin
      assert (tr.randomize) else $error("[GEN] : Randomization Failed");
      mbx.put(tr.copy);
      $display("[GEN] : din:%0d iteration:%0d", tr.din, count);
      @(sconext);
    end
    -> done;
  endtask

endclass
