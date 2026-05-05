// =============================================================================
// Scoreboard: Compares driver-sent data with monitor-received data
// =============================================================================
// Improvement: pass/fail counters and summary report
// =============================================================================

class scoreboard;

  mailbox #(bit [11:0]) mbxds;    // from driver (expected)
  mailbox #(bit [11:0]) mbxms;    // from monitor (actual)
  bit [11:0] ds, ms;
  event sconext;
  int pass_count = 0;
  int fail_count = 0;

  function new(mailbox #(bit [11:0]) mbxds, mailbox #(bit [11:0]) mbxms);
    this.mbxds = mbxds;
    this.mbxms = mbxms;
  endfunction

  task run();
    forever begin
      mbxds.get(ds);
      mbxms.get(ms);
      $display("[SCO] : DRV:%0d MON:%0d", ds, ms);

      if (ds == ms) begin
        $display("[SCO] : DATA MATCHED");
        pass_count++;
      end else begin
        $error("[SCO] : DATA MISMATCHED — expected:%0d got:%0d", ds, ms);
        fail_count++;
      end

      $display("-----------------------------------------");
      -> sconext;
    end
  endtask

  function void report();
    $display("============ SCOREBOARD SUMMARY ============");
    $display("  PASS  : %0d", pass_count);
    $display("  FAIL  : %0d", fail_count);
    $display("  TOTAL : %0d", pass_count + fail_count);
    $display("=============================================");
  endfunction

endclass
