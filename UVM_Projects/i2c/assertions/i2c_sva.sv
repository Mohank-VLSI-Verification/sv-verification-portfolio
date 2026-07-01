////////////////////////////////////////////////////////////////////////////////
// i2c_i  —  interface with 4 SVA assertions
//   SVA-5 (addr_bound) removed: it was a stimulus tautology, not a DUT property
////////////////////////////////////////////////////////////////////////////////
interface i2c_i;

  logic       clk, rst, wr;
  logic [6:0] addr;
  logic [7:0] din;
  logic [7:0] datard;
  logic       done;

  // ==========================================================================
  // SVA-1 — done is a single-cycle pulse
  //         (FSM transitions complete -> idle, idle clears done next cycle)
  // ==========================================================================
  property p_done_pulse;
    @(posedge clk) disable iff (rst)
      done |=> !done;
  endproperty
  a_done_pulse: assert property(p_done_pulse)
    else $error("SVA-1: done held high for more than one cycle");

  // ==========================================================================
  // SVA-2 — datard must be valid (no X bits) when done is high on a read
  //         (read data integrity at handshake completion)
  // ==========================================================================
  property p_datard_valid_on_read;
    @(posedge clk) disable iff (rst)
      (done && !wr) |-> !$isunknown(datard);
  endproperty
  a_datard_valid_on_read: assert property(p_datard_valid_on_read)
    else $error("SVA-2: datard has X bits while done is high on a read");

  // ==========================================================================
  // SVA-3 — FSM forward progress: while done is low, it must rise within bound
  //         (DUT cycles transactions continuously; one full I2C op ~25 cycles)
  // ==========================================================================
  property p_done_liveness;
    @(posedge clk) disable iff (rst)
      !done |-> ##[1:200] done;
  endproperty
  a_done_liveness: assert property(p_done_liveness)
    else $error("SVA-3: done did not assert within 200 cycles (FSM stuck)");

  // ==========================================================================
  // SVA-4 — addr and din are stable at the moment done asserts during a write
  //         (driver must not change inputs until transaction completes)
  // ==========================================================================
  property p_write_inputs_stable;
    @(posedge clk) disable iff (rst)
      (done && wr) |-> $stable(addr) && $stable(din);
  endproperty
  a_write_inputs_stable: assert property(p_write_inputs_stable)
    else $error("SVA-4: addr or din changed at done — write input not stable");

endinterface