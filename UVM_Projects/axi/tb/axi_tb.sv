`include "uvm_macros.svh"
import uvm_pkg::*;

////////////////////////////////////////////////////////////////////////////////
// OPERATION MODE
////////////////////////////////////////////////////////////////////////////////
typedef enum bit [2:0] {wrrdfixed = 0, wrrdincr = 1, wrrdwrap = 2, wrrderrfix = 3, rstdut = 4} oper_mode;

////////////////////////////////////////////////////////////////////////////////
// TRANSACTION
////////////////////////////////////////////////////////////////////////////////
class transaction extends uvm_sequence_item;
  
       int        len = 0;
  rand bit [3:0]  id;
       oper_mode  op;
  rand bit        awvalid;
       bit       awready;
       bit [3:0] awid;
  rand bit [3:0] awlen;
  rand bit [2:0] awsize;
  rand bit [31:0] awaddr;
  rand bit [1:0] awburst;
  
       bit       wvalid;
       bit       wready;
       bit [3:0] wid;
  rand bit [31:0] wdata;
  rand bit [3:0] wstrb;
       bit       wlast;
  
       bit       bready;
       bit       bvalid;
       bit [3:0] bid;
       bit [1:0] bresp;
  
  rand bit       arvalid;
       bit       arready;
       bit [3:0] arid;
  rand bit [3:0] arlen;
       bit [2:0] arsize;
  rand bit [31:0] araddr;
  rand bit [1:0] arburst;
  
       bit       rvalid;
       bit       rready;
       bit [3:0] rid;
       bit [31:0] rdata;
       bit [3:0] rstrb;
       bit       rlast;
       bit [1:0] rresp;
  
  bit [31:0] rdata_beats [];
  
  constraint txid   { awid == id; wid == id; bid == id; arid == id; rid == id; }
  constraint burst  { awburst inside {0,1,2}; arburst inside {0,1,2}; }
  constraint valid_c { awvalid != arvalid; }
  constraint length { awlen == arlen; }
  
  `uvm_object_utils_begin(transaction)
    `uvm_field_enum(oper_mode, op, UVM_DEFAULT)
    `uvm_field_int(awaddr,  UVM_DEFAULT)
    `uvm_field_int(awlen,   UVM_DEFAULT)
    `uvm_field_int(awburst, UVM_DEFAULT)
    `uvm_field_array_int(rdata_beats, UVM_DEFAULT)
    `uvm_field_int(bresp,   UVM_DEFAULT)
    `uvm_field_int(rresp,   UVM_DEFAULT)
  `uvm_object_utils_end
  
  function new(string name = "transaction");
    super.new(name);
  endfunction
endclass : transaction

////////////////////////////////////////////////////////////////////////////////
// SEQUENCES
////////////////////////////////////////////////////////////////////////////////

class rst_dut extends uvm_sequence#(transaction);
  `uvm_object_utils(rst_dut)
  transaction tr;
  function new(string name = "rst_dut"); super.new(name); endfunction
  
  virtual task body();
    repeat(5) begin
      tr = transaction::type_id::create("tr");
      $display("------------------------------");
      `uvm_info("SEQ", "Sending RST Transaction to DRV", UVM_NONE);
      start_item(tr);
      if(!tr.randomize()) `uvm_error("SEQ", "randomize failed")
      tr.op = rstdut;
      finish_item(tr);
    end
  endtask
endclass

class valid_wrrd_fixed extends uvm_sequence#(transaction);
  `uvm_object_utils(valid_wrrd_fixed)
  transaction tr;
  function new(string name = "valid_wrrd_fixed"); super.new(name); endfunction
  
  virtual task body();
    tr = transaction::type_id::create("tr");
    $display("------------------------------");
    `uvm_info("SEQ", "Sending Fixed mode Transaction to DRV", UVM_NONE);
    start_item(tr);
    if(!tr.randomize()) `uvm_error("SEQ", "randomize failed")
    tr.op      = wrrdfixed;
    tr.awlen   = 7;
    tr.awburst = 0;
    tr.awsize  = 2;
    finish_item(tr);
  endtask
endclass

class valid_wrrd_incr extends uvm_sequence#(transaction);
  `uvm_object_utils(valid_wrrd_incr)
  transaction tr;
  function new(string name = "valid_wrrd_incr"); super.new(name); endfunction
  
  virtual task body();
    tr = transaction::type_id::create("tr");
    $display("------------------------------");
    `uvm_info("SEQ", "Sending INCR mode Transaction to DRV", UVM_NONE);
    start_item(tr);
    if(!tr.randomize()) `uvm_error("SEQ", "randomize failed")
    tr.op      = wrrdincr;
    tr.awlen   = 7;
    tr.awburst = 1;
    tr.awsize  = 2;
    finish_item(tr);
  endtask
endclass

class valid_wrrd_wrap extends uvm_sequence#(transaction);
  `uvm_object_utils(valid_wrrd_wrap)
  transaction tr;
  function new(string name = "valid_wrrd_wrap"); super.new(name); endfunction
  
  virtual task body();
    tr = transaction::type_id::create("tr");
    $display("------------------------------");
    `uvm_info("SEQ", "Sending WRAP mode Transaction to DRV", UVM_NONE);
    start_item(tr);
    if(!tr.randomize()) `uvm_error("SEQ", "randomize failed")
    tr.op      = wrrdwrap;
    tr.awlen   = 7;
    tr.awburst = 2;
    tr.awsize  = 2;
    finish_item(tr);
  endtask
endclass

class err_wrrd_fix extends uvm_sequence#(transaction);
  `uvm_object_utils(err_wrrd_fix)
  transaction tr;
  function new(string name = "err_wrrd_fix"); super.new(name); endfunction
  
  virtual task body();
    tr = transaction::type_id::create("tr");
    $display("------------------------------");
    `uvm_info("SEQ", "Sending Error Transaction to DRV", UVM_NONE);
    start_item(tr);
    if(!tr.randomize()) `uvm_error("SEQ", "randomize failed")
    tr.op      = wrrderrfix;
    tr.awlen   = 7;
    tr.awburst = 0;
    tr.awsize  = 2;   
    finish_item(tr);
  endtask
endclass

////////////////////////////////////////////////////////////////////////////////
// DRIVER
////////////////////////////////////////////////////////////////////////////////
class driver extends uvm_driver #(transaction);
  `uvm_component_utils(driver)
  
  virtual axi_if vif;
  transaction tr;
  
  function new(string path = "drv", uvm_component parent = null);
    super.new(path, parent);
  endfunction
  
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    tr = transaction::type_id::create("tr");
    if(!uvm_config_db#(virtual axi_if)::get(this,"","vif",vif)) 
      `uvm_error("DRV","Unable to access Interface");
  endfunction
  
  task reset_dut(); 
    `uvm_info("DRV", "System Reset : Start of Simulation", UVM_MEDIUM);
    vif.resetn  <= 1'b0;
    vif.awvalid <= 1'b0;  vif.awid <= 1'b0;  vif.awlen <= 0;  vif.awsize <= 0;
    vif.awaddr  <= 0;     vif.awburst <= 0;
    vif.wvalid  <= 0;     vif.wid <= 0;      vif.wdata <= 0;  vif.wstrb <= 0; vif.wlast <= 0;
    vif.bready  <= 0;
    vif.arvalid <= 1'b0;  vif.arid <= 1'b0;  vif.arlen <= 0;  vif.arsize <= 0;
    vif.araddr  <= 0;     vif.arburst <= 0; 
    vif.rready  <= 0;
    @(posedge vif.clk);
  endtask
  
  task wrrd_fixed_wr();
    `uvm_info("DRV", "Fixed Mode Write Transaction Started", UVM_NONE);
    vif.resetn <= 1'b1;  vif.awvalid <= 1'b1;  vif.awid <= tr.id;
    vif.awlen  <= 7;     vif.awsize  <= 2;     vif.awaddr <= 5;  vif.awburst <= 0;
    vif.wvalid <= 1'b1;  vif.wid <= tr.id;     vif.wdata <= $urandom_range(0,10);
    vif.wstrb  <= 4'b1111; vif.wlast <= 0;
    vif.arvalid <= 1'b0; vif.rready <= 1'b0;  vif.bready <= 1'b0;
    @(posedge vif.clk);
    @(posedge vif.wready);
    @(posedge vif.clk);
    for(int i = 0; i < (vif.awlen); i++) begin
      vif.wdata <= $urandom_range(0,10);
      vif.wstrb <= 4'b1111;
      @(posedge vif.wready);
      @(posedge vif.clk);
    end
    vif.awvalid <= 1'b0;  vif.wvalid <= 1'b0;
    vif.wlast   <= 1'b1;  vif.bready <= 1'b1;
    @(negedge vif.bvalid); 
    vif.wlast <= 1'b0;  vif.bready <= 1'b0;  
  endtask
   
  task wrrd_fixed_rd(); 
    `uvm_info("DRV", "Fixed Mode Read Transaction Started", UVM_NONE);   
    @(posedge vif.clk);
    vif.arid <= tr.id;  vif.arlen <= 7;  vif.arsize <= 2;  vif.araddr <= 5;
    vif.arburst <= 0;   vif.arvalid <= 1'b1;  vif.rready <= 1'b1;
    for(int i = 0; i < (vif.arlen + 1); i++) begin
      @(posedge vif.arready);
      @(posedge vif.clk);
    end
    @(negedge vif.rlast);      
    vif.arvalid <= 1'b0;  vif.rready <= 1'b0; 
  endtask
 
  task wrrd_incr_wr();
    `uvm_info("DRV", "INCR Mode Write Transaction Started", UVM_NONE);
    vif.resetn <= 1'b1;  vif.awvalid <= 1'b1;  vif.awid <= tr.id;
    vif.awlen <= 7;      vif.awsize  <= 2;     vif.awaddr <= 5;  vif.awburst <= 1;
    vif.wvalid <= 1'b1;  vif.wid <= tr.id;     vif.wdata <= $urandom_range(0,10);
    vif.wstrb  <= 4'b1111; vif.wlast <= 0;
    vif.arvalid <= 1'b0; vif.rready <= 1'b0;  vif.bready <= 1'b0;
    @(posedge vif.clk);
    @(posedge vif.wready);
    @(posedge vif.clk);
    for(int i = 0; i < (vif.awlen); i++) begin
      vif.wdata <= $urandom_range(0,10);
      vif.wstrb <= 4'b1111;
      @(posedge vif.wready);
      @(posedge vif.clk);
    end
    vif.wlast <= 1'b1;  vif.bready <= 1'b1;
    vif.awvalid <= 1'b0;  vif.wvalid <= 1'b0;
    @(negedge vif.bvalid);
    vif.bready <= 1'b0;  vif.wlast <= 1'b0; 
  endtask   
      
  task wrrd_incr_rd();  
    `uvm_info("DRV", "INCR Mode Read Transaction Started", UVM_NONE);  
    @(posedge vif.clk);
    vif.arid <= tr.id;  vif.arlen <= 7;  vif.arsize <= 2;  vif.araddr <= 5;
    vif.arburst <= 1;   vif.arvalid <= 1'b1;  vif.rready <= 1'b1;
    for(int i = 0; i < (vif.arlen + 1); i++) begin
      @(posedge vif.arready);
      @(posedge vif.clk);
    end
    @(negedge vif.rlast);
    vif.arvalid <= 1'b0;  vif.rready <= 1'b0; 
  endtask

  task wrrd_wrap_wr();
    `uvm_info("DRV", "WRAP Mode Write Transaction Started", UVM_NONE);  
    vif.resetn <= 1'b1;  vif.awvalid <= 1'b1;  vif.awid <= tr.id;
    vif.awlen <= 7;      vif.awsize  <= 2;     vif.awaddr <= 5;  vif.awburst <= 2;
    vif.wvalid <= 1'b1;  vif.wid <= tr.id;     vif.wdata <= $urandom_range(0,10);
    vif.wstrb  <= 4'b1111; vif.wlast <= 0;
    vif.arvalid <= 1'b0; vif.rready <= 1'b0;  vif.bready <= 1'b0;
    @(posedge vif.clk);
    @(posedge vif.wready);
    @(posedge vif.clk);
    for(int i = 0; i < (vif.awlen); i++) begin
      vif.wdata <= $urandom_range(0,10);
      vif.wstrb <= 4'b1111;
      @(posedge vif.wready);
      @(posedge vif.clk);
    end
    vif.wlast <= 1'b1;  vif.bready <= 1'b1;
    vif.awvalid <= 1'b0;  vif.wvalid <= 1'b0;
    @(negedge vif.bvalid);
    vif.bready <= 1'b0;  vif.wlast <= 1'b0; 
  endtask 
         
  task wrrd_wrap_rd(); 
    `uvm_info("DRV", "WRAP Mode Read Transaction Started", UVM_NONE);  
    @(posedge vif.clk);
    vif.arvalid <= 1'b1;  vif.rready <= 1'b1;
    vif.arid <= tr.id;  vif.arlen <= 7;  vif.arsize <= 2;  vif.araddr <= 5;
    vif.arburst <= 2; 
    for(int i = 0; i < (vif.arlen + 1); i++) begin
      @(posedge vif.arready);
      @(posedge vif.clk);
    end
    @(negedge vif.rlast);
    vif.arvalid <= 1'b0;  vif.rready <= 1'b0; 
  endtask
  
  task err_wr();
    `uvm_info("DRV", "Error Write Transaction Started", UVM_NONE);
    vif.resetn <= 1'b1;  vif.awvalid <= 1'b1;  vif.awid <= tr.id;
    vif.awlen <= 7;      vif.awsize  <= 2;     vif.awaddr <= 128;  vif.awburst <= 0;
    vif.wvalid <= 1'b1;  vif.wid <= tr.id;     vif.wdata <= $urandom_range(0,10);
    vif.wstrb  <= 4'b1111; vif.wlast <= 0;
    vif.arvalid <= 1'b0; vif.rready <= 1'b0;  vif.bready <= 1'b0;
    @(posedge vif.clk);
    @(posedge vif.wready);
    @(posedge vif.clk);
    for(int i = 0; i < (vif.awlen); i++) begin
      vif.wdata <= $urandom_range(0,10);
      vif.wstrb <= 4'b1111;
      @(posedge vif.wready);
      @(posedge vif.clk);
    end
    vif.wlast <= 1'b1;  vif.bready <= 1'b1;
    vif.awvalid <= 1'b0;  vif.wvalid <= 1'b0;
    @(negedge vif.bvalid);
    vif.bready <= 1'b0;  vif.wlast <= 1'b0;
  endtask
        
  task err_rd();  
    `uvm_info("DRV", "Error Read Transaction Started", UVM_NONE);
    @(posedge vif.clk);
    vif.arvalid <= 1'b1;  vif.rready <= 1'b1;
    vif.arid <= tr.id;  vif.arlen <= 7;  vif.arsize <= 2;  vif.araddr <= 128;
    vif.arburst <= 0; 
    for(int i = 0; i < (vif.arlen + 1); i++) begin
      @(posedge vif.arready);
      @(posedge vif.clk);
    end
    @(negedge vif.rlast);
    vif.arvalid <= 1'b0;  vif.rready <= 1'b0; 
  endtask

  virtual task run_phase(uvm_phase phase);
    forever begin
      seq_item_port.get_next_item(tr);
      if(tr.op == rstdut)
        reset_dut();
      else if (tr.op == wrrdfixed) begin
        `uvm_info("DRV", $sformatf("Fixed Mode Write->Read WLEN:%0d WSIZE:%0d", tr.awlen+1, tr.awsize), UVM_MEDIUM);
        wrrd_fixed_wr();
        wrrd_fixed_rd();
      end
      else if (tr.op == wrrdincr) begin
        `uvm_info("DRV", $sformatf("INCR Mode Write->Read WLEN:%0d WSIZE:%0d", tr.awlen+1, tr.awsize), UVM_MEDIUM);
        wrrd_incr_wr();
        wrrd_incr_rd();
      end   
      else if (tr.op == wrrdwrap) begin
        `uvm_info("DRV", $sformatf("WRAP Mode Write->Read WLEN:%0d WSIZE:%0d", tr.awlen+1, tr.awsize), UVM_MEDIUM);
        wrrd_wrap_wr();
        wrrd_wrap_rd();
      end   
      else if (tr.op == wrrderrfix) begin
        `uvm_info("DRV", $sformatf("Error Transaction WLEN:%0d WSIZE:%0d", tr.awlen+1, tr.awsize), UVM_MEDIUM);
        err_wr();
        err_rd();
      end 
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
  virtual axi_if vif;
  
  function new(string inst = "mon", uvm_component parent = null);
    super.new(inst, parent);
  endfunction
  
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    tr   = transaction::type_id::create("tr");
    send = new("send", this);
    if(!uvm_config_db#(virtual axi_if)::get(this,"","vif",vif))
      `uvm_error("MON","Unable to access Interface");
  endfunction
  
  virtual task run_phase(uvm_phase phase);
    forever begin
      @(posedge vif.clk);
      
      if(!vif.resetn) begin
        tr.op          = rstdut;
        tr.awaddr      = 32'h0;
        tr.awlen       = 4'h0;
        tr.awburst     = 2'h0;
        tr.rdata_beats = new[0];
        tr.bresp       = 2'b00;
        tr.rresp       = 2'b00;
        `uvm_info("MON", "System Reset Detected", UVM_MEDIUM); 
        send.write(tr);
      end
      else begin
        wait(vif.awvalid == 1'b1);
        tr.awaddr  = vif.awaddr;
        tr.awlen   = vif.awlen;
        tr.awburst = vif.awburst;
        
        if(vif.awaddr < 128) begin
          case(vif.awburst)
            2'b00:   tr.op = wrrdfixed;
            2'b01:   tr.op = wrrdincr;
            2'b10:   tr.op = wrrdwrap;
            default: tr.op = wrrdfixed;
          endcase
          
          for(int i = 0; i < (vif.awlen + 1); i++) begin
            @(posedge vif.wready);
          end
          
          @(posedge vif.bvalid);
          tr.bresp = vif.bresp;
          
          wait(vif.arvalid == 1'b1);
          
          tr.rdata_beats = new[vif.arlen + 1];
          for(int i = 0; i < (vif.arlen + 1); i++) begin
            @(posedge vif.rvalid);
            tr.rdata_beats[i] = vif.rdata;
          end
          
          @(posedge vif.rlast);
          tr.rresp = vif.rresp;
          
          `uvm_info("MON", $sformatf("BURST op:%s addr:%0d len:%0d bresp:%0d rresp:%0d",
            tr.op.name(), tr.awaddr, tr.awlen, tr.bresp, tr.rresp), UVM_NONE);
          send.write(tr);
          $display("------------------------------");
        end
        else begin
          tr.op = wrrderrfix;
          
          for(int i = 0; i < (vif.awlen + 1); i++) begin
            @(negedge vif.wready);
          end
          
          @(posedge vif.bvalid);
          tr.bresp = vif.bresp;
          
          wait(vif.arvalid == 1'b1);
          
          tr.rdata_beats = new[vif.arlen + 1];
          for(int i = 0; i < (vif.arlen + 1); i++) begin
            @(posedge vif.arready);
            tr.rdata_beats[i] = 32'h0;
          end
          
          @(posedge vif.rlast);
          tr.rresp = vif.rresp;
          
          `uvm_info("MON", $sformatf("ERROR BURST addr:%0d bresp:%0d rresp:%0d",
            tr.awaddr, tr.bresp, tr.rresp), UVM_NONE);
          send.write(tr);
          $display("------------------------------");
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
  virtual axi_if vif;
  
  bit [31:0] ref_arr [128];
  
  function new(string inst = "ref_model", uvm_component parent = null);
    super.new(inst, parent);
  endfunction
  
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    tr       = transaction::type_id::create("tr");
    send_ref = new("send_ref", this);
    foreach(ref_arr[i]) ref_arr[i] = 32'h0;
    if(!uvm_config_db#(virtual axi_if)::get(this,"","vif",vif))
      `uvm_error("REF","Unable to access Interface");
  endfunction
  
  virtual task run_phase(uvm_phase phase);
    forever begin
      @(posedge vif.clk);
      
      if(!vif.resetn) begin
        tr.op          = rstdut;
        tr.awaddr      = 32'h0;
        tr.awlen       = 4'h0;
        tr.awburst     = 2'h0;
        tr.rdata_beats = new[0];
        tr.bresp       = 2'b00;
        tr.rresp       = 2'b00;
        send_ref.write(tr);
      end
      else begin
        wait(vif.awvalid == 1'b1);
        tr.awaddr  = vif.awaddr;
        tr.awlen   = vif.awlen;
        tr.awburst = vif.awburst;
        
        if(vif.awaddr < 128) begin
          case(vif.awburst)
            2'b00:   tr.op = wrrdfixed;
            2'b01:   tr.op = wrrdincr;
            2'b10:   tr.op = wrrdwrap;
            default: tr.op = wrrdfixed;
          endcase
          
          for(int i = 0; i < (vif.awlen + 1); i++) begin
            @(posedge vif.wready);
            ref_arr[vif.next_addrwr] = vif.wdata;
          end
          
          @(posedge vif.bvalid);
          tr.bresp = 2'b00;
          
          wait(vif.arvalid == 1'b1);
          
          tr.rdata_beats = new[vif.arlen + 1];
          for(int i = 0; i < (vif.arlen + 1); i++) begin
            @(posedge vif.rvalid);
            tr.rdata_beats[i] = ref_arr[vif.next_addrrd];
          end
          
          @(posedge vif.rlast);
          tr.rresp = 2'b00;
          
          `uvm_info("REF", $sformatf("BURST op:%s addr:%0d predicted bresp:%0d rresp:%0d",
            tr.op.name(), tr.awaddr, tr.bresp, tr.rresp), UVM_NONE);
          send_ref.write(tr);
        end
        else begin
          tr.op = wrrderrfix;
          
          for(int i = 0; i < (vif.awlen + 1); i++) begin
            @(negedge vif.wready);
          end
          
          @(posedge vif.bvalid);
          tr.bresp = 2'b11;
          
          wait(vif.arvalid == 1'b1);
          
          tr.rdata_beats = new[vif.arlen + 1];
          for(int i = 0; i < (vif.arlen + 1); i++) begin
            @(posedge vif.arready);
            tr.rdata_beats[i] = 32'h0;
          end
          
          @(posedge vif.rlast);
          tr.rresp = 2'b11;
          
          `uvm_info("REF", $sformatf("ERROR BURST addr:%0d predicted bresp:%0d rresp:%0d",
            tr.awaddr, tr.bresp, tr.rresp), UVM_NONE);
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
        `uvm_info("SCO", $sformatf("Test PASSED  op:%s addr:%0d len:%0d bresp:%0d/%0d rresp:%0d/%0d",
          tr.op.name(), tr.awaddr, tr.awlen, tr.bresp, trref.bresp, tr.rresp, trref.rresp), UVM_NONE)
      else
        `uvm_info("SCO", $sformatf("Test FAILED  op:%s addr:%0d len:%0d bresp:%0d/%0d rresp:%0d/%0d",
          tr.op.name(), tr.awaddr, tr.awlen, tr.bresp, trref.bresp, tr.rresp, trref.rresp), UVM_NONE)
      $display("----------------------------------------------------------------");
    end
  endtask
endclass

////////////////////////////////////////////////////////////////////////////////
// FUNCTIONAL COVERAGE
////////////////////////////////////////////////////////////////////////////////
class axi_coverage extends uvm_subscriber #(transaction);
  `uvm_component_utils(axi_coverage)
  
  transaction tr;
  
  covergroup axi_cg;
    option.per_instance = 1;
    option.name         = "axi_cov";
    
    op_cp: coverpoint tr.op {
      bins fixed    = {wrrdfixed};
      bins incr     = {wrrdincr};
      bins wrap     = {wrrdwrap};
      bins err_fix  = {wrrderrfix};
      ignore_bins ignore_rst = {rstdut};
    }
    
    burst_cp: coverpoint tr.awburst {
      bins fixed_b = {2'b00};
      bins incr_b  = {2'b01};
      bins wrap_b  = {2'b10};
      illegal_bins reserved = {2'b11};
    }
    
    addr_cp: coverpoint tr.awaddr {
      bins valid_zone = {[0:127]};
      bins error_zone = {[128:$]};
    }
    
    bresp_cp: coverpoint tr.bresp {
      bins okay   = {2'b00};
      bins decerr = {2'b11};
      ignore_bins unused = {2'b01, 2'b10};
    }
    
    rresp_cp: coverpoint tr.rresp {
      bins okay   = {2'b00};
      bins decerr = {2'b11};
      ignore_bins unused = {2'b01, 2'b10};
    }
    
    id_cp: coverpoint tr.id {
      bins low_id  = {[0:7]};
      bins high_id = {[8:15]};
    }
    
    op_x_bresp: cross op_cp, bresp_cp {
      ignore_bins ig1 = binsof(op_cp.fixed)   && binsof(bresp_cp.decerr);
      ignore_bins ig2 = binsof(op_cp.incr)    && binsof(bresp_cp.decerr);
      ignore_bins ig3 = binsof(op_cp.wrap)    && binsof(bresp_cp.decerr);
      ignore_bins ig4 = binsof(op_cp.err_fix) && binsof(bresp_cp.okay);
    }
    
    op_x_rresp: cross op_cp, rresp_cp {
      ignore_bins ig1 = binsof(op_cp.fixed)   && binsof(rresp_cp.decerr);
      ignore_bins ig2 = binsof(op_cp.incr)    && binsof(rresp_cp.decerr);
      ignore_bins ig3 = binsof(op_cp.wrap)    && binsof(rresp_cp.decerr);
      ignore_bins ig4 = binsof(op_cp.err_fix) && binsof(rresp_cp.okay);
    }
    
    addr_x_bresp: cross addr_cp, bresp_cp {
      ignore_bins ig1 = binsof(addr_cp.valid_zone) && binsof(bresp_cp.decerr);
      ignore_bins ig2 = binsof(addr_cp.error_zone) && binsof(bresp_cp.okay);
    }
    
  endgroup
  
  function new(string name, uvm_component parent);
    super.new(name, parent);
    axi_cg = new();
  endfunction
  
  function void write(transaction t);
    if (t.op == rstdut) return;
    tr = t;
    axi_cg.sample();
  endfunction
  
  function void report_phase(uvm_phase phase);
    `uvm_info("COV", $sformatf("AXI Functional Coverage = %0.2f%%",
      axi_cg.get_inst_coverage()), UVM_LOW)
  endfunction
endclass

////////////////////////////////////////////////////////////////////////////////
// AGENT
////////////////////////////////////////////////////////////////////////////////
class agent extends uvm_agent;
  `uvm_component_utils(agent)
  
  driver        d;
  uvm_sequencer#(transaction) seqr;
  mon           m;
  ref_model     ref_m;
  axi_coverage  cov;
  
  function new(string inst = "agent", uvm_component parent = null);
    super.new(inst, parent);
  endfunction
  
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    m     = mon::type_id::create("m", this); 
    ref_m = ref_model::type_id::create("ref_m", this);
    d     = driver::type_id::create("d", this);
    seqr  = uvm_sequencer#(transaction)::type_id::create("seqr", this);
    cov   = axi_coverage::type_id::create("cov", this);
  endfunction
  
  virtual function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    d.seq_item_port.connect(seqr.seq_item_export);
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
// TEST
////////////////////////////////////////////////////////////////////////////////
class test extends uvm_test;
  `uvm_component_utils(test)
  
  env e;
  rst_dut          rst_seq;
  valid_wrrd_fixed fixed_seq;
  valid_wrrd_incr  incr_seq;
  valid_wrrd_wrap  wrap_seq;
  err_wrrd_fix     err_seq;
  
  function new(string inst = "test", uvm_component c);
    super.new(inst, c);
  endfunction
  
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    e = env::type_id::create("env", this);
  endfunction
  
  virtual task run_phase(uvm_phase phase);
    phase.raise_objection(this);
    
    rst_seq   = rst_dut::type_id::create("rst_seq");
    fixed_seq = valid_wrrd_fixed::type_id::create("fixed_seq");
    incr_seq  = valid_wrrd_incr::type_id::create("incr_seq");
    wrap_seq  = valid_wrrd_wrap::type_id::create("wrap_seq");
    err_seq   = err_wrrd_fix::type_id::create("err_seq");
    
   rst_seq.start(e.a.seqr);
    fixed_seq.start(e.a.seqr);
    rst_seq.start(e.a.seqr);
    incr_seq.start(e.a.seqr);
    rst_seq.start(e.a.seqr);
    wrap_seq.start(e.a.seqr);
    rst_seq.start(e.a.seqr);
    err_seq.start(e.a.seqr);
    
    #20;
    phase.drop_objection(this);
  endtask
endclass

////////////////////////////////////////////////////////////////////////////////
// TB TOP
////////////////////////////////////////////////////////////////////////////////
module tb;

  axi_if vif();
  axi_slave dut (
    vif.clk, vif.resetn,
    vif.awvalid, vif.awready, vif.awid, vif.awlen, vif.awsize, vif.awaddr, vif.awburst,
    vif.wvalid, vif.wready, vif.wid, vif.wdata, vif.wstrb, vif.wlast,
    vif.bready, vif.bvalid, vif.bid, vif.bresp,
    vif.arready, vif.arid, vif.araddr, vif.arlen, vif.arsize, vif.arburst, vif.arvalid,
    vif.rid, vif.rdata, vif.rresp, vif.rlast, vif.rvalid, vif.rready
  );
 
  initial vif.clk <= 0;
  always #5 vif.clk <= ~vif.clk;
  
  initial begin
    uvm_config_db#(virtual axi_if)::set(null, "*", "vif", vif);
    run_test("test");
  end
  
  initial begin
    $dumpfile("dump.vcd");
    $dumpvars;   
  end
  
  assign vif.next_addrwr = dut.nextaddr;
  assign vif.next_addrrd = dut.rdnextaddr;
  
endmodule