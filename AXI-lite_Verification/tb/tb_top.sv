// =============================================================================
// AXI4-Lite Testbench — Self-contained for Vivado XSIM
// =============================================================================

class transaction;
  randc bit         op;
  rand  bit [31:0]  awaddr;
  rand  bit [31:0]  wdata;
  rand  bit [31:0]  araddr;
        bit [31:0]  rdata;
        bit [1:0]   wresp;
        bit [1:0]   rresp;

  constraint valid_addr_range { awaddr inside {[0:127]}; araddr inside {[0:127]}; }
  constraint valid_data_range { wdata < 256; }

  function transaction copy();
    copy = new();
    copy.op = this.op; copy.awaddr = this.awaddr; copy.wdata = this.wdata;
    copy.araddr = this.araddr; copy.rdata = this.rdata;
    copy.wresp = this.wresp; copy.rresp = this.rresp;
  endfunction

  function void display(input string tag);
    $display("[%0s] : op:%0s awaddr:%0d wdata:%0d araddr:%0d rdata:%0d @ %0t",
             tag, (op ? "WR" : "RD"), awaddr, wdata, araddr, rdata, $time);
  endfunction
endclass

class generator;
  transaction tr;
  mailbox #(transaction) mbxgd;
  event done, sconext;
  int count = 0;

  function new(mailbox #(transaction) mbxgd);
    this.mbxgd = mbxgd; tr = new();
  endfunction

  task run();
    for (int i = 0; i < count; i++) begin
      assert (tr.randomize) else $error("[GEN] : Randomization Failed");
      $display("[GEN] : op:%0s awaddr:%0d wdata:%0d araddr:%0d",
               (tr.op ? "WR" : "RD"), tr.awaddr, tr.wdata, tr.araddr);
      mbxgd.put(tr.copy);
      @(sconext);
    end
    -> done;
  endtask
endclass

class driver;
  virtual axi_if vif;
  transaction tr;
  mailbox #(transaction) mbxgd;
  mailbox #(transaction) mbxdm;

  function new(mailbox #(transaction) mbxgd, mailbox #(transaction) mbxdm);
    this.mbxgd = mbxgd; this.mbxdm = mbxdm;
  endfunction

  task reset();
    vif.resetn <= 1'b0; vif.awvalid <= 1'b0; vif.awaddr <= 0;
    vif.wvalid <= 0; vif.wdata <= 0; vif.bready <= 0;
    vif.arvalid <= 1'b0; vif.araddr <= 0; vif.rready <= 0;
    repeat (5) @(posedge vif.clk);
    vif.resetn <= 1'b1;
    $display("[DRV] : RESET DONE @ %0t", $time);
    $display("-----------------------------------------");
  endtask

  task write_data(input transaction tr);
    $display("[DRV] : WRITE awaddr:%0d wdata:%0d @ %0t", tr.awaddr, tr.wdata, $time);
    mbxdm.put(tr.copy);
    vif.resetn <= 1'b1; vif.awvalid <= 1'b1; vif.arvalid <= 1'b0;
    vif.araddr <= 0; vif.awaddr <= tr.awaddr;
    @(negedge vif.awready);
    vif.awvalid <= 1'b0; vif.awaddr <= 0;
    vif.wvalid <= 1'b1; vif.wdata <= tr.wdata;
    @(negedge vif.wready);
    vif.wvalid <= 1'b0; vif.wdata <= 0;
    vif.bready <= 1'b1; vif.rready <= 1'b0;
    @(negedge vif.bvalid);
    vif.bready <= 1'b0;
  endtask

  task read_data(input transaction tr);
    $display("[DRV] : READ araddr:%0d @ %0t", tr.araddr, $time);
    mbxdm.put(tr.copy);
    vif.resetn <= 1'b1; vif.awvalid <= 1'b0; vif.awaddr <= 0;
    vif.wvalid <= 1'b0; vif.wdata <= 0; vif.bready <= 1'b0;
    vif.arvalid <= 1'b1; vif.araddr <= tr.araddr;
    @(negedge vif.arready);
    vif.araddr <= 0; vif.arvalid <= 1'b0;
    vif.rready <= 1'b1;
    @(negedge vif.rvalid);
    vif.rready <= 1'b0;
  endtask

  task run();
    forever begin
      mbxgd.get(tr);
      @(posedge vif.clk);
      if (tr.op == 1'b1) write_data(tr); else read_data(tr);
    end
  endtask
endclass

class monitor;
  virtual axi_if vif;
  transaction tr, trd;
  mailbox #(transaction) mbxms;
  mailbox #(transaction) mbxdm;

  function new(mailbox #(transaction) mbxms, mailbox #(transaction) mbxdm);
    this.mbxms = mbxms; this.mbxdm = mbxdm;
  endfunction

  task run();
    forever begin
      tr = new();
      @(posedge vif.clk);
      mbxdm.get(trd);
      if (trd.op == 1) begin
        tr.op = trd.op; tr.awaddr = trd.awaddr; tr.wdata = trd.wdata;
        @(posedge vif.bvalid);
        tr.wresp = vif.wresp;
        @(negedge vif.bvalid);
        $display("[MON] : WRITE awaddr:%0d wdata:%0d wresp:%0d @ %0t", tr.awaddr, tr.wdata, tr.wresp, $time);
        mbxms.put(tr);
      end else begin
        tr.op = trd.op; tr.araddr = trd.araddr;
        @(posedge vif.rvalid);
        tr.rdata = vif.rdata; tr.rresp = vif.rresp;
        @(negedge vif.rvalid);
        $display("[MON] : READ araddr:%0d rdata:%0d rresp:%0d @ %0t", tr.araddr, tr.rdata, tr.rresp, $time);
        mbxms.put(tr);
      end
    end
  endtask
endclass

class scoreboard;
  transaction tr;
  mailbox #(transaction) mbxms;
  event sconext;
  bit [31:0] temp;
  bit [31:0] data[128];
  int pass_count = 0;
  int fail_count = 0;

  function new(mailbox #(transaction) mbxms);
    this.mbxms = mbxms;
    for (int i = 0; i < 128; i++) data[i] = 0;
  endfunction

  task run();
    forever begin
      mbxms.get(tr);
      if (tr.op == 1) begin
        if (tr.wresp == 2'b11) begin
          $display("[SCO] : WRITE DECERR addr:%0d", tr.awaddr); pass_count++;
        end else begin
          data[tr.awaddr] = tr.wdata;
          $display("[SCO] : WRITE OK addr:%0d data:%0d", tr.awaddr, tr.wdata); pass_count++;
        end
      end else begin
        if (tr.rresp == 2'b11) begin
          $display("[SCO] : READ DECERR addr:%0d", tr.araddr); pass_count++;
        end else begin
          temp = data[tr.araddr];
          if (tr.rdata == temp) begin
            $display("[SCO] : READ MATCH addr:%0d exp:%0d got:%0d", tr.araddr, temp, tr.rdata);
            pass_count++;
          end else begin
            $error("[SCO] : READ MISMATCH addr:%0d exp:%0d got:%0d", tr.araddr, temp, tr.rdata);
            fail_count++;
          end
        end
      end
      $display("-----------------------------------------");
      -> sconext;
    end
  endtask

  function void report();
    $display("============ SCOREBOARD SUMMARY ============");
    $display("  PASS  : %0d", pass_count);
    $display("  FAIL  : %0d", fail_count);
    $display("  TOTAL : %0d", pass_count + fail_count);
    $display("=============================================");
  endfunction
endclass

class environment;
  generator gen; driver drv; monitor mon; scoreboard sco;
  event nextgs;
  mailbox #(transaction) mbxgd, mbxms, mbxdm;
  virtual axi_if vif;

  function new(virtual axi_if vif);
    mbxgd = new(); mbxms = new(); mbxdm = new();
    gen = new(mbxgd); drv = new(mbxgd, mbxdm); mon = new(mbxms, mbxdm); sco = new(mbxms);
    this.vif = vif; drv.vif = this.vif; mon.vif = this.vif;
    gen.sconext = nextgs; sco.sconext = nextgs;
  endfunction

  task pre_test(); drv.reset(); endtask
  task test(); fork gen.run(); drv.run(); mon.run(); sco.run(); join_any endtask
  task post_test();
    fork wait(gen.done.triggered); begin #5000000; $error("[ENV] : TIMEOUT"); end join_any
    sco.report(); $finish();
  endtask
  task run(); pre_test(); test(); post_test(); endtask
endclass

// =============================================================================
module tb;
  axi_if vif();

  axilite_s dut (
    .s_axi_aclk(vif.clk), .s_axi_aresetn(vif.resetn),
    .s_axi_awvalid(vif.awvalid), .s_axi_awready(vif.awready), .s_axi_awaddr(vif.awaddr),
    .s_axi_wvalid(vif.wvalid), .s_axi_wready(vif.wready), .s_axi_wdata(vif.wdata),
    .s_axi_bvalid(vif.bvalid), .s_axi_bready(vif.bready), .s_axi_bresp(vif.wresp),
    .s_axi_arvalid(vif.arvalid), .s_axi_arready(vif.arready), .s_axi_araddr(vif.araddr),
    .s_axi_rvalid(vif.rvalid), .s_axi_rready(vif.rready), .s_axi_rdata(vif.rdata), .s_axi_rresp(vif.rresp)
  );

  initial vif.clk <= 0;
  always #5 vif.clk <= ~vif.clk;

  environment env;

  initial begin
    env = new(vif);
    env.gen.count = 10;
    env.run();
  end

  initial begin $dumpfile("dump.vcd"); $dumpvars; end
endmodule
