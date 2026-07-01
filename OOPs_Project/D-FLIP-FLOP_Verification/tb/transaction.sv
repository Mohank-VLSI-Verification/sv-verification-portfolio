// =============================================================================
// Transaction: Data packet flowing through the testbench
// =============================================================================

class transaction;

  rand bit din;
  bit dout;

  // Deep copy — prevents shared-reference bugs when sending to multiple mailboxes
  function transaction copy();
    copy = new();
    copy.din = this.din;
    copy.dout = this.dout;
  endfunction

  function void display(input string tag);
    $display("[%0s] : DIN : %0b  DOUT : %0b  @ time %0t", tag, din, dout, $time);
  endfunction

endclass
