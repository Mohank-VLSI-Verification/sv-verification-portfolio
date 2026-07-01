// =============================================================================
// Scoreboard: Golden model comparison for FIFO
// =============================================================================
// Uses a SystemVerilog queue as reference FIFO model.
// Improvements: pass/fail counters, summary report function
// =============================================================================

class scoreboard;

  mailbox #(transaction) mbx;
  transaction tr;
  event next;

  bit [7:0] din[$];       // reference queue (golden model)
  bit [7:0] temp;
  int pass_count = 0;
  int fail_count = 0;

  function new(mailbox #(transaction) mbx);
    this.mbx = mbx;
  endfunction

  task run();
    forever begin
      mbx.get(tr);
      tr.display("SCO");

      // Write operation
      if (tr.wr == 1'b1) begin
        if (tr.full == 1'b0) begin
          din.push_front(tr.data_in);
          $display("[SCO] : DATA STORED IN QUEUE : %0d (depth: %0d)", tr.data_in, din.size());
        end else begin
          $display("[SCO] : WRITE REJECTED — FIFO FULL");
        end
      end

      // Read operation
      if (tr.rd == 1'b1) begin
        if (tr.empty == 1'b0) begin
          temp = din.pop_back();
          if (tr.data_out == temp) begin
            $display("[SCO] : DATA MATCH — expected:%0d got:%0d", temp, tr.data_out);
            pass_count++;
          end else begin
            $error("[SCO] : DATA MISMATCH — expected:%0d got:%0d", temp, tr.data_out);
            fail_count++;
          end
        end else begin
          $display("[SCO] : READ REJECTED — FIFO EMPTY");
        end
      end

      $display("--------------------------------------");
      -> next;
    end
  endtask

  function void report();
    $display("============ SCOREBOARD SUMMARY ============");
    $display("  PASS  : %0d", pass_count);
    $display("  FAIL  : %0d", fail_count);
    $display("  TOTAL : %0d", pass_count + fail_count);
    $display("  ERRORS: %0d", fail_count);
    $display("=============================================");
  endfunction

endclass
