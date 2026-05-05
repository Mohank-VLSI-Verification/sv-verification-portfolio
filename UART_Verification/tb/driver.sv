// =============================================================================
// Driver: Handles both UART TX (write) and RX (read) operations
// =============================================================================
// TX path: drives dintx + newd, waits for donetx
// RX path: drives rx line bit-by-bit with random data, waits for donerx
// Sends driven data to scoreboard via mbxds for comparison
// =============================================================================

class driver;

  virtual uart_if vif;
  transaction tr;
  mailbox #(transaction) mbx;
  mailbox #(bit [7:0]) mbxds;
  event drvnext;

  bit [7:0] datarx;

  function new(mailbox #(bit [7:0]) mbxds, mailbox #(transaction) mbx);
    this.mbx   = mbx;
    this.mbxds = mbxds;
  endfunction

  task reset();
    vif.rst   <= 1'b1;
    vif.dintx <= 8'b0;
    vif.newd  <= 1'b0;
    vif.rx    <= 1'b1;          // idle state for RX line
    repeat (5) @(posedge vif.uclktx);
    vif.rst   <= 1'b0;
    @(posedge vif.uclktx);
    $display("[DRV] : RESET DONE @ %0t", $time);
    $display("----------------------------------------");
  endtask

  task run();
    forever begin
      mbx.get(tr);

      // TX operation (write)
      if (tr.oper == 1'b0) begin
        @(posedge vif.uclktx);
        vif.rst   <= 1'b0;
        vif.newd  <= 1'b1;
        vif.rx    <= 1'b1;
        vif.dintx <= tr.dintx;
        @(posedge vif.uclktx);
        vif.newd  <= 1'b0;
        mbxds.put(tr.dintx);
        $display("[DRV] : TX Data Sent : %0d @ %0t", tr.dintx, $time);
        wait (vif.donetx == 1'b1);
        -> drvnext;
      end

      // RX operation (read)
      else begin
        @(posedge vif.uclkrx);
        vif.rst  <= 1'b0;
        vif.rx   <= 1'b0;      // start bit
        vif.newd <= 1'b0;
        @(posedge vif.uclkrx);

        for (int i = 0; i <= 7; i++) begin
          @(posedge vif.uclkrx);
          vif.rx     <= $urandom;
          datarx[i]   = vif.rx;
        end

        mbxds.put(datarx);
        $display("[DRV] : RX Data Received : %0d @ %0t", datarx, $time);
        wait (vif.donerx == 1'b1);
        vif.rx <= 1'b1;         // return to idle
        -> drvnext;
      end
    end
  endtask

endclass
