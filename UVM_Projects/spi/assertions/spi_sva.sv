////////////////////////////////////////////////////////////////////////////////
// spi_i  —  interface with 5 SVA assertions
////////////////////////////////////////////////////////////////////////////////
interface spi_i;
  
  logic clk, rst, cs, miso;
  logic ready, mosi, op_done;
  
  // ==========================================================================
  // SVA-1 — cs (chip select) must be deasserted (high) while rst is asserted
  //         (master-side protocol invariant — no transactions during reset)
  // ==========================================================================
  property p_cs_high_during_rst;
    @(posedge clk)
      rst |-> cs;
  endproperty
  a_cs_high_during_rst: assert property(p_cs_high_during_rst)
    else $error("SVA-1: cs not high while rst is asserted");
  
  // ==========================================================================
  // SVA-2 — op_done is a single-cycle pulse
  //         (FSM transitions to idle on the next clock, clearing op_done)
  // ==========================================================================
  property p_op_done_pulse;
    @(posedge clk) disable iff (rst)
      op_done |=> !op_done;
  endproperty
  a_op_done_pulse: assert property(p_op_done_pulse)
    else $error("SVA-2: op_done held high for more than one cycle");
  
  // ==========================================================================
  // SVA-3 — cs falling edge (transaction start) eventually drives op_done
  //         (bounded liveness — write path ~18 cycles, read path ~19 cycles)
  // ==========================================================================
  property p_cs_falling_completion;
    @(posedge clk) disable iff (rst)
      $fell(cs) |-> ##[1:100] op_done;
  endproperty
  a_cs_falling_completion: assert property(p_cs_falling_completion)
    else $error("SVA-3: op_done did not assert within bounded time after cs fell");
  
  // ==========================================================================
  // SVA-4 — mosi must be valid (no X bits) while ready is asserted
  //         (mosi carries read data during the ready window)
  // ==========================================================================
  property p_mosi_valid_at_ready;
    @(posedge clk) disable iff (rst)
      ready |-> !$isunknown(mosi);
  endproperty
  a_mosi_valid_at_ready: assert property(p_mosi_valid_at_ready)
    else $error("SVA-4: mosi has X bits while ready is high");
  
  // ==========================================================================
  // SVA-5 — reset assertion clears ready on the next cycle
  //         (DUT explicitly clears ready in its rst branch)
  // ==========================================================================
  property p_rst_clears_ready;
    @(posedge clk)
      rst |=> !ready;
  endproperty
  a_rst_clears_ready: assert property(p_rst_clears_ready)
    else $error("SVA-5: ready did not clear on cycle after reset");
  
endinterface