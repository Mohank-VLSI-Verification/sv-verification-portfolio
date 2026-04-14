// =============================================================================
// Driver: Handles I2C write and read operations via virtual interface
// =============================================================================

class driver;

  virtual i2c_if vif;
  transaction tr;
  event drvnext;
  mailbox #(transaction) mbxgd;

  function new(mailbox #(transaction) mbxgd);
    this.mbxgd = mbxgd;
  endfunction

  task reset();
    vif.rst  <= 1'b1;
    vif.newd <= 1'b0;
    vif.op   <= 1'b0;
    vif.din  <= 0;
    vif.addr <= 0;
    repeat (10) @(posedge vif.clk);
    vif.rst  <= 1'b0;
    $display("[DRV] : RESET DONE @ %0t", $time);
    $display("-----------------------------------------");
  endtask

  task write();
    vif.rst  <= 1'b0;
    vif.newd <= 1'b1;
    vif.op   <= 1'b0;
    vif.din  <= tr.din;
    vif.addr <= tr.addr;
    repeat (5) @(posedge vif.clk);
    vif.newd <= 1'b0;
    @(posedge vif.done);
    $display("[DRV] : OP:WR ADDR:%0d DIN:%0d @ %0t", tr.addr, tr.din, $time);
    vif.newd <= 1'b0;
  endtask

  task read();
    vif.rst  <= 1'b0;
    vif.newd <= 1'b1;
    vif.op   <= 1'b1;
    vif.din  <= 0;
    vif.addr <= tr.addr;
    repeat (5) @(posedge vif.clk);
    vif.newd <= 1'b0;
    @(posedge vif.done);
    $display("[DRV] : OP:RD ADDR:%0d DOUT:%0d @ %0t", tr.addr, vif.dout, $time);
  endtask

  task run();
    tr = new();
    forever begin
      mbxgd.get(tr);
      if (tr.op == 1'b0)
        write();
      else
        read();
      -> drvnext;
    end
  endtask

endclass
