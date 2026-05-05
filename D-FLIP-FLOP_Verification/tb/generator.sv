// =============================================================================
// Generator: Creates randomized transactions, sends to driver and scoreboard
// =============================================================================

class generator;

  transaction tr;
  mailbox #(transaction) mbx;       // → driver
  mailbox #(transaction) mbxref;    // → scoreboard (golden reference)
  event sconext;                     // wait for scoreboard completion
  event done;                        // all stimuli applied
  int count;

  function new(mailbox #(transaction) mbx, mailbox #(transaction) mbxref);
    this.mbx    = mbx;
    this.mbxref = mbxref;
    tr = new();
  endfunction

  task run();
    repeat (count) begin
      assert (tr.randomize) else $error("[GEN] : RANDOMIZATION FAILED");
      mbx.put(tr.copy);
      mbxref.put(tr.copy);
      tr.display("GEN");
      @(sconext);
    end
    -> done;
  endtask

endclass
