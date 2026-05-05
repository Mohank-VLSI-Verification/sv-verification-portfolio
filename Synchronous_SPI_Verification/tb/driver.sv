// =============================================================================
// Driver: Sends SPI transactions to DUT via virtual interface
// =============================================================================
// Also sends driven data to scoreboard via mbxds for golden reference
// =============================================================================

class driver;

  virtual spi_if vif;
  transaction tr;
  mailbox #(transaction) mbx;
  mailbox #(bit [11:0]) mbxds;    // driven data → scoreboard
  event drvnext;

  function new(mailbox #(bit [11:0]) mbxds, mailbox #(transaction) mbx);
    this.mbx   = mbx;
    this.mbxds = mbxds;
  endfunction

  task reset();
    vif.rst  <= 1'b1;
    vif.newd <= 1'b0;
    vif.din  <= 12'b0;
    repeat (10) @(posedge vif.clk);
    vif.rst  <= 1'b0;
    repeat (5) @(posedge vif.clk);
    $display("[DRV] : RESET DONE @ %0t", $time);
    $display("-----------------------------------------");
  endtask

  task run();
    forever begin
      mbx.get(tr);
      vif.newd <= 1'b1;
      vif.din  <= tr.din;
      mbxds.put(tr.din);          // send to scoreboard as golden ref
      @(posedge vif.sclk);
      vif.newd <= 1'b0;
      @(posedge vif.done);
      $display("[DRV] : DATA SENT TO DAC : %0d @ %0t", tr.din, $time);
      @(posedge vif.sclk);
    end
  endtask

endclass
