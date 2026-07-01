// =============================================================================
// Environment: Wires SPI testbench components, orchestrates test phases
// =============================================================================

class environment;

  generator   gen;
  driver      drv;
  monitor     mon;
  scoreboard  sco;

  event nextgd;
  event nextgs;

  mailbox #(transaction)  mbxgd;    // generator → driver
  mailbox #(bit [11:0])   mbxds;    // driver → scoreboard (golden ref)
  mailbox #(bit [11:0])   mbxms;    // monitor → scoreboard (actual)

  virtual spi_if vif;

  function new(virtual spi_if vif);
    mbxgd = new();
    mbxds = new();
    mbxms = new();

    gen = new(mbxgd);
    drv = new(mbxds, mbxgd);
    mon = new(mbxms);
    sco = new(mbxds, mbxms);

    this.vif = vif;
    drv.vif  = this.vif;
    mon.vif  = this.vif;

    gen.sconext = nextgs;
    sco.sconext = nextgs;

    gen.drvnext = nextgd;
    drv.drvnext = nextgd;
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
