////////////////////////////////////////////////////////////////////////////////
// uart_if  —  interface with 5 SVA assertions
////////////////////////////////////////////////////////////////////////////////
interface uart_if;
  
  logic         clk, rst;
  logic         tx_start, rx_start;
  logic [7:0]   tx_data;
  logic [16:0]  baud;
  logic [3:0]   length;
  logic         parity_type, parity_en;
  logic         stop2;
  logic         tx_done, rx_done, tx_err, rx_err;
  logic [7:0]   rx_out;
  
  // ==========================================================================
  // SVA-1 — rx_out must have no X bits when rx_done asserts
  // ==========================================================================
  property p_rx_out_valid;
    @(posedge clk) disable iff (rst)
      rx_done |-> !$isunknown(rx_out);
  endproperty
  a_rx_out_valid: assert property(p_rx_out_valid)
    else $error("SVA-1: rx_out has X bits while rx_done is high");
  
  // ==========================================================================
  // SVA-2 — tx_done and tx_err are mutually exclusive
  // ==========================================================================
  property p_tx_done_err_mutex;
    @(posedge clk) disable iff (rst)
      !(tx_done && tx_err);
  endproperty
  a_tx_done_err_mutex: assert property(p_tx_done_err_mutex)
    else $error("SVA-2: tx_done and tx_err asserted simultaneously");
  
  // ==========================================================================
  // SVA-3 — rx_done and rx_err are mutually exclusive
  // ==========================================================================
  property p_rx_done_err_mutex;
    @(posedge clk) disable iff (rst)
      !(rx_done && rx_err);
  endproperty
  a_rx_done_err_mutex: assert property(p_rx_done_err_mutex)
    else $error("SVA-3: rx_done and rx_err asserted simultaneously");
  
  // ==========================================================================
  // SVA-4 — reset assertion clears both done signals within bounded cycles
  // ==========================================================================
  property p_rst_clears_done;
    @(posedge clk)
      $rose(rst) |-> ##[1:20000] (!tx_done && !rx_done);
  endproperty
  a_rst_clears_done: assert property(p_rst_clears_done)
    else $error("SVA-4: done signals did not clear within bound after reset");
  
  // ==========================================================================
  // SVA-5 — tx_start eventually drives tx_done (transmit liveness)
  // ==========================================================================
  property p_tx_start_completion;
    @(posedge clk) disable iff (rst)
      $rose(tx_start) |-> ##[1:150000] tx_done;
  endproperty
  a_tx_start_completion: assert property(p_tx_start_completion)
    else $error("SVA-5: tx_done did not assert within bounded time after tx_start");
  
endinterface