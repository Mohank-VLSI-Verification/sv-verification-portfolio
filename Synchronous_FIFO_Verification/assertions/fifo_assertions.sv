// =============================================================================
// FIFO Assertions
// =============================================================================


module fifo_assertions_extra (
  input logic       clk,
  input logic       rst,
  input logic       wr,
  input logic       rd,
  input logic       full,
  input logic       empty,
  input logic [7:0] din,
  input logic [7:0] dout,
  input logic [4:0] cnt,     
  input logic [3:0] wptr,    
  input logic [3:0] rptr     
);

  // A1 — Reset state
property p_reset_state;
  @(posedge clk) $rose(rst) |=> (empty && !full && cnt == 0);
endproperty
assert property (p_reset_state)
  else $error("[A1] Reset did not clear FIFO state @ %0t", $time);

// A2 — Overflow protection
property p_no_overflow;
  @(posedge clk) disable iff (rst)
    (full && wr && !rd) |=> $stable(wptr) && $stable(cnt);
endproperty
assert property (p_no_overflow)
  else $error("[A2] Write accepted when full @ %0t", $time);

// A3 — Underflow protection
property p_no_underflow;
  @(posedge clk) disable iff (rst)
    (empty && rd && !wr) |=> $stable(rptr) && $stable(cnt) && $stable(dout);
endproperty
assert property (p_no_underflow)
  else $error("[A3] Read accepted when empty @ %0t", $time);

// A4 — Simultaneous R+W
property p_simultaneous_rw;
  @(posedge clk) disable iff (rst)
    (wr && !full && rd && !empty) |=> 
      $stable(cnt) && (wptr == $past(wptr) + 1) && (rptr == $past(rptr) + 1);
endproperty
assert property (p_simultaneous_rw)
  else $error("[A4] Simultaneous R/W mishandled @ %0t", $time);

// A5 — Flag transitions
property p_empty_clears;
  @(posedge clk) disable iff (rst)
    (empty && wr && !full) |=> !empty;
endproperty
assert property (p_empty_clears)
  else $error("[A5a] Empty did not clear after write @ %0t", $time);

property p_full_clears;
  @(posedge clk) disable iff (rst)
    (full && rd && !wr) |=> !full;
endproperty
assert property (p_full_clears)
  else $error("[A5b] Full did not clear after read @ %0t", $time);

// A6 — Flag consistency
property p_full_empty_mutex;
  @(posedge clk) disable iff (rst) !(full && empty);
endproperty
assert property (p_full_empty_mutex)
  else $error("[A6a] FIFO is both full and empty @ %0t", $time);

property p_flag_cnt_consistency;
  @(posedge clk) disable iff (rst)
    (empty == (cnt == 0)) && (full == (cnt == 16));
endproperty
assert property (p_flag_cnt_consistency)
  else $error("[A6b] Flag/count mismatch @ %0t", $time);