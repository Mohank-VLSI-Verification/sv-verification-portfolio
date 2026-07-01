`include "uvm_macros.svh"
import uvm_pkg::*;

////////////////////////////////////////////////////////////////////////////////
// CONFIGURATION
////////////////////////////////////////////////////////////////////////////////
class spi_config extends uvm_object;
  `uvm_object_utils(spi_config)
  
  uvm_active_passive_enum is_active = UVM_ACTIVE;
  
  function new(string name = "spi_config");
    super.new(name);
  endfunction
endclass

////////////////////////////////////////////////////////////////////////////////
// OPERATION MODE
////////////////////////////////////////////////////////////////////////////////
typedef enum bit [1:0] {readd = 0, writed = 1, rstdut = 2} oper_mode;

////////////////////////////////////////////////////////////////////////////////
// TRANSACTION
////////////////////////////////////////////////////////////////////////////////
class transaction extends uvm_sequence_item;
    randc logic [7:0] addr;
    rand  logic [7:0] din;
          logic [7:0] dout;
    rand  oper_mode   op;
          logic       rst;
    rand  logic       miso;
          logic       cs;     
          logic       done;
          logic       err;
          logic       ready;
          logic       mosi;
         
    constraint addr_c { addr <= 10; }

    `uvm_object_utils_begin(transaction)
      `uvm_field_enum(oper_mode, op, UVM_DEFAULT)
      `uvm_field_int (addr, UVM_DEFAULT)
      `uvm_field_int (din,  UVM_DEFAULT)
      `uvm_field_int (dout, UVM_DEFAULT)
    `uvm_object_utils_end
  
    function new(string name = "transaction");
      super.new(name);
    endfunction
endclass : transaction

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
      tr.addr_c.constraint_mode(1);
      start_item(tr);
      if(!tr.randomize()) `uvm_error("SEQ", "randomize failed")
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
      tr.addr_c.constraint_mode(1);
      start_item(tr);
      if(!tr.randomize()) `uvm_error("SEQ", "randomize failed")
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
      tr.addr_c.constraint_mode(1);
      start_item(tr);
      if(!tr.randomize()) `uvm_error("SEQ", "randomize failed")
      tr.op = rstdut;
      finish_item(tr);
    end
  endtask
endclass

class writeb_readb extends uvm_sequence#(transaction);
  `uvm_object_utils(writeb_readb)
  transaction tr;
  function new(string name = "writeb_readb"); super.new(name); endfunction
  
  virtual task body();
    repeat(10) begin
      tr = transaction::type_id::create("tr");
      tr.addr_c.constraint_mode(1);
      start_item(tr);
      if(!tr.randomize()) `uvm_error("SEQ", "randomize failed")
      tr.op = writed;
      finish_item(tr);
    end
    repeat(10) begin
      tr = transaction::type_id::create("tr");
      tr.addr_c.constraint_mode(1);
      start_item(tr);
      if(!tr.randomize()) `uvm_error("SEQ", "randomize failed")
      tr.op = readd;
      finish_item(tr);
    end
  endtask
endclass

////////////////////////////////////////////////////////////////////////////////
// DRIVER
////////////////////////////////////////////////////////////////////////////////
class driver extends uvm_driver #(transaction);
  `uvm_component_utils(driver)
  
  virtual spi_i vif;
  transaction tr;
  logic [15:0] data;
  logic [7:0]  datard;
  
  function new(string path = "drv", uvm_component parent = null);
    super.new(path, parent);
  endfunction
  
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    tr = transaction::type_id::create("tr");
    if(!uvm_config_db#(virtual spi_i)::get(this,"","vif",vif))
      `uvm_error("DRV","Unable to access Interface");
  endfunction
  
  task reset_dut(); 
    vif.rst  <= 1'b1;
    vif.miso <= 1'b0;
    vif.cs   <= 1'b1;
    `uvm_info("DRV", "System Reset", UVM_MEDIUM);
    @(posedge vif.clk);
  endtask
  
  task write_d();
    vif.rst  <= 1'b0;
    vif.cs   <= 1'b0;
    vif.miso <= 1'b0;
    data     = {tr.din, tr.addr};
    `uvm_info("DRV", $sformatf("DATA WRITE addr:%0d din:%0d", tr.addr, tr.din), UVM_MEDIUM); 
    @(posedge vif.clk);
    vif.miso <= 1'b1;
    @(posedge vif.clk);
    for(int i = 0; i < 16; i++) begin
      vif.miso <= data[i];
      @(posedge vif.clk);
    end
    @(posedge vif.op_done);
  endtask 
  
  task read_d();
    vif.rst  <= 1'b0;
    vif.cs   <= 1'b0;
    vif.miso <= 1'b0;
    data     = {8'h00, tr.addr};
    @(posedge vif.clk);
    vif.miso <= 1'b0;
    @(posedge vif.clk);
    for(int i = 0; i < 8; i++) begin
      vif.miso <= data[i];
      @(posedge vif.clk);
    end
    @(posedge vif.ready);
    for(int i = 0; i < 8; i++) begin
      @(posedge vif.clk);
      datard[i] = vif.mosi;
    end
    `uvm_info("DRV", $sformatf("DATA READ addr:%0d dout:%0d", tr.addr, datard), UVM_MEDIUM);  
    @(posedge vif.op_done);
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
  virtual spi_i vif;
  logic [15:0] din_buf;
  logic [7:0]  dout_buf;
  
  function new(string inst = "mon", uvm_component parent = null);
    super.new(inst, parent);
  endfunction
  
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    tr   = transaction::type_id::create("tr");
    send = new("send", this);
    if(!uvm_config_db#(virtual spi_i)::get(this,"","vif",vif))
      `uvm_error("MON","Unable to access Interface");
  endfunction
  
  virtual task run_phase(uvm_phase phase);
    forever begin
      @(posedge vif.clk);
      
      if(vif.rst) begin
        tr.op   = rstdut;
        tr.addr = 8'h00;
        tr.din  = 8'h00;
        tr.dout = 8'h00;
        `uvm_info("MON", "SYSTEM RESET DETECTED", UVM_NONE);
        send.write(tr);
      end
      else begin
        @(posedge vif.clk);
        if(vif.miso && !vif.cs) begin
          tr.op = writed;
          @(posedge vif.clk);
          for(int i = 0; i < 16; i++) begin
            din_buf[i] <= vif.miso;
            @(posedge vif.clk);
          end
          tr.addr = din_buf[7:0];
          tr.din  = din_buf[15:8];
          tr.dout = 8'h00;
          @(posedge vif.op_done);
          `uvm_info("MON", $sformatf("DATA WRITE addr:%0d data:%0d", din_buf[7:0], din_buf[15:8]), UVM_NONE); 
          send.write(tr);
        end
        else if (!vif.miso && !vif.cs) begin
          tr.op = readd;
          @(posedge vif.clk);
          for(int i = 0; i < 8; i++) begin
            din_buf[i] <= vif.miso;
            @(posedge vif.clk);
          end
          tr.addr = din_buf[7:0];
          tr.din  = 8'h00;
          @(posedge vif.ready);
          for(int i = 0; i < 8; i++) begin
            @(posedge vif.clk);
            dout_buf[i] = vif.mosi;
          end
          @(posedge vif.op_done);
          tr.dout = dout_buf;
          `uvm_info("MON", $sformatf("DATA READ addr:%0d data:%0d", tr.addr, tr.dout), UVM_NONE); 
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
  virtual spi_i vif;
  
  logic [7:0]  ref_arr [32];
  logic [15:0] din_buf;
  
  function new(string inst = "ref_model", uvm_component parent = null);
    super.new(inst, parent);
  endfunction
  
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    tr       = transaction::type_id::create("tr");
    send_ref = new("send_ref", this);
    foreach(ref_arr[i]) ref_arr[i] = 8'h00;
    if(!uvm_config_db#(virtual spi_i)::get(this,"","vif",vif))
      `uvm_error("REF","Unable to access Interface");
  endfunction
  
  virtual task run_phase(uvm_phase phase);
    forever begin
      @(posedge vif.clk);
      
      if(vif.rst) begin
        tr.op   = rstdut;
        tr.addr = 8'h00;
        tr.din  = 8'h00;
        tr.dout = 8'h00;
        send_ref.write(tr);
      end
      else begin
        @(posedge vif.clk);
        if(vif.miso && !vif.cs) begin
          tr.op = writed;
          @(posedge vif.clk);
          for(int i = 0; i < 16; i++) begin
            din_buf[i] <= vif.miso;
            @(posedge vif.clk);
          end
          tr.addr = din_buf[7:0];
          tr.din  = din_buf[15:8];
          tr.dout = 8'h00;
          @(posedge vif.op_done);
          
          ref_arr[tr.addr] = tr.din;
          
          `uvm_info("REF", $sformatf("WRITE addr:%0d din:%0d ref_arr:%0d", tr.addr, tr.din, ref_arr[tr.addr]), UVM_NONE);
          send_ref.write(tr);
        end
        else if (!vif.miso && !vif.cs) begin
          tr.op = readd;
          @(posedge vif.clk);
          for(int i = 0; i < 8; i++) begin
            din_buf[i] <= vif.miso;
            @(posedge vif.clk);
          end
          tr.addr = din_buf[7:0];
          tr.din  = 8'h00;
          @(posedge vif.ready);
          
          tr.dout = ref_arr[tr.addr];
          
          @(posedge vif.op_done);
          `uvm_info("REF", $sformatf("READ addr:%0d predicted_dout:%0d", tr.addr, tr.dout), UVM_NONE);
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
        `uvm_info("SCO", $sformatf("Test PASSED  op:%s addr:%0d din:%0d dout:%0d exp_dout:%0d",
          tr.op.name(), tr.addr, tr.din, tr.dout, trref.dout), UVM_NONE)
      else
        `uvm_info("SCO", $sformatf("Test FAILED  op:%s addr:%0d din:%0d dout:%0d exp_dout:%0d",
          tr.op.name(), tr.addr, tr.din, tr.dout, trref.dout), UVM_NONE)
      $display("----------------------------------------------------------------");
    end
  endtask
endclass

////////////////////////////////////////////////////////////////////////////////
// FUNCTIONAL COVERAGE  —  subscribes to monitor's analysis port
////////////////////////////////////////////////////////////////////////////////
class spi_coverage extends uvm_subscriber #(transaction);
  `uvm_component_utils(spi_coverage)
  
  transaction tr;
  
  covergroup spi_cg;
    option.per_instance = 1;
    option.name         = "spi_cov";
    
    op_cp: coverpoint tr.op {
      bins write_op = {writed};
      bins read_op  = {readd};
    }
    
    addr_cp: coverpoint tr.addr {
      bins addr[] = {[0:10]};
    }
    
    data_cp: coverpoint tr.din iff (tr.op == writed) {
      bins low  = {[8'h00 : 8'h3F]};
      bins mid  = {[8'h40 : 8'hBF]};
      bins high = {[8'hC0 : 8'hFF]};
    }
    
    op_x_addr: cross op_cp, addr_cp;
    op_x_data: cross op_cp, data_cp;
    
  endgroup
  
  function new(string name, uvm_component parent);
    super.new(name, parent);
    spi_cg = new();
  endfunction
  
  function void write(transaction t);
    if (t.op == rstdut) return;
    tr = t;
    spi_cg.sample();
  endfunction
  
  function void report_phase(uvm_phase phase);
    `uvm_info("COV", $sformatf("SPI Functional Coverage = %0.2f%%",
      spi_cg.get_inst_coverage()), UVM_LOW)
  endfunction
endclass

////////////////////////////////////////////////////////////////////////////////
// AGENT  —  holds coverage per APB lock pattern
////////////////////////////////////////////////////////////////////////////////
class agent extends uvm_agent;
  `uvm_component_utils(agent)
  
  spi_config    cfg;
  driver        d;
  uvm_sequencer#(transaction) seqr;
  mon           m;
  ref_model     ref_m;
  spi_coverage  cov;
  
  function new(string inst = "agent", uvm_component parent = null);
    super.new(inst, parent);
  endfunction
  
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    cfg   = spi_config::type_id::create("cfg"); 
    m     = mon::type_id::create("m", this);
    ref_m = ref_model::type_id::create("ref_m", this);
    cov   = spi_coverage::type_id::create("cov", this);
    
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
  reset_dut     rst_seq;
  write_data    wseq;
  read_data     rseq;
  writeb_readb  wr_seq;
  
  function new(string inst = "test", uvm_component c);
    super.new(inst, c);
  endfunction
  
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    e = env::type_id::create("env", this);
  endfunction
  
  virtual task run_phase(uvm_phase phase);
    phase.raise_objection(this);
    
    rst_seq = reset_dut::type_id::create("rst_seq");
    wseq    = write_data::type_id::create("wseq");
    rseq    = read_data::type_id::create("rseq");
    wr_seq  = writeb_readb::type_id::create("wr_seq");
    
    rst_seq.start(e.a.seqr);
    wseq.start(e.a.seqr);
    rseq.start(e.a.seqr);
    wr_seq.start(e.a.seqr);
    
    #20;
    phase.drop_objection(this);
  endtask
endclass

////////////////////////////////////////////////////////////////////////////////
// TB TOP
////////////////////////////////////////////////////////////////////////////////
module tb;
  
  spi_i vif();
  
  spi_mem dut (
    .clk(vif.clk),
    .rst(vif.rst),
    .cs(vif.cs),
    .miso(vif.miso),
    .ready(vif.ready),
    .mosi(vif.mosi),
    .op_done(vif.op_done)
  );
  
  initial begin
    vif.clk <= 0;
  end
  
  always #10 vif.clk <= ~vif.clk;
  
  initial begin
    uvm_config_db#(virtual spi_i)::set(null, "*", "vif", vif);
    run_test("test");
  end
  
  initial begin
    $dumpfile("dump.vcd");
    $dumpvars;
  end
endmodule