// =============================================================================
// D Flip-Flop with Synchronous Reset
// =============================================================================


interface dff_if;
  logic clk;
  logic rst;
  logic din;
  logic dout;

  modport DUT (input clk, rst, din, output dout);
  modport TB  (input dout, output clk, rst, din);
endinterface

// -----------------------------------------------------------------------------

module dff (dff_if.DUT vif);

  always_ff @(posedge vif.clk) begin
    if (vif.rst == 1'b1)
      vif.dout <= 1'b0;
    else
      vif.dout <= vif.din;
  end

endmodule
