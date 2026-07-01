////////////////////////////////////////////////////////////////////////////////
// apb_if  —  interface with 5 SVA assertions
////////////////////////////////////////////////////////////////////////////////
interface apb_if;
  
  logic        presetn, pclk;
  logic        psel, penable, pwrite;
  logic [31:0] paddr, pwdata, prdata;
  logic        pready, pslverr;
  
  // ==========================================================================
  // SVA-1 — PENABLE may only be asserted when PSEL is also asserted
  //         (APB protocol invariant — PENABLE without PSEL is illegal)
  // ==========================================================================
  property p_penable_requires_psel;
    @(posedge pclk) disable iff (!presetn)
      penable |-> psel;
  endproperty
  a_penable_requires_psel: assert property(p_penable_requires_psel)
    else $error("SVA-1: penable asserted while psel is low");
  
  // ==========================================================================
  // SVA-2 — Wait-state stability: while access phase awaits PREADY, both
  //         PSEL and PENABLE must remain asserted (no early termination)
  // ==========================================================================
  property p_wait_state_handshake_stable;
    @(posedge pclk) disable iff (!presetn)
      (psel && penable && !pready) |=> (psel && penable);
  endproperty
  a_wait_state_handshake_stable: assert property(p_wait_state_handshake_stable)
    else $error("SVA-2: psel or penable dropped before pready in access phase");
  
  // ==========================================================================
  // SVA-3 — PREADY liveness: after PENABLE rises, PREADY must assert within
  //         a bounded number of cycles (DUT responds within ~2-3 cycles)
  // ==========================================================================
  property p_pready_liveness;
    @(posedge pclk) disable iff (!presetn)
      $rose(penable) |-> ##[1:20] pready;
  endproperty
  a_pready_liveness: assert property(p_pready_liveness)
    else $error("SVA-3: pready did not assert within 20 cycles of penable rising");
  
  // ==========================================================================
  // SVA-4 — PADDR and PWDATA must remain stable during wait-states
  //         (slave still consuming — master cannot mutate inputs mid-transfer)
  // ==========================================================================
  property p_addr_data_stable_in_wait;
    @(posedge pclk) disable iff (!presetn)
      (psel && penable && !pready) |=> $stable(paddr) && $stable(pwdata);
  endproperty
  a_addr_data_stable_in_wait: assert property(p_addr_data_stable_in_wait)
    else $error("SVA-4: paddr or pwdata changed during wait-state");
  
  // ==========================================================================
  // SVA-5 — PSLVERR is only valid when PREADY is asserted
  //         (error status is a property of the transfer cycle, not idle/setup)
  // ==========================================================================
  property p_pslverr_qualified_by_pready;
    @(posedge pclk) disable iff (!presetn)
      pslverr |-> pready;
  endproperty
  a_pslverr_qualified_by_pready: assert property(p_pslverr_qualified_by_pready)
    else $error("SVA-5: pslverr asserted while pready is low");
  
endinterface