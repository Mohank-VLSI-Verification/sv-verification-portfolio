// =============================================================================
// Monitor: Captures SPI slave output after done is asserted
// =============================================================================
// Fix: No shared-object bug here since we're putting raw bit[11:0] into
//      mailbox, not a transaction handle. But we create fresh tr each time
//      for clean display.
// =============================================================================

class monitor;

  transaction tr;
  mailbox #(bit [11:0]) mbx;
  virtual spi_if vif;

  function new(mailbox #(bit [11:0]) mbx);
    this.mbx = mbx;
  endfunction

  task run();
    forever begin
      tr = new();
      @(posedge vif.sclk);
      @(posedge vif.done);
      tr.dout = vif.dout;
      @(posedge vif.sclk);
      $display("[MON] : DATA RECEIVED : %0d @ %0t", tr.dout, $time);
      mbx.put(tr.dout);
    end
  endtask

endclass
