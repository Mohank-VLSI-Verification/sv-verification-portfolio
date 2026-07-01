`include "uvm_macros.svh"
import uvm_pkg::*;

////////////////////////////////////////////////////////////////////////////////
// CONFIGURATION CLASS
////////////////////////////////////////////////////////////////////////////////
class uart_config extends uvm_object;
  `uvm_object_utils(uart_config)
  
  uvm_active_passive_enum is_active = UVM_ACTIVE;
  
  function new(string name = "uart_config");
    super.new(name);
  endfunction
endclass

////////////////////////////////////////////////////////////////////////////////
// OPERATION MODE ENUM
////////////////////////////////////////////////////////////////////////////////
typedef enum bit [3:0] {
  rand_baud_1_stop   = 0,
  rand_length_1_stop = 1,
  length5wp          = 2,
  length6wp          = 3,
  length7wp          = 4,
  length8wp          = 5,
  length5wop         = 6,
  length6wop         = 7,
  length7wop         = 8,
  length8wop         = 9,
  rand_baud_2_stop   = 11,
  rand_length_2_stop = 12
} oper_mode;

////////////////////////////////////////////////////////////////////////////////
// TRANSACTION
////////////////////////////////////////////////////////////////////////////////
class transaction extends uvm_sequence_item;
  
  rand oper_mode     op;
       logic         tx_start, rx_start;
       logic         rst;
  rand logic [7:0]   tx_data;
  rand logic [16:0]  baud;
  rand logic [3:0]   length;
  rand logic         parity_type, parity_en;
       logic         stop2;
       logic         tx_done, rx_done, tx_err, rx_err;
       logic [7:0]   rx_out;
  
  constraint baud_c   { baud   inside {4800,9600,14400,19200,38400,57600}; }
  constraint length_c { length inside {5,6,7,8}; }
  
  `uvm_object_utils_begin(transaction)
    `uvm_field_int (tx_data,     UVM_DEFAULT)
    `uvm_field_int (baud,        UVM_DEFAULT)
    `uvm_field_int (length,      UVM_DEFAULT)
    `uvm_field_int (parity_type, UVM_DEFAULT)
    `uvm_field_int (parity_en,   UVM_DEFAULT)
    `uvm_field_int (stop2,       UVM_DEFAULT)
    `uvm_field_int (rx_out,      UVM_DEFAULT)
    `uvm_field_int (rst,         UVM_DEFAULT)
    `uvm_field_enum(oper_mode, op, UVM_DEFAULT)
  `uvm_object_utils_end
  
  function new(string name = "transaction");
    super.new(name);
  endfunction
endclass : transaction

////////////////////////////////////////////////////////////////////////////////
// SEQUENCES  (all 10)
////////////////////////////////////////////////////////////////////////////////

class rand_baud extends uvm_sequence#(transaction);
  `uvm_object_utils(rand_baud)
  transaction tr;
  function new(string name = "rand_baud"); super.new(name); endfunction
  virtual task body();
    repeat(5) begin
      tr = transaction::type_id::create("tr");
      start_item(tr);
      if(!tr.randomize()) `uvm_error("SEQ", "randomize failed")
      tr.op = rand_baud_1_stop; tr.length = 8; tr.baud = 9600;
      tr.rst = 1'b0; tr.tx_start = 1'b1; tr.rx_start = 1'b1;
      tr.parity_en = 1'b1; tr.stop2 = 1'b0;
      finish_item(tr);
    end
  endtask
endclass

class rand_baud_with_stop extends uvm_sequence#(transaction);
  `uvm_object_utils(rand_baud_with_stop)
  transaction tr;
  function new(string name = "rand_baud_with_stop"); super.new(name); endfunction
  virtual task body();
    repeat(5) begin
      tr = transaction::type_id::create("tr");
      start_item(tr);
      if(!tr.randomize()) `uvm_error("SEQ", "randomize failed")
      tr.op = rand_baud_2_stop; tr.rst = 1'b0; tr.length = 8;
      tr.tx_start = 1'b1; tr.rx_start = 1'b1; tr.parity_en = 1'b1; tr.stop2 = 1'b1;
      finish_item(tr);
    end
  endtask
endclass

class rand_baud_len5p extends uvm_sequence#(transaction);
  `uvm_object_utils(rand_baud_len5p)
  transaction tr;
  function new(string name = "rand_baud_len5p"); super.new(name); endfunction
  virtual task body();
    repeat(5) begin
      tr = transaction::type_id::create("tr");
      start_item(tr);
      if(!tr.randomize()) `uvm_error("SEQ", "randomize failed")
      tr.op = length5wp; tr.rst = 1'b0; tr.tx_data = {3'b000, tr.tx_data[7:3]};
      tr.length = 5; tr.tx_start = 1'b1; tr.rx_start = 1'b1;
      tr.parity_en = 1'b1; tr.stop2 = 1'b0;
      finish_item(tr);
    end
  endtask
endclass

class rand_baud_len6p extends uvm_sequence#(transaction);
  `uvm_object_utils(rand_baud_len6p)
  transaction tr;
  function new(string name = "rand_baud_len6p"); super.new(name); endfunction
  virtual task body();
    repeat(5) begin
      tr = transaction::type_id::create("tr");
      start_item(tr);
      if(!tr.randomize()) `uvm_error("SEQ", "randomize failed")
      tr.op = length6wp; tr.rst = 1'b0; tr.length = 6;
      tr.tx_data = {2'b00, tr.tx_data[7:2]};
      tr.tx_start = 1'b1; tr.rx_start = 1'b1; tr.parity_en = 1'b1; tr.stop2 = 1'b0;
      finish_item(tr);
    end
  endtask
endclass

class rand_baud_len7p extends uvm_sequence#(transaction);
  `uvm_object_utils(rand_baud_len7p)
  transaction tr;
  function new(string name = "rand_baud_len7p"); super.new(name); endfunction
  virtual task body();
    repeat(5) begin
      tr = transaction::type_id::create("tr");
      start_item(tr);
      if(!tr.randomize()) `uvm_error("SEQ", "randomize failed")
      tr.op = length7wp; tr.rst = 1'b0; tr.length = 7;
      tr.tx_data = {1'b0, tr.tx_data[7:1]};
      tr.tx_start = 1'b1; tr.rx_start = 1'b1; tr.parity_en = 1'b1; tr.stop2 = 1'b0;
      finish_item(tr);
    end
  endtask
endclass

class rand_baud_len8p extends uvm_sequence#(transaction);
  `uvm_object_utils(rand_baud_len8p)
  transaction tr;
  function new(string name = "rand_baud_len8p"); super.new(name); endfunction
  virtual task body();
    repeat(5) begin
      tr = transaction::type_id::create("tr");
      start_item(tr);
      if(!tr.randomize()) `uvm_error("SEQ", "randomize failed")
      tr.op = length8wp; tr.rst = 1'b0; tr.length = 8;
      tr.tx_data = tr.tx_data[7:0];
      tr.tx_start = 1'b1; tr.rx_start = 1'b1; tr.parity_en = 1'b1; tr.stop2 = 1'b0;
      finish_item(tr);
    end
  endtask
endclass

class rand_baud_len5 extends uvm_sequence#(transaction);
  `uvm_object_utils(rand_baud_len5)
  transaction tr;
  function new(string name = "rand_baud_len5"); super.new(name); endfunction
  virtual task body();
    repeat(5) begin
      tr = transaction::type_id::create("tr");
      start_item(tr);
      if(!tr.randomize()) `uvm_error("SEQ", "randomize failed")
      tr.op = length5wop; tr.rst = 1'b0; tr.length = 5;
      tr.tx_data = {3'b000, tr.tx_data[7:3]};
      tr.tx_start = 1'b1; tr.rx_start = 1'b1; tr.parity_en = 1'b0; tr.stop2 = 1'b0;
      finish_item(tr);
    end
  endtask
endclass

class rand_baud_len6 extends uvm_sequence#(transaction);
  `uvm_object_utils(rand_baud_len6)
  transaction tr;
  function new(string name = "rand_baud_len6"); super.new(name); endfunction
  virtual task body();
    repeat(5) begin
      tr = transaction::type_id::create("tr");
      start_item(tr);
      if(!tr.randomize()) `uvm_error("SEQ", "randomize failed")
      tr.op = length6wop; tr.rst = 1'b0; tr.length = 6;
      tr.tx_data = {2'b00, tr.tx_data[7:2]};
      tr.tx_start = 1'b1; tr.rx_start = 1'b1; tr.parity_en = 1'b0; tr.stop2 = 1'b0;
      finish_item(tr);
    end
  endtask
endclass

class rand_baud_len7 extends uvm_sequence#(transaction);
  `uvm_object_utils(rand_baud_len7)
  transaction tr;
  function new(string name = "rand_baud_len7"); super.new(name); endfunction
  virtual task body();
    repeat(5) begin
      tr = transaction::type_id::create("tr");
      start_item(tr);
      if(!tr.randomize()) `uvm_error("SEQ", "randomize failed")
      tr.op = length7wop; tr.rst = 1'b0; tr.length = 7;
      tr.tx_data = {1'b0, tr.tx_data[7:1]};
      tr.tx_start = 1'b1; tr.rx_start = 1'b1; tr.parity_en = 1'b0; tr.stop2 = 1'b0;
      finish_item(tr);
    end
  endtask
endclass

class rand_baud_len8 extends uvm_sequence#(transaction);
  `uvm_object_utils(rand_baud_len8)
  transaction tr;
  function new(string name = "rand_baud_len8"); super.new(name); endfunction
  virtual task body();
    repeat(5) begin
      tr = transaction::type_id::create("tr");
      start_item(tr);
      if(!tr.randomize()) `uvm_error("SEQ", "randomize failed")
      tr.op = length8wop; tr.rst = 1'b0; tr.length = 8;
      tr.tx_data = tr.tx_data[7:0];
      tr.tx_start = 1'b1; tr.rx_start = 1'b1; tr.parity_en = 1'b0; tr.stop2 = 1'b0;
      finish_item(tr);
    end
  endtask
endclass

////////////////////////////////////////////////////////////////////////////////
// DRIVER
////////////////////////////////////////////////////////////////////////////////
class driver extends uvm_driver #(transaction);
  `uvm_component_utils(driver)
  
  virtual uart_if vif;
  transaction tr;
  
  function new(string path = "drv", uvm_component parent = null);
    super.new(path, parent);
  endfunction
  
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    tr = transaction::type_id::create("tr");
    if(!uvm_config_db#(virtual uart_if)::get(this,"","vif",vif))
      `uvm_error("DRV","Unable to access Interface");
  endfunction
  
  task reset_dut();
    repeat(5) begin
      vif.rst         <= 1'b1;
      vif.tx_start    <= 1'b0;
      vif.rx_start    <= 1'b0;
      vif.tx_data     <= 8'h00;
      vif.baud        <= 17'h0;
      vif.length      <= 4'h0;
      vif.parity_type <= 1'b0;
      vif.parity_en   <= 1'b0;
      vif.stop2       <= 1'b0;
      `uvm_info("DRV", "System Reset : Start of Simulation", UVM_MEDIUM);
      @(posedge vif.clk);
    end
  endtask
  
  task drive();
    reset_dut();
    forever begin
      seq_item_port.get_next_item(tr);
      vif.rst         <= 1'b0;
      vif.tx_start    <= tr.tx_start;
      vif.rx_start    <= tr.rx_start;
      vif.tx_data     <= tr.tx_data;
      vif.baud        <= tr.baud;
      vif.length      <= tr.length;
      vif.parity_type <= tr.parity_type;
      vif.parity_en   <= tr.parity_en;
      vif.stop2       <= tr.stop2;
      `uvm_info("DRV", $sformatf("BAUD:%0d LEN:%0d PAR_T:%0d PAR_EN:%0d STOP:%0d TX_DATA:%0d",
        tr.baud, tr.length, tr.parity_type, tr.parity_en, tr.stop2, tr.tx_data), UVM_NONE);
      @(posedge vif.clk);
      @(posedge vif.tx_done);
      @(negedge vif.rx_done);
      seq_item_port.item_done();
    end
  endtask
  
  virtual task run_phase(uvm_phase phase);
    drive();
  endtask
endclass

////////////////////////////////////////////////////////////////////////////////
// MONITOR  —  samples at posedge clk on rx_done rising edge
////////////////////////////////////////////////////////////////////////////////
class mon extends uvm_monitor;
  `uvm_component_utils(mon)
  
  uvm_analysis_port#(transaction) send;
  transaction tr;
  virtual uart_if vif;
  
  function new(string inst = "mon", uvm_component parent = null);
    super.new(inst, parent);
  endfunction
  
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    tr   = transaction::type_id::create("tr");
    send = new("send", this);
    if(!uvm_config_db#(virtual uart_if)::get(this,"","vif",vif))
      `uvm_error("MON","Unable to access Interface");
  endfunction
  
  virtual task run_phase(uvm_phase phase);
    bit rst_prev     = 1'b0;
    bit rx_done_prev = 1'b0;
    forever begin
      @(posedge vif.clk);
      if(vif.rst && !rst_prev) begin
        tr.rst = 1'b1;
        `uvm_info("MON", "SYSTEM RESET DETECTED", UVM_NONE)
        send.write(tr);
      end
      else if(!vif.rst && vif.rx_done && !rx_done_prev) begin
        tr.rst         = 1'b0;
        tr.tx_start    = vif.tx_start;
        tr.rx_start    = vif.rx_start;
        tr.tx_data     = vif.tx_data;
        tr.baud        = vif.baud;
        tr.length      = vif.length;
        tr.parity_type = vif.parity_type;
        tr.parity_en   = vif.parity_en;
        tr.stop2       = vif.stop2;
        tr.rx_out      = vif.rx_out;
        `uvm_info("MON", $sformatf("BAUD:%0d LEN:%0d PAR_T:%0d PAR_EN:%0d STOP:%0d TX_DATA:%0d RX_DATA:%0d",
          tr.baud, tr.length, tr.parity_type, tr.parity_en, tr.stop2, tr.tx_data, tr.rx_out), UVM_NONE)
        send.write(tr);
      end
      rst_prev     = vif.rst;
      rx_done_prev = vif.rx_done;
    end
  endtask
endclass

////////////////////////////////////////////////////////////////////////////////
// REFERENCE MODEL  —  matches monitor sampling pattern
////////////////////////////////////////////////////////////////////////////////
class ref_model extends uvm_monitor;
  `uvm_component_utils(ref_model)
  
  uvm_analysis_port#(transaction) send_ref;
  transaction tr;
  virtual uart_if vif;
  
  function new(string inst = "ref_model", uvm_component parent = null);
    super.new(inst, parent);
  endfunction
  
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    tr       = transaction::type_id::create("tr");
    send_ref = new("send_ref", this);
    if(!uvm_config_db#(virtual uart_if)::get(this,"","vif",vif))
      `uvm_error("REF","Unable to access Interface");
  endfunction
  
  function void predict();
    tr.rx_out = tr.tx_data;
  endfunction
  
  virtual task run_phase(uvm_phase phase);
    bit rst_prev     = 1'b0;
    bit rx_done_prev = 1'b0;
    forever begin
      @(posedge vif.clk);
      if(vif.rst && !rst_prev) begin
        tr.rst = 1'b1;
        send_ref.write(tr);
      end
      else if(!vif.rst && vif.rx_done && !rx_done_prev) begin
        tr.rst         = 1'b0;
        tr.tx_start    = vif.tx_start;
        tr.rx_start    = vif.rx_start;
        tr.tx_data     = vif.tx_data;
        tr.baud        = vif.baud;
        tr.length      = vif.length;
        tr.parity_type = vif.parity_type;
        tr.parity_en   = vif.parity_en;
        tr.stop2       = vif.stop2;
        predict();
        `uvm_info("REF", $sformatf("EXPECTED RX:%0d (TX:%0d LEN:%0d)",
          tr.rx_out, tr.tx_data, tr.length), UVM_NONE)
        send_ref.write(tr);
      end
      rst_prev     = vif.rst;
      rx_done_prev = vif.rx_done;
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
      
      if(tr.rst == 1'b1)
        `uvm_info("SCO", "System Reset", UVM_NONE)
      else if(tr.compare(trref))
        `uvm_info("SCO", $sformatf("Test PASSED  TX:%0d RX:%0d EXP_RX:%0d LEN:%0d",
          tr.tx_data, tr.rx_out, trref.rx_out, tr.length), UVM_NONE)
      else
        `uvm_info("SCO", $sformatf("Test FAILED  TX:%0d RX:%0d EXP_RX:%0d LEN:%0d",
          tr.tx_data, tr.rx_out, trref.rx_out, tr.length), UVM_NONE)
      $display("----------------------------------------------------------------");
    end
  endtask
endclass

////////////////////////////////////////////////////////////////////////////////
// FUNCTIONAL COVERAGE  —  subscribes to monitor's analysis port
////////////////////////////////////////////////////////////////////////////////
class uart_coverage extends uvm_subscriber #(transaction);
  `uvm_component_utils(uart_coverage)
  
  transaction tr;
  
  covergroup uart_cg;
    option.per_instance = 1;
    option.name         = "uart_cov";
    
    op_cp: coverpoint tr.op {
      bins baud_1s      = {rand_baud_1_stop};
      bins baud_2s      = {rand_baud_2_stop};
      bins len5_par     = {length5wp};
      bins len6_par     = {length6wp};
      bins len7_par     = {length7wp};
      bins len8_par     = {length8wp};
      bins len5_nopar   = {length5wop};
      bins len6_nopar   = {length6wop};
      bins len7_nopar   = {length7wop};
      bins len8_nopar   = {length8wop};
    }
    
    data_cp: coverpoint tr.tx_data {
      bins data_zero   = {8'h00};
      bins data_lo     = {[8'h01 : 8'h3F]};
      bins data_mid_lo = {[8'h40 : 8'h7F]};
      bins data_mid_hi = {[8'h80 : 8'hBF]};
      bins data_hi     = {[8'hC0 : 8'hFE]};
      bins data_max    = {8'hFF};
    }
    
    parity_cp: coverpoint {tr.parity_en, tr.parity_type} {
      bins none = {2'b00, 2'b01};
      bins even = {2'b10};
      bins odd  = {2'b11};
    }
    
    stop_cp: coverpoint tr.stop2 {
      bins one_stop = {1'b0};
      bins two_stop = {1'b1};
    }
    
    length_cp: coverpoint tr.length {
      bins five_bit  = {4'd5};
      bins six_bit   = {4'd6};
      bins seven_bit = {4'd7};
      bins eight_bit = {4'd8};
    }
    
    baud_cp: coverpoint tr.baud {
      bins baud_4800  = {17'd4800};
      bins baud_9600  = {17'd9600};
      bins baud_14400 = {17'd14400};
      bins baud_19200 = {17'd19200};
      bins baud_38400 = {17'd38400};
      bins baud_57600 = {17'd57600};
    }
    
    parity_x_length: cross parity_cp, length_cp;
    parity_x_stop:   cross parity_cp, stop_cp;
    length_x_baud:   cross length_cp, baud_cp;
    
  endgroup
  
  function new(string name, uvm_component parent);
    super.new(name, parent);
    uart_cg = new();
  endfunction
  
  function void write(transaction t);
    if (t.rst) return;
    tr = t;
    uart_cg.sample();
  endfunction
  
  function void report_phase(uvm_phase phase);
    `uvm_info("COV", $sformatf("UART Functional Coverage = %0.2f%%",
      uart_cg.get_inst_coverage()), UVM_LOW)
  endfunction
endclass

////////////////////////////////////////////////////////////////////////////////
// AGENT  —  holds coverage per APB lock pattern
////////////////////////////////////////////////////////////////////////////////
class agent extends uvm_agent;
  `uvm_component_utils(agent)
  
  uart_config    cfg;
  driver         d;
  uvm_sequencer#(transaction) seqr;
  mon            m;
  ref_model      ref_m;
  uart_coverage  cov;
  
  function new(string inst = "agent", uvm_component parent = null);
    super.new(inst, parent);
  endfunction
  
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    cfg   = uart_config::type_id::create("cfg");
    m     = mon::type_id::create("m", this);
    ref_m = ref_model::type_id::create("ref_m", this);
    cov   = uart_coverage::type_id::create("cov", this);
    
    if(cfg.is_active == UVM_ACTIVE) begin
      d    = driver::type_id::create("d", this);
      seqr = uvm_sequencer#(transaction)::type_id::create("seqr", this);
    end
  endfunction
  
  virtual function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    if(cfg.is_active == UVM_ACTIVE) begin
      d.seq_item_port.connect(seqr.seq_item_export);
    end
    m.send.connect(cov.analysis_export);
  endfunction
endclass

////////////////////////////////////////////////////////////////////////////////
// ENVIRONMENT
////////////////////////////////////////////////////////////////////////////////
class env extends uvm_env;
  `uvm_component_utils(env)
  
  agent  a;
  sco    s;
  
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
// TEST  —  sequential seq.start() only, no uvm_sequence_library
////////////////////////////////////////////////////////////////////////////////
class test extends uvm_test;
  `uvm_component_utils(test)
  
  env e;
  rand_baud            s1;
  rand_baud_with_stop  s2;
  rand_baud_len5p      s3;
  rand_baud_len6p      s4;
  rand_baud_len7p      s5;
  rand_baud_len8p      s6;
  rand_baud_len5       s7;
  rand_baud_len6       s8;
  rand_baud_len7       s9;
  rand_baud_len8       s10;
  
  function new(string inst = "test", uvm_component c);
    super.new(inst, c);
  endfunction
  
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    e = env::type_id::create("env", this);
  endfunction
  
  virtual task run_phase(uvm_phase phase);
    phase.raise_objection(this);
    
    s1  = rand_baud::type_id::create("s1");
    s2  = rand_baud_with_stop::type_id::create("s2");
    s3  = rand_baud_len5p::type_id::create("s3");
    s4  = rand_baud_len6p::type_id::create("s4");
    s5  = rand_baud_len7p::type_id::create("s5");
    s6  = rand_baud_len8p::type_id::create("s6");
    s7  = rand_baud_len5::type_id::create("s7");
    s8  = rand_baud_len6::type_id::create("s8");
    s9  = rand_baud_len7::type_id::create("s9");
    s10 = rand_baud_len8::type_id::create("s10");
    
    s1.start(e.a.seqr);
    s2.start(e.a.seqr);
    s3.start(e.a.seqr);
    s4.start(e.a.seqr);
    s5.start(e.a.seqr);
    s6.start(e.a.seqr);
    s7.start(e.a.seqr);
    s8.start(e.a.seqr);
    s9.start(e.a.seqr);
    s10.start(e.a.seqr);
    
    #20;
    phase.drop_objection(this);
  endtask
endclass

////////////////////////////////////////////////////////////////////////////////
// TB TOP
////////////////////////////////////////////////////////////////////////////////
module tb;
  
  uart_if vif();
  
  uart_top dut (
    .clk(vif.clk),
    .rst(vif.rst),
    .tx_start(vif.tx_start),
    .rx_start(vif.rx_start),
    .tx_data(vif.tx_data),
    .baud(vif.baud),
    .length(vif.length),
    .parity_type(vif.parity_type),
    .parity_en(vif.parity_en),
    .stop2(vif.stop2),
    .tx_done(vif.tx_done),
    .rx_done(vif.rx_done),
    .tx_err(vif.tx_err),
    .rx_err(vif.rx_err),
    .rx_out(vif.rx_out)
  );
  
  initial begin
    vif.clk <= 0;
  end
  
  always #10 vif.clk <= ~vif.clk;
  
  initial begin
    uvm_config_db#(virtual uart_if)::set(null, "*", "vif", vif);
    run_test("test");
  end
  
  initial begin
    $dumpfile("dump.vcd");
    $dumpvars;
  end
  
endmodule