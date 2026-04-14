// =============================================================================
// Scoreboard: Golden memory model for I2C verification
// =============================================================================
// Mirrors slave's internal memory (128 bytes, initialized to address value)
// Write: stores data in golden model
// Read: compares DUT dout against golden model
// =============================================================================

class scoreboard;

  transaction tr;
  mailbox #(transaction) mbxms;
  event sconext;

  bit [7:0] temp;
  bit [7:0] mem [128];
  int pass_count = 0;
  int fail_count = 0;

  function new(mailbox #(transaction) mbxms);
    this.mbxms = mbxms;
    // Initialize golden memory to match slave (mem[i] = i)
    for (int i = 0; i < 128; i++)
      mem[i] = i;
  endfunction

  task run();
    forever begin
      mbxms.get(tr);
      temp = mem[tr.addr];

      if (tr.op == 1'b0) begin
        // Write operation — store in golden model
        mem[tr.addr] = tr.din;
        $display("[SCO] : WRITE → addr:%0d data:%0d", tr.addr, tr.din);
        pass_count++;
      end else begin
        // Read operation — compare DUT output against golden model
        if (tr.dout == temp) begin
          $display("[SCO] : READ MATCH → addr:%0d expected:%0d got:%0d", tr.addr, temp, tr.dout);
          pass_count++;
        end else begin
          $error("[SCO] : READ MISMATCH → addr:%0d expected:%0d got:%0d", tr.addr, temp, tr.dout);
          fail_count++;
        end
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
