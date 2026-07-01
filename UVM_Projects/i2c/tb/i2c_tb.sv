`include "uvm_macros.svh"
import uvm_pkg::*;

////////////////////////////////////////////////////////////////////////////////
// OPERATION MODE
////////////////////////////////////////////////////////////////////////////////
typedef enum bit [1:0] {readd = 0, writed = 1, rstdut = 2} oper_mode;

////////////////////////////////////////////////////////////////////////////////
// TRANSACTION  —  knob-based constraint: valid_addr=1 -> narrow (0..10)
//                                        valid_addr=0 -> full 7-bit (0..127)
////////////////////////////////////////////////////////////////////////////////
class transaction extends uvm_sequence_item;

  oper_mode         op;
  logic             wr;
  randc logic [6:0] addr;
  rand  logic [7:0] din;
  logic [7:0]       datard;
  logic             done;

  bit               valid_addr = 1;   // knob (non-rand)

  constraint addr_c {
    if (valid_addr) addr inside {[0:10]};
    else            addr inside {[0:127]};
  }

  `uvm_object_utils_begin(transaction)
    `uvm_field_enum(oper_mode, op, UVM_DEFAULT)
    `uvm_field_int (addr,   UVM_DEFAULT)
    `uvm_field_int (din,    UVM_DEFAULT)
    `uvm_field_int (datard, UVM_DEFAULT)
  `uvm_object_utils_end

  function new(string name = "transaction");
    super.new(name);
  endfunction
endclass : transaction

////////////////////////////////////////////////////////////////////////////////
// BASELINE SEQUENCES  (narrow addr, valid_addr = 1)
////////////////////////////////////////////////////////////////////////////////

class write_data extends uvm_sequence#(transaction);
  `uvm_object_utils(write_data)
  transaction tr;
  function new(string name = "write_data"); super.new(name); endfunction

  virtual task body();
    repeat(15) begin
      tr = transaction::type_id::create("tr");
      start_item(tr);
      tr.valid_addr = 1;
      if(!tr.randomize()) `uvm_error("SEQ", "write_data randomize failed")
      tr.op = writed;
      `uvm_info("SEQ", $sformatf("MODE : WRITE DIN : %0d ADDR : %0d ", tr.din, tr.addr), UVM_NONE);
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
      tr.valid_addr = 1;
      if(!tr.randomize()) `uvm_error("SEQ", "read_data randomize failed")
      tr.op = readd;
      `uvm_info("SEQ", $sformatf("MODE : READ ADDR : %0d ", tr.addr), UVM_NONE);
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
      tr.valid_addr = 1;
      if(!tr.randomize()) `uvm_error("SEQ", "reset_dut randomize failed")
      tr.op = rstdut;
      `uvm_info("SEQ", "MODE : RESET", UVM_NONE);
      finish_item(tr);
    end
  endtask
endclass

////////////////////////////////////////////////////////////////////////////////
// STRESS SEQUENCES  —  full 7-bit sweep to close addr_cp + op_x_addr cross
////////////////////////////////////////////////////////////////////////////////

class stress_write extends uvm_sequence#(transaction);
  `uvm_object_utils(stress_write)
  transaction tr;
  function new(string name = "stress_write"); super.new(name); endfunction

  virtual task body();
    repeat(60) begin
      tr = transaction::type_id::create("tr");
      start_item(tr);
      tr.valid_addr = 0;
      if(!tr.randomize()) `uvm_error("SEQ", "stress_write randomize failed")
      tr.op = writed;
      `uvm_info("SEQ", $sformatf("STRESS WRITE ADDR:%0d DIN:%0d", tr.addr, tr.din), UVM_HIGH);
      finish_item(tr);
    end
  endtask
endclass

class stress_read extends uvm_sequence#(transaction);
  `uvm_object_utils(stress_read)
  transaction tr;
  function new(string name = "stress_read"); super.new(name); endfunction

  virtual task body();
    repeat(60) begin
      tr = transaction::type_id::create("tr");
      start_item(tr);
      tr.valid_addr = 0;
      if(!tr.randomize()) `uvm_error("SEQ", "stress_read randomize failed")
      tr.op = readd;
      `uvm_info("SEQ", $sformatf("STRESS READ ADDR:%0d", tr.addr), UVM_HIGH);
      finish_item(tr);
    end
  endtask
endclass

////////////////////////////////////////////////////////////////////////////////
// SEQUENCE LIBRARY  (retained but not used — XSIM UVM 1.2 execute() null deref)
////////////////////////////////////////////////////////////////////////////////
class i2c_seq_lib extends uvm_sequence_library #(transaction);
  `uvm_object_utils(i2c_seq_lib)
  `uvm_sequence_library_utils(i2c_seq_lib)

  function new(string name = "i2c_seq_lib");
    super.new(name);
    add_typewide_sequence(write_data::get_type());
    add_typewide_sequence(read_data::get_type());
    add_typewide_sequence(reset_dut::get_type());
  endfunction
endclass

////////////////////////////////////////////////////////////////////////////////
// DRIVER
////////////////////////////////////////////////////////////////////////////////
class driver extends uvm_driver #(transaction);
  `uvm_component_utils(driver)

  virtual i2c_i vif;
  transaction tr;

  function new(string path = "drv", uvm_component parent = null);
    super.new(path, parent);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    tr = transaction::type_id::create("tr");
    if(!uvm_config_db#(virtual i2c_i)::get(this,"","vif",vif))
      `uvm_error("DRV","Unable to access Interface");
  endfunction

  task reset_dut();
    `uvm_info("DRV", "System Reset", UVM_MEDIUM);
    vif.rst  <= 1'b1;
    vif.addr <= 0;
    vif.din  <= 0;
    vif.wr   <= 0;
    @(posedge vif.clk);
  endtask

  task write_d();
    `uvm_info("DRV", $sformatf("mode : WRITE addr:%0d din:%0d", tr.addr, tr.din), UVM_NONE);
    vif.rst  <= 1'b0;
    vif.wr   <= 1'b1;
    vif.addr <= tr.addr;
    vif.din  <= tr.din;
    @(posedge vif.done);
  endtask

  task read_d();
    `uvm_info("DRV", $sformatf("mode : READ addr:%0d din:%0d", tr.addr, tr.din), UVM_NONE);
    vif.rst  <= 1'b0;
    vif.wr   <= 1'b0;
    vif.addr <= tr.addr;
    vif.din  <= 0;
    @(posedge vif.done);
  endtask

  virtual task run_phase(uvm_phase phase);
    forever begin
      seq_item_port.get_next_item(tr);
      if(tr.op == rstdut)
        reset_dut();
      else if(tr.op == writed)
        write_d();
      else if(tr.op == readd)
        read_d();
      seq_item_port.item_done();
    end
  endtask
endclass

////////////////////////////////////////////////////////////////////////////////
// MONITOR
////////////////////////////////////////////////////////////////////////////////
class mon extends uvm_monitor;
  `uvm_component_utils(mon)

  uvm_analysis_port#(transaction) send;
  transaction tr;
  virtual i2c_i vif;

  function new(string inst = "mon", uvm_component parent = null);
    super.new(inst, parent);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    tr   = transaction::type_id::create("tr");
    send = new("send", this);
    if(!uvm_config_db#(virtual i2c_i)::get(this,"","vif",vif))
      `uvm_error("MON","Unable to access Interface");
  endfunction

  virtual task run_phase(uvm_phase phase);
    forever begin
      @(posedge vif.clk);

      if(vif.rst) begin
        tr.op     = rstdut;
        tr.addr   = 7'h00;
        tr.din    = 8'h00;
        tr.datard = 8'h00;
        `uvm_info("MON", "SYSTEM RESET DETECTED", UVM_NONE);
        send.write(tr);
      end
      else begin
        if(vif.wr) begin
          tr.op     = writed;
          tr.addr   = vif.addr;
          tr.din    = vif.din;
          tr.datard = 8'h00;
          @(posedge vif.done);
          `uvm_info("MON", $sformatf("DATA WRITE addr:%0d data:%0d", tr.addr, tr.din), UVM_NONE);
          send.write(tr);
        end
        else if (!vif.wr) begin
          tr.op   = readd;
          tr.addr = vif.addr;
          tr.din  = 8'h00;
          @(posedge vif.done);
          tr.datard = vif.datard;
          `uvm_info("MON", $sformatf("DATA READ addr:%0d data:%0d", tr.addr, tr.datard), UVM_NONE);
          send.write(tr);
        end
      end
    end
  endtask
endclass

////////////////////////////////////////////////////////////////////////////////
// REFERENCE MODEL
////////////////////////////////////////////////////////////////////////////////
class ref_model extends uvm_monitor;
  `uvm_component_utils(ref_model)

  uvm_analysis_port#(transaction) send_ref;
  transaction tr;
  virtual i2c_i vif;

  logic [7:0] ref_arr [128];

  function new(string inst = "ref_model", uvm_component parent = null);
    super.new(inst, parent);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    tr       = transaction::type_id::create("tr");
    send_ref = new("send_ref", this);
    foreach(ref_arr[i]) ref_arr[i] = 8'h00;
    if(!uvm_config_db#(virtual i2c_i)::get(this,"","vif",vif))
      `uvm_error("REF","Unable to access Interface");
  endfunction

  virtual task run_phase(uvm_phase phase);
    forever begin
      @(posedge vif.clk);

      if(vif.rst) begin
        tr.op     = rstdut;
        tr.addr   = 7'h00;
        tr.din    = 8'h00;
        tr.datard = 8'h00;
        foreach(ref_arr[i]) ref_arr[i] = 8'h00;
        send_ref.write(tr);
      end
      else begin
        if(vif.wr) begin
          tr.op     = writed;
          tr.addr   = vif.addr;
          tr.din    = vif.din;
          tr.datard = 8'h00;
          @(posedge vif.done);
          ref_arr[tr.addr] = tr.din;
          `uvm_info("REF", $sformatf("WRITE addr:%0d din:%0d ref_arr:%0d", tr.addr, tr.din, ref_arr[tr.addr]), UVM_NONE);
          send_ref.write(tr);
        end
        else if (!vif.wr) begin
          tr.op   = readd;
          tr.addr = vif.addr;
          tr.din  = 8'h00;
          @(posedge vif.done);
          tr.datard = ref_arr[tr.addr];
          `uvm_info("REF", $sformatf("READ addr:%0d predicted_datard:%0d", tr.addr, tr.datard), UVM_NONE);
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

      if(tr.op == rstdut)
        `uvm_info("SCO", "System Reset", UVM_NONE)
      else if(tr.compare(trref))
        `uvm_info("SCO", $sformatf("Test PASSED  op:%s addr:%0d din:%0d datard:%0d exp_datard:%0d",
          tr.op.name(), tr.addr, tr.din, tr.datard, trref.datard), UVM_NONE)
      else
        `uvm_info("SCO", $sformatf("Test FAILED  op:%s addr:%0d din:%0d datard:%0d exp_datard:%0d",
          tr.op.name(), tr.addr, tr.din, tr.datard, trref.datard), UVM_NONE)
      $display("----------------------------------------------------------------");
    end
  endtask
endclass

////////////////////////////////////////////////////////////////////////////////
// FUNCTIONAL COVERAGE  —  subscribes to monitor's analysis port
////////////////////////////////////////////////////////////////////////////////
class i2c_coverage extends uvm_subscriber #(transaction);
  `uvm_component_utils(i2c_coverage)

  transaction tr;

  covergroup i2c_cg;
    option.per_instance = 1;
    option.name         = "i2c_cov";

    // ----- Coverpoint 1: operation type -----
    op_cp: coverpoint tr.op {
      bins write_op = {writed};
      bins read_op  = {readd};
    }

    // ----- Coverpoint 2: 7-bit address space -----
    addr_cp: coverpoint tr.addr {
      bins addr_zero    = {7'd0};
      bins range_lo     = {[7'd1   : 7'd31]};
      bins range_lo_mid = {[7'd32  : 7'd63]};
      bins range_hi_mid = {[7'd64  : 7'd95]};
      bins range_hi     = {[7'd96  : 7'd126]};
      bins addr_max     = {7'd127};
    }

    // ----- Coverpoint 3: write data buckets (sampled only on writes) -----
    data_cp: coverpoint tr.din iff (tr.op == writed) {
      bins low  = {[8'h00 : 8'h3F]};
      bins mid  = {[8'h40 : 8'hBF]};
      bins high = {[8'hC0 : 8'hFF]};
    }

    // ----- Cross: op x addr_bucket -----
    op_x_addr: cross op_cp, addr_cp;

  endgroup

  function new(string name, uvm_component parent);
    super.new(name, parent);
    i2c_cg = new();
  endfunction

  function void write(transaction t);
    tr = t;
    i2c_cg.sample();
  endfunction

  function void report_phase(uvm_phase phase);
    `uvm_info("COV", $sformatf("I2C Functional Coverage = %0.2f%%",
      i2c_cg.get_inst_coverage()), UVM_LOW)
  endfunction
endclass

////////////////////////////////////////////////////////////////////////////////
// AGENT
////////////////////////////////////////////////////////////////////////////////
class agent extends uvm_agent;
  `uvm_component_utils(agent)

  driver d;
  uvm_sequencer#(transaction) seqr;
  mon m;
  ref_model ref_m;

  function new(string inst = "agent", uvm_component parent = null);
    super.new(inst, parent);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    m     = mon::type_id::create("m", this);
    ref_m = ref_model::type_id::create("ref_m", this);
    d     = driver::type_id::create("d", this);
    seqr  = uvm_sequencer#(transaction)::type_id::create("seqr", this);
  endfunction

  virtual function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    d.seq_item_port.connect(seqr.seq_item_export);
  endfunction
endclass

////////////////////////////////////////////////////////////////////////////////
// ENVIRONMENT  —  i2c_coverage subscriber alongside scoreboard
////////////////////////////////////////////////////////////////////////////////
class env extends uvm_env;
  `uvm_component_utils(env)

  agent         a;
  sco           s;
  i2c_coverage  cov;

  function new(string inst = "env", uvm_component c);
    super.new(inst, c);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    a   = agent::type_id::create("a", this);
    s   = sco::type_id::create("s", this);
    cov = i2c_coverage::type_id::create("cov", this);
  endfunction

  virtual function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    a.m.send.connect(s.sco_data.analysis_export);
    a.ref_m.send_ref.connect(s.sco_data_ref.analysis_export);
    a.m.send.connect(cov.analysis_export);
  endfunction
endclass

////////////////////////////////////////////////////////////////////////////////
// TEST  —  sequential .start() (XSIM UVM 1.2 sequence_library workaround)
////////////////////////////////////////////////////////////////////////////////
class test extends uvm_test;
  `uvm_component_utils(test)

  env           e;
  write_data    wseq;
  read_data     rseq;
  reset_dut     rstseq;
  stress_write  swseq;
  stress_read   srseq;

  function new(string inst = "test", uvm_component c);
    super.new(inst, c);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    e      = env::type_id::create("env", this);
    wseq   = write_data  ::type_id::create("wseq");
    rseq   = read_data   ::type_id::create("rseq");
    rstseq = reset_dut   ::type_id::create("rstseq");
    swseq  = stress_write::type_id::create("swseq");
    srseq  = stress_read ::type_id::create("srseq");
  endfunction

  virtual task run_phase(uvm_phase phase);
    phase.raise_objection(this);
      `uvm_info("TEST", "=== RESET SEQUENCE START ===", UVM_LOW)
      rstseq.start(e.a.seqr);

      `uvm_info("TEST", "=== WRITE SEQUENCE START ===", UVM_LOW)
      wseq.start(e.a.seqr);

      `uvm_info("TEST", "=== READ SEQUENCE START ===", UVM_LOW)
      rseq.start(e.a.seqr);

      `uvm_info("TEST", "=== STRESS WRITE START ===", UVM_LOW)
      swseq.start(e.a.seqr);

      `uvm_info("TEST", "=== STRESS READ START ===", UVM_LOW)
      srseq.start(e.a.seqr);

      #200ns;
    phase.drop_objection(this);
  endtask
endclass

////////////////////////////////////////////////////////////////////////////////
// TB TOP
////////////////////////////////////////////////////////////////////////////////
module tb;

  i2c_i vif();

  i2c_mem dut (
    .clk(vif.clk),
    .rst(vif.rst),
    .wr(vif.wr),
    .addr(vif.addr),
    .din(vif.din),
    .datard(vif.datard),
    .done(vif.done)
  );

  initial begin
    vif.clk <= 0;
  end

  always #10 vif.clk <= ~vif.clk;

  initial begin
    uvm_config_db#(virtual i2c_i)::set(null, "*", "vif", vif);
    run_test("test");
  end

  initial begin
    $dumpfile("dump.vcd");
    $dumpvars;
  end
endmodule