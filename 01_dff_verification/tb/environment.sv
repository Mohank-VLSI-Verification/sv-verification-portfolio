// =============================================================================
// Environment: Wires all testbench components together, orchestrates test phases
// =============================================================================

class environment;

  generator   gen;
  driver      drv;
  monitor     mon;
  scoreboard  sco;
  event       next;

  mailbox #(transaction) gdmbx;    // generator → driver
  mailbox #(transaction) msmbx;    // monitor → scoreboard
  mailbox #(transaction) mbxref;   // generator → scoreboard (golden ref)

  virtual dff_if vif;

  function new(virtual dff_if vif);
    // Create mailboxes
    gdmbx  = new();
    mbxref = new();
    msmbx  = new();

    // Create components and connect mailboxes
    gen = new(gdmbx, mbxref);
    drv = new(gdmbx);
    mon = new(msmbx);
    sco = new(msmbx, mbxref);

    // Connect virtual interface
    this.vif = vif;
    drv.vif  = this.vif;
    mon.vif  = this.vif;

    // Connect synchronization event
    gen.sconext = next;
    sco.sconext = next;
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
        #100000;
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
