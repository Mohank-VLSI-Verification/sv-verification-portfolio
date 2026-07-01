// =============================================================================
// Transaction: Data packet for UART testbench
// =============================================================================
// Supports both TX (write) and RX (read) operations
// randc on oper cycles through write/read before repeating
// =============================================================================

class transaction;

  typedef enum bit {WRITE = 1'b0, READ = 1'b1} oper_type;

  randc oper_type   oper;
  rand  bit [7:0]   dintx;

  bit       rx;
  bit       newd;
  bit       tx;
  bit [7:0] doutrx;
  bit       donetx;
  bit       donerx;

  function transaction copy();
    copy        = new();
    copy.oper   = this.oper;
    copy.rx     = this.rx;
    copy.dintx  = this.dintx;
    copy.newd   = this.newd;
    copy.tx     = this.tx;
    copy.doutrx = this.doutrx;
    copy.donetx = this.donetx;
    copy.donerx = this.donerx;
  endfunction

  function void display(input string tag);
    $display("[%0s] : oper:%0s dintx:%0d doutrx:%0d donetx:%0d donerx:%0d @ %0t",
             tag, oper.name(), dintx, doutrx, donetx, donerx, $time);
  endfunction

endclass
