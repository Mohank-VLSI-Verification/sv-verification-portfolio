// =============================================================================
// Monitor: Captures UART TX and RX data from DUT
// =============================================================================
// TX: Detects newd + rx=1 (write mode), captures 8 bits from tx line
// RX: Detects rx=0 + newd=0 (read mode), waits for donerx, reads doutrx
// =============================================================================

class monitor;

  transaction tr;
  mailbox #(bit [7:0]) mbx;
  virtual uart_if vif;

  bit [7:0] srx;    // captured TX data
  bit [7:0] rrx;    // captured RX data

  function new(mailbox #(bit [7:0]) mbx);
    this.mbx = mbx;
  endfunction

  task run();
    forever begin
      @(posedge vif.uclktx);

      // TX monitoring: capture serial data from tx line
      if ((vif.newd == 1'b1) && (vif.rx == 1'b1)) begin
        @(posedge vif.uclktx);     // skip start bit cycle

        for (int i = 0; i <= 7; i++) begin
          @(posedge vif.uclktx);
          srx[i] = vif.tx;
        end

        $display("[MON] : TX Data Captured : %0d @ %0t", srx, $time);
        @(posedge vif.uclktx);
        mbx.put(srx);
      end

      // RX monitoring: read doutrx after donerx asserts
      else if ((vif.rx == 1'b0) && (vif.newd == 1'b0)) begin
        wait (vif.donerx == 1);
        rrx = vif.doutrx;
        $display("[MON] : RX Data Captured : %0d @ %0t", rrx, $time);
        @(posedge vif.uclktx);
        mbx.put(rrx);
      end
    end
  endtask

endclass
