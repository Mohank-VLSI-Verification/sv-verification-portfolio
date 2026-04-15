// =============================================================================
// Driver: Drives AXI4-Lite write and read transactions via virtual interface
// =============================================================================
// Follows AXI4-Lite handshake protocol:
//   Write: awvalid→awready → wvalid→wready → bvalid→bready
//   Read:  arvalid→arready → rvalid→rready
// Also sends transaction to monitor via mbxdm for operation type tracking
// =============================================================================

class driver;

  virtual axi_if vif;
  transaction tr;
  mailbox #(transaction) mbxgd;
  mailbox #(transaction) mbxdm;     // driver → monitor (operation context)

  function new(mailbox #(transaction) mbxgd, mailbox #(transaction) mbxdm);
    this.mbxgd = mbxgd;
    this.mbxdm = mbxdm;
  endfunction

  task reset();
    vif.resetn  <= 1'b0;
    vif.awvalid <= 1'b0;
    vif.awaddr  <= 0;
    vif.wvalid  <= 1'b0;
    vif.wdata   <= 0;
    vif.bready  <= 1'b0;
    vif.arvalid <= 1'b0;
    vif.araddr  <= 0;
    vif.rready  <= 1'b0;
    repeat (5) @(posedge vif.clk);
    vif.resetn  <= 1'b1;
    $display("[DRV] : RESET DONE @ %0t", $time);
    $display("-----------------------------------------");
  endtask

  task write_data(input transaction tr);
    $display("[DRV] : WRITE awaddr:%0d wdata:%0d @ %0t", tr.awaddr, tr.wdata, $time);
    mbxdm.put(tr.copy);

    // Write address phase
    vif.resetn  <= 1'b1;
    vif.awvalid <= 1'b1;
    vif.arvalid <= 1'b0;
    vif.araddr  <= 0;
    vif.awaddr  <= tr.awaddr;
    @(negedge vif.awready);
    vif.awvalid <= 1'b0;
    vif.awaddr  <= 0;

    // Write data phase
    vif.wvalid  <= 1'b1;
    vif.wdata   <= tr.wdata;
    @(negedge vif.wready);
    vif.wvalid  <= 1'b0;
    vif.wdata   <= 0;

    // Write response phase
    vif.bready  <= 1'b1;
    vif.rready  <= 1'b0;
    @(negedge vif.bvalid);
    vif.bready  <= 1'b0;
  endtask

  task read_data(input transaction tr);
    $display("[DRV] : READ araddr:%0d @ %0t", tr.araddr, $time);
    mbxdm.put(tr.copy);

    // Read address phase
    vif.resetn  <= 1'b1;
    vif.awvalid <= 1'b0;
    vif.awaddr  <= 0;
    vif.wvalid  <= 1'b0;
    vif.wdata   <= 0;
    vif.bready  <= 1'b0;
    vif.arvalid <= 1'b1;
    vif.araddr  <= tr.araddr;
    @(negedge vif.arready);
    vif.araddr  <= 0;
    vif.arvalid <= 1'b0;

    // Read data phase
    vif.rready  <= 1'b1;
    @(negedge vif.rvalid);
    vif.rready  <= 1'b0;
  endtask

  task run();
    forever begin
      mbxgd.get(tr);
      @(posedge vif.clk);
      if (tr.op == 1'b1)
        write_data(tr);
      else
        read_data(tr);
    end
  endtask

endclass
