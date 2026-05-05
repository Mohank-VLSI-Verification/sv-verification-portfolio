// =============================================================================
// Driver: Receives transactions from generator, drives DUT inputs via vif
// =============================================================================

class driver;

  transaction tr;
  mailbox #(transaction) mbx;
  virtual dff_if vif;

  function new(mailbox #(transaction) mbx);
    this.mbx = mbx;
  endfunction

  // Hold reset for 5 clock cycles to ensure all flip-flops capture reset state
  task reset();
    vif.rst <= 1'b1;
    repeat (5) @(posedge vif.clk);
    vif.rst <= 1'b0;
    @(posedge vif.clk);
    $display("[DRV] : RESET DONE @ time %0t", $time);
  endtask

  // Drive stimulus — no forced idle between transactions
  // Allows back-to-back testing for consecutive din values
  task run();
    forever begin
      mbx.get(tr);
      vif.din <= tr.din;
      @(posedge vif.clk);
      tr.display("DRV");
    end
  endtask

endclass
