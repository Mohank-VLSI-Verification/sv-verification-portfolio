// =============================================================================
// Generator: Creates randomized UART transactions (TX and RX)
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
      $display("[GEN] : Oper:%0s Din:%0d", tr.oper.name(), tr.dintx);
      @(drvnext);
      @(sconext);
    end
    -> done;
  endtask

endclass
