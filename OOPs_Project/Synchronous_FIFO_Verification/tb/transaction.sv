// =============================================================================
// Transaction: Data packet for FIFO testbench
// =============================================================================
// Improvements over original:
//   - Added copy() to prevent shared-reference bugs
//   - Added display() for debug visibility
//   - data_in is now randomized (driver was ignoring it before)
// =============================================================================

class transaction;

  rand bit        oper;         // 1 = write, 0 = read
  rand bit [7:0]  data_in;     // randomized write data
  bit             rd, wr;
  bit             full, empty;
  bit [7:0]       data_out;

  constraint oper_ctrl {
    oper dist {1 :/ 50, 0 :/ 50};
  }

  function transaction copy();
    copy          = new();
    copy.oper     = this.oper;
    copy.data_in  = this.data_in;
    copy.rd       = this.rd;
    copy.wr       = this.wr;
    copy.full     = this.full;
    copy.empty    = this.empty;
    copy.data_out = this.data_out;
  endfunction

  function void display(input string tag);
    $display("[%0s] : oper:%0d wr:%0d rd:%0d din:%0d dout:%0d full:%0d empty:%0d @ %0t",
             tag, oper, wr, rd, data_in, data_out, full, empty, $time);
  endfunction

endclass
