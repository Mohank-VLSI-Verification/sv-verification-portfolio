// =============================================================================
// Scoreboard: Golden memory model for AXI4-Lite verification
// =============================================================================
// Write: stores data in golden model, checks wresp
// Read: compares DUT rdata against golden model
// Handles DECERR (resp=3) for out-of-range addresses
// =============================================================================

class scoreboard;

  transaction tr;
  mailbox #(transaction) mbxms;
  event sconext;

  bit [31:0] temp;
  bit [31:0] data [128];
  int pass_count = 0;
  int fail_count = 0;

  function new(mailbox #(transaction) mbxms);
    this.mbxms = mbxms;
    for (int i = 0; i < 128; i++)
      data[i] = 0;
  endfunction

  task run();
    forever begin
      mbxms.get(tr);

      if (tr.op == 1) begin
        // Write operation
        if (tr.wresp == 2'b11) begin
          $display("[SCO] : WRITE DECERR — addr:%0d out of range", tr.awaddr);
          pass_count++;   // error response is correct behavior for bad addr
        end else begin
          data[tr.awaddr] = tr.wdata;
          $display("[SCO] : WRITE OK — addr:%0d data:%0d", tr.awaddr, tr.wdata);
          pass_count++;
        end
      end else begin
        // Read operation
        if (tr.rresp == 2'b11) begin
          $display("[SCO] : READ DECERR — addr:%0d out of range", tr.araddr);
          pass_count++;
        end else begin
          temp = data[tr.araddr];
          if (tr.rdata == temp) begin
            $display("[SCO] : READ MATCH — addr:%0d expected:%0d got:%0d", tr.araddr, temp, tr.rdata);
            pass_count++;
          end else begin
            $error("[SCO] : READ MISMATCH — addr:%0d expected:%0d got:%0d", tr.araddr, temp, tr.rdata);
            fail_count++;
          end
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
