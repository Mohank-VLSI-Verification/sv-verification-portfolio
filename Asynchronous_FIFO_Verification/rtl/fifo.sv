// =============================================================================
// FIFO — 16-deep, 8-bit wide, synchronous reset
// =============================================================================
// Improvements over original:
//   - always_ff for sequential intent
//   - Handles simultaneous read+write
//   - modport added to interface
//   - Reset handles initialization (not declaration)
// =============================================================================

interface fifo_if;

  logic        clock;
  logic        rst;
  logic        rd, wr;
  logic        full, empty;
  logic [7:0]  data_in;
  logic [7:0]  data_out;

  modport DUT (input clock, rst, rd, wr, data_in, output data_out, full, empty);
  modport TB  (input data_out, full, empty, output clock, rst, rd, wr, data_in);

endinterface

// -----------------------------------------------------------------------------

module FIFO (
  input  logic        clk,
  input  logic        rst,
  input  logic        wr,
  input  logic        rd,
  input  logic [7:0]  din,
  output logic [7:0]  dout,
  output logic        empty,
  output logic        full
);

  logic [3:0] wptr, rptr;
  logic [4:0] cnt;
  logic [7:0] mem [15:0];

  always_ff @(posedge clk) begin
    if (rst) begin
      wptr <= 4'b0;
      rptr <= 4'b0;
      cnt  <= 5'b0;
    end
    else begin
      // Handle simultaneous read + write
      case ({wr && !full, rd && !empty})
        2'b10: begin   // write only
          mem[wptr] <= din;
          wptr      <= wptr + 1;
          cnt       <= cnt + 1;
        end
        2'b01: begin   // read only
          dout <= mem[rptr];
          rptr <= rptr + 1;
          cnt  <= cnt - 1;
        end
        2'b11: begin   // simultaneous read + write
          mem[wptr] <= din;
          wptr      <= wptr + 1;
          dout      <= mem[rptr];
          rptr      <= rptr + 1;
          // cnt stays the same (one in, one out)
        end
        default: ;     // no operation
      endcase
    end
  end

  assign empty = (cnt == 0);
  assign full  = (cnt == 16);

endmodule
