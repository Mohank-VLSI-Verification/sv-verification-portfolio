// =============================================================================
// Environment: Wires AXI4-Lite testbench components
// =============================================================================
// Improvement: Proper environment class (original had phases in tb module)
// =============================================================================

class environment;

  generator   gen;
  driver      drv;
  monitor     mon;
  scoreboard  sco;

  event nextgs;

  mailbox #(transaction) mbxgd;
  mailbox #(transaction) mbxms;
  mailbox #(transaction) mbxdm;    // driver → monitor context

  virtual axi_if vif;

  function new(virtual axi_if vif);
    mbxgd = new();
    mbxms = new();
    mbxdm = new();

    gen = new(mbxgd);
    drv = new(mbxgd, mbxdm);
    mon = new(mbxms, mbxdm);
    sco = new(mbxms);

    this.vif = vif;
    drv.vif  = this.vif;
    mon.vif  = this.vif;

    gen.sconext = nextgs;
    sco.sconext = nextgs;
  endfunction

  task pre_test();
    drv.reset();
  endtask

  task test();
    fork
      gen.run();
      drv.run();
      mon.run();
      sco.run();
    join_any
  endtask

  task post_test();
    fork
      wait(gen.done.triggered);
      begin
        #5000000;
        $error("[ENV] : TEST TIMEOUT — simulation hung");
      end
    join_any
    sco.report();
    $finish();
  endtask

  task run();
    pre_test();
    test();
    post_test();
  endtask

endclass
