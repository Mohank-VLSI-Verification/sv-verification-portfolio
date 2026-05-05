// =============================================================================
// UART Transmitter — generates baud clock, sends start + 8 data bits (LSB first)
// =============================================================================
// Improvements: always_ff, reset handles init, cleaned up FSM
// =============================================================================

module uarttx
#(
  parameter clk_freq  = 1000000,
  parameter baud_rate = 9600
)
(
  input  logic       clk,
  input  logic       rst,
  input  logic       newd,
  input  logic [7:0] tx_data,
  output logic       tx,
  output logic       donetx
);

  localparam clkcount = (clk_freq / baud_rate);

  integer count;
  integer counts;
  logic   uclk;
  logic [7:0] din;

  typedef enum logic [1:0] {IDLE = 2'b00, TRANSFER = 2'b01, DONE = 2'b10} state_t;
  state_t state;

  // Baud clock generation
  always_ff @(posedge clk) begin
    if (rst) begin
      count <= 0;
      uclk  <= 1'b0;
    end else begin
      if (count < clkcount / 2)
        count <= count + 1;
      else begin
        count <= 0;
        uclk  <= ~uclk;
      end
    end
  end

  // TX FSM
  always_ff @(posedge uclk) begin
    if (rst) begin
      state  <= IDLE;
      tx     <= 1'b1;
      donetx <= 1'b0;
      counts <= 0;
      din    <= 8'b0;
    end else begin
      case (state)
        IDLE: begin
          counts <= 0;
          tx     <= 1'b1;
          donetx <= 1'b0;
          if (newd) begin
            state <= TRANSFER;
            din   <= tx_data;
            tx    <= 1'b0;      // start bit
          end
        end

        TRANSFER: begin
          if (counts <= 7) begin
            tx     <= din[counts];
            counts <= counts + 1;
          end else begin
            counts <= 0;
            tx     <= 1'b1;     // stop bit / idle
            state  <= IDLE;
            donetx <= 1'b1;
          end
        end

        default: state <= IDLE;
      endcase
    end
  end

endmodule

// =============================================================================
// UART Receiver — detects start bit (rx=0), shifts in 8 data bits
// =============================================================================

module uartrx
#(
  parameter clk_freq  = 1000000,
  parameter baud_rate = 9600
)
(
  input  logic       clk,
  input  logic       rst,
  input  logic       rx,
  output logic       donerx,
  output logic [7:0] rxdata
);

  localparam clkcount = (clk_freq / baud_rate);

  integer count;
  integer counts;
  logic   uclk;

  typedef enum logic {IDLE = 1'b0, START = 1'b1} state_t;
  state_t state;

  // Baud clock generation
  always_ff @(posedge clk) begin
    if (rst) begin
      count <= 0;
      uclk  <= 1'b0;
    end else begin
      if (count < clkcount / 2)
        count <= count + 1;
      else begin
        count <= 0;
        uclk  <= ~uclk;
      end
    end
  end

  // RX FSM
  always_ff @(posedge uclk) begin
    if (rst) begin
      rxdata <= 8'h00;
      counts <= 0;
      donerx <= 1'b0;
      state  <= IDLE;
    end else begin
      case (state)
        IDLE: begin
          rxdata <= 8'h00;
          counts <= 0;
          donerx <= 1'b0;
          if (rx == 1'b0)       // start bit detected
            state <= START;
        end

        START: begin
          if (counts <= 7) begin
            counts <= counts + 1;
            rxdata <= {rx, rxdata[7:1]};
          end else begin
            counts <= 0;
            donerx <= 1'b1;
            state  <= IDLE;
          end
        end

        default: state <= IDLE;
      endcase
    end
  end

endmodule

// =============================================================================
// UART Top — wraps TX and RX with parameterized baud rate
// =============================================================================

module uart_top
#(
  parameter clk_freq  = 1000000,
  parameter baud_rate = 9600
)
(
  input  logic       clk,
  input  logic       rst,
  input  logic       rx,
  input  logic [7:0] dintx,
  input  logic       newd,
  output logic       tx,
  output logic [7:0] doutrx,
  output logic       donetx,
  output logic       donerx
);

  uarttx #(clk_freq, baud_rate) utx (clk, rst, newd, dintx, tx, donetx);
  uartrx #(clk_freq, baud_rate) rtx (clk, rst, rx, donerx, doutrx);

endmodule

// =============================================================================
// Interface
// =============================================================================

interface uart_if;

  logic       clk;
  logic       uclktx;
  logic       uclkrx;
  logic       rst;
  logic       rx;
  logic [7:0] dintx;
  logic       newd;
  logic       tx;
  logic [7:0] doutrx;
  logic       donetx;
  logic       donerx;

  modport DUT (input clk, rst, rx, dintx, newd, output tx, doutrx, donetx, donerx);
  modport TB  (input tx, doutrx, donetx, donerx, uclktx, uclkrx, output clk, rst, rx, dintx, newd);

endinterface
