// =============================================================================
// Environment: Wires UART testbench components
// =============================================================================

class environment;

  generator   gen;
  driver      drv;
  monitor     mon;
  scoreboard  sco;

  event nextgd;
  event nextgs;

  mailbox #(transaction)  mbxgd;
  mailbox #(bit [7:0])    mbxds;
  mailbox #(bit [7:0])    mbxms;

  virtual uart_if vif;

  function new(virtual uart_if vif);
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
        #50000000;
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
