// =============================================================================
// Environment: Wires I2C testbench components
// =============================================================================
// Improvement: Proper environment class (original had test phases in tb module)
// =============================================================================

class environment;

  generator   gen;
  driver      drv;
  monitor     mon;
  scoreboard  sco;

  event nextgd;
  event nextgs;

  mailbox #(transaction) mbxgd;
  mailbox #(transaction) mbxms;

  virtual i2c_if vif;

  function new(virtual i2c_if vif);
    mbxgd = new();
    mbxms = new();

    gen = new(mbxgd);
    drv = new(mbxgd);
    mon = new(mbxms);
    sco = new(mbxms);

    this.vif = vif;
    drv.vif  = this.vif;
    mon.vif  = this.vif;

    gen.drvnext = nextgd;
    drv.drvnext = nextgd;

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
        #100000000;
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
