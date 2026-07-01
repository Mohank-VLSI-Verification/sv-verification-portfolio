// =============================================================================
// Transaction: Data packet for SPI testbench
// =============================================================================
// Improvements: added display(), copy() already existed
// =============================================================================

class transaction;

  bit             newd;
  rand bit [11:0] din;
  bit [11:0]      dout;

  function transaction copy();
    copy      = new();
    copy.newd = this.newd;
    copy.din  = this.din;
    copy.dout = this.dout;
  endfunction

  function void display(input string tag);
    $display("[%0s] : newd:%0d din:%0d dout:%0d @ %0t",
             tag, newd, din, dout, $time);
  endfunction

endclass
