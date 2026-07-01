// =============================================================================
// Transaction: Data packet for I2C testbench
// =============================================================================
// Supports read (op=1) and write (op=0) with constrained addr and din
// =============================================================================

class transaction;

  bit           newd;
  rand bit      op;          // 0=write, 1=read
  rand bit [7:0] din;
  rand bit [6:0] addr;
  bit [7:0]     dout;
  bit           done;
  bit           busy;
  bit           ack_err;

  constraint addr_c  { addr > 1; addr < 5; din > 1; din < 10; }
  constraint rd_wr_c { op dist {1 :/ 50, 0 :/ 50}; }

  function transaction copy();
    copy         = new();
    copy.newd    = this.newd;
    copy.op      = this.op;
    copy.din     = this.din;
    copy.addr    = this.addr;
    copy.dout    = this.dout;
    copy.done    = this.done;
    copy.busy    = this.busy;
    copy.ack_err = this.ack_err;
  endfunction

  function void display(input string tag);
    $display("[%0s] : op:%0s addr:%0d din:%0d dout:%0d done:%0d ack_err:%0d @ %0t",
             tag, (op ? "RD" : "WR"), addr, din, dout, done, ack_err, $time);
  endfunction

endclass
