// =============================================================================
// SPI Master — generates sclk, sends 12-bit data serially (LSB first)
// =============================================================================
// Improvements over original:
//   - always_ff for sequential intent
//   - Removed unused FSM states (enable, comp)
//   - Fixed 8'h00 → 12'h000 width mismatch
//   - Reset handles initialization (not declaration)
// =============================================================================

module spi_master (
  input  logic        clk,
  input  logic        newd,
  input  logic        rst,
  input  logic [11:0] din,
  output logic        sclk,
  output logic        cs,
  output logic        mosi
);

  typedef enum logic [1:0] {IDLE = 2'b00, SEND = 2'b01} state_t;
  state_t state;

  int countc;
  int count;
  logic [11:0] temp;

  // sclk generation: clk divided by 22 (count to 10, toggle)
  always_ff @(posedge clk) begin
    if (rst) begin
      countc <= 0;
      sclk   <= 1'b0;
    end else begin
      if (countc < 10)
        countc <= countc + 1;
      else begin
        countc <= 0;
        sclk   <= ~sclk;
      end
    end
  end

  // FSM: send 12 bits on mosi, LSB first
  always_ff @(posedge sclk) begin
    if (rst) begin
      cs    <= 1'b1;
      mosi  <= 1'b0;
      state <= IDLE;
      temp  <= 12'h000;
      count <= 0;
    end else begin
      case (state)
        IDLE: begin
          if (newd) begin
            state <= SEND;
            temp  <= din;
            cs    <= 1'b0;
          end else begin
            state <= IDLE;
            temp  <= 12'h000;
          end
        end

        SEND: begin
          if (count <= 11) begin
            mosi  <= temp[count];
            count <= count + 1;
          end else begin
            count <= 0;
            state <= IDLE;
            cs    <= 1'b1;
            mosi  <= 1'b0;
          end
        end

        default: state <= IDLE;
      endcase
    end
  end

endmodule

// =============================================================================
// SPI Slave — detects cs low, shifts in 12 bits from mosi, asserts done
// =============================================================================

module spi_slave (
  input  logic        sclk,
  input  logic        cs,
  input  logic        mosi,
  output logic [11:0] dout,
  output logic        done
);

  typedef enum logic {DETECT_START = 1'b0, READ_DATA = 1'b1} state_t;
  state_t state;

  logic [11:0] temp;
  int count;

  always_ff @(posedge sclk) begin
    case (state)
      DETECT_START: begin
        done <= 1'b0;
        if (!cs)
          state <= READ_DATA;
        else
          state <= DETECT_START;
      end

      READ_DATA: begin
        if (count <= 11) begin
          count <= count + 1;
          temp  <= {mosi, temp[11:1]};
        end else begin
          count <= 0;
          done  <= 1'b1;
          state <= DETECT_START;
        end
      end
    endcase
  end

  assign dout = temp;

endmodule

// =============================================================================
// Top — connects SPI master and slave
// =============================================================================

module top (
  input  logic        clk,
  input  logic        rst,
  input  logic        newd,
  input  logic [11:0] din,
  output logic [11:0] dout,
  output logic        done
);

  wire sclk, cs, mosi;

  spi_master m1 (clk, newd, rst, din, sclk, cs, mosi);
  spi_slave  s1 (sclk, cs, mosi, dout, done);

endmodule

// =============================================================================
// Interface
// =============================================================================

interface spi_if;

  logic        clk;
  logic        rst;
  logic        newd;
  logic [11:0] din;
  logic [11:0] dout;
  logic        done;
  logic        sclk;

  modport DUT (input clk, rst, newd, din, output dout, done);
  modport TB  (input dout, done, sclk, output clk, rst, newd, din);

endinterface
