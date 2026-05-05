// =============================================================================
// Monitor: Passively captures FIFO signals, sends to scoreboard
// =============================================================================
// Fix: Creates new transaction object each iteration
// =============================================================================

class monitor;

  virtual fifo_if fif;
  mailbox #(transaction) mbx;
  transaction tr;

  function new(mailbox #(transaction) mbx);
    this.mbx = mbx;
  endfunction

  task run();
    forever begin
      tr = new();                       // fresh object each iteration (bug fix)
      repeat (2) @(posedge fif.clock);
      tr.wr       = fif.wr;
      tr.rd       = fif.rd;
      tr.data_in  = fif.data_in;
      tr.full     = fif.full;
      tr.empty    = fif.empty;
      @(posedge fif.clock);
      tr.data_out = fif.data_out;
      mbx.put(tr);
      tr.display("MON");
    end
  endtask

endclass
