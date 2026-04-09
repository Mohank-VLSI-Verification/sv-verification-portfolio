// =============================================================================
// Scoreboard: Compares DUT output (from monitor) against expected (from generator)
// =============================================================================

class scoreboard;

  transaction tr;       // actual (from monitor)
  transaction trref;    // expected (from generator)
  mailbox #(transaction) mbx;
  mailbox #(transaction) mbxref;
  event sconext;

  int pass_count;
  int fail_count;

  function new(mailbox #(transaction) mbx, mailbox #(transaction) mbxref);
    this.mbx    = mbx;
    this.mbxref = mbxref;
    pass_count  = 0;
    fail_count  = 0;
  endfunction

  task run();
    forever begin
      mbx.get(tr);
      mbxref.get(trref);

      tr.display("SCO");
      trref.display("REF");

      // For a DFF: output should equal the input that was driven
      if (tr.dout == trref.din) begin
        $display("[SCO] : DATA MATCHED");
        pass_count++;
      end else begin
        $display("[SCO] : DATA MISMATCHED — expected %0b, got %0b", trref.din, tr.dout);
        fail_count++;
      end

      $display("-----------------------------------------------------------");
      -> sconext;
    end
  endtask

  function void report();
    $display("============ SCOREBOARD SUMMARY ============");
    $display("  PASS : %0d", pass_count);
    $display("  FAIL : %0d", fail_count);
    $display("  TOTAL: %0d", pass_count + fail_count);
    $display("=============================================");
  endfunction

endclass
