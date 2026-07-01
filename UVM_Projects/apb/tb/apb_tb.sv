`include "uvm_macros.svh"
import uvm_pkg::*;

////////////////////////////////////////////////////////////////////////////////
// CONFIGURATION
////////////////////////////////////////////////////////////////////////////////
class apb_config extends uvm_object;
  `uvm_object_utils(apb_config)
  
  uvm_active_passive_enum is_active = UVM_ACTIVE;
  
  function new(string name = "apb_config");
    super.new(name);
  endfunction
endclass

////////////////////////////////////////////////////////////////////////////////
// OPERATION MODE
////////////////////////////////////////////////////////////////////////////////
typedef enum bit [1:0] {readd = 0, writed = 1, rst = 2} oper_mode;

////////////////////////////////////////////////////////////////////////////////
// TRANSACTION  —  single conditional constraint via valid_addr knob
////////////////////////////////////////////////////////////////////////////////
class transaction extends uvm_sequence_item;
  
  rand oper_mode    op;
  rand logic        PWRITE;
  rand logic [31:0] PWDATA;
  rand logic [31:0] PADDR;
  
  // Knob: TRUE = constrain PADDR to valid range (0-31)
  //       FALSE = constrain PADDR to error range (32-max)
  bit valid_addr = 1'b1;
  
  logic        PREADY;
  logic        PSLVERR;
  logic [31:0] PRDATA;
  
  // Single conditional constraint — no constraint_mode juggling
  constraint addr_c {
    if (valid_addr) PADDR inside {[0:31]};
    else            PADDR inside {[32:32'hFFFF_FFFF]};
  }
  
  `uvm_object_utils_begin(transaction)
    `uvm_field_enum(oper_mode, op, UVM_DEFAULT)
    `uvm_field_int (PADDR,   UVM_DEFAULT)
    `uvm_field_int (PWDATA,  UVM_DEFAULT)
    `uvm_field_int (PRDATA,  UVM_DEFAULT)
    `uvm_field_int (PSLVERR, UVM_DEFAULT)
  `uvm_object_utils_end
  
  function new(string name = "transaction");
    super.new(name);
  endfunction
endclass : transaction

////////////////////////////////////////////////////////////////////////////////
// COVERAGE SUBSCRIBER
////////////////////////////////////////////////////////////////////////////////
class apb_coverage extends uvm_subscriber #(transaction);
  `uvm_component_utils(apb_coverage)
  
  transaction tr;
  
  covergroup apb_cg;
    option.per_instance = 1;
    option.name         = "apb_cov";
    
    op_cp: coverpoint tr.op {
      bins write = {writed};
      bins read  = {readd};
    }
    
    paddr_cp: coverpoint tr.PADDR {
      bins addr_zero   = {0};
      bins valid_lo    = {[1:7]};
      bins valid_mid   = {[8:23]};
      bins valid_hi    = {[24:30]};
      bins addr_max    = {31};
      bins error_range = {[32:$]};
    }
    
    pwdata_cp: coverpoint tr.PWDATA iff (tr.op == writed) {
      bins low  = {[0:99]};
      bins mid  = {[100:9999]};
      bins high = {[10000:$]};
    }
    
    pslverr_cp: coverpoint tr.PSLVERR {
      bins no_err = {0};
      bins err    = {1};
    }
    
    op_x_paddr:      cross op_cp, paddr_cp;
    op_x_pslverr:    cross op_cp, pslverr_cp;
    paddr_x_pslverr: cross paddr_cp, pslverr_cp;
    
  endgroup
  
  function new(string name, uvm_component parent);
    super.new(name, parent);
    apb_cg = new();
  endfunction
  
  function void write(transaction t);
    tr = t;
    apb_cg.sample();
  endfunction
  
  function void report_phase(uvm_phase phase);
    `uvm_info("COV", $sformatf("APB Functional Coverage = %0.2f%%",
      apb_cg.get_inst_coverage()), UVM_LOW)
  endfunction
  
endclass

////////////////////////////////////////////////////////////////////////////////
// SEQUENCES
////////////////////////////////////////////////////////////////////////////////

class write_data extends uvm_sequence#(transaction);
  `uvm_object_utils(write_data)
  transaction tr;
  function new(string name = "write_data"); super.new(name); endfunction
  
  virtual task body();
    repeat(15) begin
      tr = transaction::type_id::create("tr");
      start_item(tr);
      tr.valid_addr = 1'b1;
      if(!tr.randomize()) `uvm_error("SEQ","write_data randomize failed")
      tr.op = writed;
      finish_item(tr);
    end
  endtask
endclass

class read_data extends uvm_sequence#(transaction);
  `uvm_object_utils(read_data)
  transaction tr;
  function new(string name = "read_data"); super.new(name); endfunction
  
  virtual task body();
    repeat(15) begin
      tr = transaction::type_id::create("tr");
      start_item(tr);
      tr.valid_addr = 1'b1;
      if(!tr.randomize()) `uvm_error("SEQ","read_data randomize failed")
      tr.op = readd;
      finish_item(tr);
    end
  endtask
endclass

class write_read extends uvm_sequence#(transaction);
  `uvm_object_utils(write_read)
  transaction tr;
  function new(string name = "write_read"); super.new(name); endfunction
  
  virtual task body();
    repeat(15) begin
      tr = transaction::type_id::create("tr");
      
      start_item(tr);
      tr.valid_addr = 1'b1;
      if(!tr.randomize()) `uvm_error("SEQ","write_read W randomize failed")
      tr.op = writed;
      finish_item(tr);
      
      start_item(tr);
      tr.valid_addr = 1'b1;
      if(!tr.randomize()) `uvm_error("SEQ","write_read R randomize failed")
      tr.op = readd;
      finish_item(tr);
    end
  endtask
endclass

class writeb_readb extends uvm_sequence#(transaction);
  `uvm_object_utils(writeb_readb)
  transaction tr;
  function new(string name = "writeb_readb"); super.new(name); endfunction
  
  virtual task body();
    repeat(15) begin
      tr = transaction::type_id::create("tr");
      start_item(tr);
      tr.valid_addr = 1'b1;
      if(!tr.randomize()) `uvm_error("SEQ","writeb randomize failed")
      tr.op = writed;
      finish_item(tr);
    end
    repeat(15) begin
      tr = transaction::type_id::create("tr");
      start_item(tr);
      tr.valid_addr = 1'b1;
      if(!tr.randomize()) `uvm_error("SEQ","readb randomize failed")
      tr.op = readd;
      finish_item(tr);
    end
  endtask
endclass

class write_err extends uvm_sequence#(transaction);
  `uvm_object_utils(write_err)
  transaction tr;
  function new(string name = "write_err"); super.new(name); endfunction
  
  virtual task body();
    repeat(15) begin
      tr = transaction::type_id::create("tr");
      start_item(tr);
      tr.valid_addr = 1'b0;     // error range
      if(!tr.randomize()) `uvm_error("SEQ","write_err randomize failed")
      tr.op = writed;
      finish_item(tr);
    end
  endtask
endclass

class read_err extends uvm_sequence#(transaction);
  `uvm_object_utils(read_err)
  transaction tr;
  function new(string name = "read_err"); super.new(name); endfunction
  
  virtual task body();
    repeat(15) begin
      tr = transaction::type_id::create("tr");
      start_item(tr);
      tr.valid_addr = 1'b0;     // error range
      if(!tr.randomize()) `uvm_error("SEQ","read_err randomize failed")
      tr.op = readd;
      finish_item(tr);
    end
  endtask
endclass

class reset_dut extends uvm_sequence#(transaction);
  `uvm_object_utils(reset_dut)
  transaction tr;
  function new(string name = "reset_dut"); super.new(name); endfunction
  
  virtual task body();
    repeat(15) begin
      tr = transaction::type_id::create("tr");
      start_item(tr);
      tr.valid_addr = 1'b1;
      if(!tr.randomize()) `uvm_error("SEQ","reset_dut randomize failed")
      tr.op = rst;
      finish_item(tr);
    end
  endtask
endclass

////////////////////////////////////////////////////////////////////////////////
// DRIVER
////////////////////////////////////////////////////////////////////////////////
class driver extends uvm_driver #(transaction);
  `uvm_component_utils(driver)
  
  virtual apb_if vif;
  transaction tr;
  
  function new(string path = "drv", uvm_component parent = null);
    super.new(path, parent);
  endfunction
  
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    tr = transaction::type_id::create("tr");
    if(!uvm_config_db#(virtual apb_if)::get(this,"","vif",vif))
      `uvm_error("DRV","Unable to access Interface");
  endfunction
  
  task reset_dut();
    repeat(5) begin
      vif.presetn <= 1'b0;
      vif.paddr   <= 'h0;
      vif.pwdata  <= 'h0;
      vif.pwrite  <= 'b0;
      vif.psel    <= 'b0;
      vif.penable <= 'b0; 
      `uvm_info("DRV", "System Reset : Start of Simulation", UVM_MEDIUM);
      @(posedge vif.pclk);
    end
  endtask
  
  task drive();
    reset_dut();
    forever begin
      seq_item_port.get_next_item(tr);
      
      if(tr.op == rst) begin
        vif.presetn <= 1'b0;
        vif.paddr   <= 'h0;
        vif.pwdata  <= 'h0;
        vif.pwrite  <= 'b0;
        vif.psel    <= 'b0;
        vif.penable <= 'b0;
        @(posedge vif.pclk);  
      end
      else if(tr.op == writed) begin
        vif.psel    <= 1'b1;
        vif.paddr   <= tr.PADDR;
        vif.pwdata  <= tr.PWDATA;
        vif.presetn <= 1'b1;
        vif.pwrite  <= 1'b1;
        @(posedge vif.pclk);
        vif.penable <= 1'b1;
        `uvm_info("DRV", $sformatf("mode:%s addr:%0d wdata:%0d", tr.op.name(), tr.PADDR, tr.PWDATA), UVM_NONE);
        @(negedge vif.pready);
        vif.penable <= 1'b0;
        tr.PSLVERR  = vif.pslverr;
      end
      else if(tr.op == readd) begin
        vif.psel    <= 1'b1;
        vif.paddr   <= tr.PADDR;
        vif.presetn <= 1'b1;
        vif.pwrite  <= 1'b0;
        @(posedge vif.pclk);
        vif.penable <= 1'b1;
        `uvm_info("DRV", $sformatf("mode:%s addr:%0d", tr.op.name(), tr.PADDR), UVM_NONE);
        @(negedge vif.pready);
        vif.penable <= 1'b0;
        tr.PRDATA  = vif.prdata;
        tr.PSLVERR = vif.pslverr;
      end
      
      seq_item_port.item_done();
    end
  endtask
  
  virtual task run_phase(uvm_phase phase);
    drive();
  endtask
endclass

////////////////////////////////////////////////////////////////////////////////
// MONITOR  —  Bug 2 FIX: sample only when pready=1 in access phase
////////////////////////////////////////////////////////////////////////////////
class mon extends uvm_monitor;
  `uvm_component_utils(mon)
  
  uvm_analysis_port#(transaction) send;
  transaction tr;
  virtual apb_if vif;
  
  function new(string inst = "mon", uvm_component parent = null);
    super.new(inst, parent);
  endfunction
  
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    tr   = transaction::type_id::create("tr");
    send = new("send", this);
    if(!uvm_config_db#(virtual apb_if)::get(this,"","vif",vif))
      `uvm_error("MON","Unable to access Interface");
  endfunction
  
  virtual task run_phase(uvm_phase phase);
    forever begin
      @(posedge vif.pclk);
      
      if(!vif.presetn) begin
        tr.op      = rst;
        tr.PADDR   = 32'h0;
        tr.PWDATA  = 32'h0;
        tr.PRDATA  = 32'h0;
        tr.PSLVERR = 1'b0;
        `uvm_info("MON", "SYSTEM RESET DETECTED", UVM_NONE);
        send.write(tr);
      end
      // Sample only when DUT is in valid response cycle: pready high
      else if (vif.presetn && vif.psel && vif.penable && vif.pready) begin
        if (vif.pwrite) begin
          tr.op      = writed;
          tr.PADDR   = vif.paddr;
          tr.PWDATA  = vif.pwdata;
          tr.PRDATA  = 32'h0;
          tr.PSLVERR = vif.pslverr;
          `uvm_info("MON", $sformatf("DATA WRITE addr:%0d data:%0d slverr:%0d", tr.PADDR, tr.PWDATA, tr.PSLVERR), UVM_NONE);
          send.write(tr);
        end
        else begin
          tr.op      = readd;
          tr.PADDR   = vif.paddr;
          tr.PWDATA  = 32'h0;
          tr.PSLVERR = vif.pslverr;
          if(tr.PSLVERR == 1'b1)
            tr.PRDATA = 32'h0;
          else
            tr.PRDATA = vif.prdata;
          `uvm_info("MON", $sformatf("DATA READ addr:%0d data:%0d slverr:%0d", tr.PADDR, tr.PRDATA, tr.PSLVERR), UVM_NONE);
          send.write(tr);
        end
      end
    end
  endtask
endclass

////////////////////////////////////////////////////////////////////////////////
// REFERENCE MODEL  —  same gating as monitor for race-free comparison
////////////////////////////////////////////////////////////////////////////////
class ref_model extends uvm_monitor;
  `uvm_component_utils(ref_model)
  
  uvm_analysis_port#(transaction) send_ref;
  transaction tr;
  virtual apb_if vif;
  
  logic [31:0] ref_arr [32];
  
  function new(string inst = "ref_model", uvm_component parent = null);
    super.new(inst, parent);
  endfunction
  
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    tr       = transaction::type_id::create("tr");
    send_ref = new("send_ref", this);
    foreach(ref_arr[i]) ref_arr[i] = 32'h0;
    if(!uvm_config_db#(virtual apb_if)::get(this,"","vif",vif))
      `uvm_error("REF","Unable to access Interface");
  endfunction
  
  virtual task run_phase(uvm_phase phase);
    forever begin
      @(posedge vif.pclk);
      
      if(!vif.presetn) begin
        tr.op      = rst;
        tr.PADDR   = 32'h0;
        tr.PWDATA  = 32'h0;
        tr.PRDATA  = 32'h0;
        tr.PSLVERR = 1'b0;
        foreach(ref_arr[i]) ref_arr[i] = 32'h0;
        send_ref.write(tr);
      end
      else if (vif.presetn && vif.psel && vif.penable && vif.pready) begin
        if (vif.pwrite) begin
          tr.op     = writed;
          tr.PADDR  = vif.paddr;
          tr.PWDATA = vif.pwdata;
          tr.PRDATA = 32'h0;
          
          if(tr.PADDR > 31) begin
            tr.PSLVERR = 1'b1;
          end
          else begin
            tr.PSLVERR        = 1'b0;
            ref_arr[tr.PADDR] = tr.PWDATA;
          end
          
          `uvm_info("REF", $sformatf("WRITE addr:%0d wdata:%0d predicted_slverr:%0d", tr.PADDR, tr.PWDATA, tr.PSLVERR), UVM_NONE);
          send_ref.write(tr);
        end
        else begin
          tr.op     = readd;
          tr.PADDR  = vif.paddr;
          tr.PWDATA = 32'h0;
          
          if(tr.PADDR > 31) begin
            tr.PSLVERR = 1'b1;
            tr.PRDATA  = 32'h0;
          end
          else begin
            tr.PSLVERR = 1'b0;
            tr.PRDATA  = ref_arr[tr.PADDR];
          end
          
          `uvm_info("REF", $sformatf("READ addr:%0d predicted_rdata:%0d predicted_slverr:%0d", tr.PADDR, tr.PRDATA, tr.PSLVERR), UVM_NONE);
          send_ref.write(tr);
        end
      end
    end
  endtask
endclass

////////////////////////////////////////////////////////////////////////////////
// SCOREBOARD
////////////////////////////////////////////////////////////////////////////////
class sco extends uvm_scoreboard;
  `uvm_component_utils(sco)
  
  uvm_tlm_analysis_fifo#(transaction) sco_data;
  uvm_tlm_analysis_fifo#(transaction) sco_data_ref;
  
  transaction tr, trref;
  
  function new(string inst = "sco", uvm_component parent = null);
    super.new(inst, parent);
  endfunction
  
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    sco_data     = new("sco_data", this);
    sco_data_ref = new("sco_data_ref", this);
  endfunction
  
  virtual task run_phase(uvm_phase phase);
    forever begin
      sco_data.get(tr);
      sco_data_ref.get(trref);
      
      if(tr.op == rst)
        `uvm_info("SCO", "System Reset", UVM_NONE)
      else if(tr.compare(trref))
        `uvm_info("SCO", $sformatf("Test PASSED  op:%s addr:%0d wdata:%0d rdata:%0d exp_rdata:%0d slverr:%0d exp_slverr:%0d",
          tr.op.name(), tr.PADDR, tr.PWDATA, tr.PRDATA, trref.PRDATA, tr.PSLVERR, trref.PSLVERR), UVM_NONE)
      else
        `uvm_info("SCO", $sformatf("Test FAILED  op:%s addr:%0d wdata:%0d rdata:%0d exp_rdata:%0d slverr:%0d exp_slverr:%0d",
          tr.op.name(), tr.PADDR, tr.PWDATA, tr.PRDATA, trref.PRDATA, tr.PSLVERR, trref.PSLVERR), UVM_NONE)
      $display("----------------------------------------------------------------");
    end
  endtask
endclass

////////////////////////////////////////////////////////////////////////////////
// AGENT
////////////////////////////////////////////////////////////////////////////////
class agent extends uvm_agent;
  `uvm_component_utils(agent)
  
  apb_config    cfg;
  driver        d;
  uvm_sequencer#(transaction) seqr;
  mon           m;
  ref_model     ref_m;
  apb_coverage  cov;
  
  function new(string inst = "agent", uvm_component parent = null);
    super.new(inst, parent);
  endfunction
  
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    cfg   = apb_config::type_id::create("cfg"); 
    m     = mon::type_id::create("m", this);
    ref_m = ref_model::type_id::create("ref_m", this);
    cov   = apb_coverage::type_id::create("cov", this);
    
    if(cfg.is_active == UVM_ACTIVE) begin   
      d    = driver::type_id::create("d", this);
      seqr = uvm_sequencer#(transaction)::type_id::create("seqr", this);
    end
  endfunction
  
  virtual function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    m.send.connect(cov.analysis_export);
    if(cfg.is_active == UVM_ACTIVE) begin  
      d.seq_item_port.connect(seqr.seq_item_export);
    end
  endfunction
endclass

////////////////////////////////////////////////////////////////////////////////
// ENVIRONMENT
////////////////////////////////////////////////////////////////////////////////
class env extends uvm_env;
  `uvm_component_utils(env)
  
  agent a;
  sco   s;
  
  function new(string inst = "env", uvm_component c);
    super.new(inst, c);
  endfunction
  
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    a = agent::type_id::create("a", this);
    s = sco::type_id::create("s", this);
  endfunction
  
  virtual function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    a.m.send.connect(s.sco_data.analysis_export);
    a.ref_m.send_ref.connect(s.sco_data_ref.analysis_export);
  endfunction
endclass

////////////////////////////////////////////////////////////////////////////////
// TEST  —  runs all 7 sequences sequentially for full coverage path hits
////////////////////////////////////////////////////////////////////////////////
class test extends uvm_test;
  `uvm_component_utils(test)
  
  env e;
  
  write_data   wd_seq;
  read_data    rd_seq;
  write_read   wr_seq;
  writeb_readb wbrb_seq;
  write_err    werr_seq;
  read_err     rerr_seq;
  reset_dut    rst_seq;
  
  function new(string inst = "test", uvm_component c);
    super.new(inst, c);
  endfunction
  
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    e = env::type_id::create("env", this);
  endfunction
  
  virtual task run_phase(uvm_phase phase);
    phase.raise_objection(this);
    
    `uvm_info("TEST", "=== Starting APB regression: 7 sequences sequentially ===", UVM_LOW)
    
    rst_seq = reset_dut::type_id::create("rst_seq");
    `uvm_info("TEST", "--- Sequence 1/7: reset_dut ---", UVM_LOW)
    rst_seq.start(e.a.seqr);
    
    wd_seq = write_data::type_id::create("wd_seq");
    `uvm_info("TEST", "--- Sequence 2/7: write_data ---", UVM_LOW)
    wd_seq.start(e.a.seqr);
    
    rd_seq = read_data::type_id::create("rd_seq");
    `uvm_info("TEST", "--- Sequence 3/7: read_data ---", UVM_LOW)
    rd_seq.start(e.a.seqr);
    
    wr_seq = write_read::type_id::create("wr_seq");
    `uvm_info("TEST", "--- Sequence 4/7: write_read ---", UVM_LOW)
    wr_seq.start(e.a.seqr);
    
    wbrb_seq = writeb_readb::type_id::create("wbrb_seq");
    `uvm_info("TEST", "--- Sequence 5/7: writeb_readb ---", UVM_LOW)
    wbrb_seq.start(e.a.seqr);
    
    werr_seq = write_err::type_id::create("werr_seq");
    `uvm_info("TEST", "--- Sequence 6/7: write_err ---", UVM_LOW)
    werr_seq.start(e.a.seqr);
    
    rerr_seq = read_err::type_id::create("rerr_seq");
    `uvm_info("TEST", "--- Sequence 7/7: read_err ---", UVM_LOW)
    rerr_seq.start(e.a.seqr);
    
    `uvm_info("TEST", "=== APB regression complete ===", UVM_LOW)
    
    #100;
    phase.drop_objection(this);
  endtask
endclass

////////////////////////////////////////////////////////////////////////////////
// TB TOP
////////////////////////////////////////////////////////////////////////////////
module tb;
  
  apb_if vif();
  
  apb_ram dut (
    .presetn(vif.presetn),
    .pclk(vif.pclk),
    .psel(vif.psel),
    .penable(vif.penable),
    .pwrite(vif.pwrite),
    .paddr(vif.paddr),
    .pwdata(vif.pwdata),
    .prdata(vif.prdata),
    .pready(vif.pready),
    .pslverr(vif.pslverr)
  );
  
  initial begin
    vif.pclk <= 0;
  end
  
  always #10 vif.pclk <= ~vif.pclk;
  
  initial begin
    uvm_config_db#(virtual apb_if)::set(null, "*", "vif", vif);
    run_test("test");
  end
  
endmodule