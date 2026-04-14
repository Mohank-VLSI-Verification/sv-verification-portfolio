// =============================================================================
// I2C Master — generates SCL, handles start/stop/ACK, reads and writes via SDA
// =============================================================================
// Improvements: always_ff, reset handles init, cleaned state names
// =============================================================================

module i2c_master (
  input  logic        clk, rst, newd,
  input  logic [6:0]  addr,
  input  logic        op,           // 0=write, 1=read
  inout  wire         sda,
  output wire         scl,
  input  logic [7:0]  din,
  output logic [7:0]  dout,
  output logic        busy, ack_err, done
);

  logic scl_t;
  logic sda_t;
  logic sda_en;

  parameter sys_freq  = 40000000;
  parameter i2c_freq  = 100000;
  parameter clk_count4 = (sys_freq / i2c_freq);
  parameter clk_count1 = clk_count4 / 4;

  integer count1;
  logic [1:0] pulse;

  // 4x clock pulse generator
  always_ff @(posedge clk) begin
    if (rst) begin
      pulse  <= 0;
      count1 <= 0;
    end else if (busy == 1'b0) begin
      pulse  <= 0;
      count1 <= 0;
    end else if (count1 == clk_count1 - 1) begin
      pulse  <= 1;
      count1 <= count1 + 1;
    end else if (count1 == clk_count1*2 - 1) begin
      pulse  <= 2;
      count1 <= count1 + 1;
    end else if (count1 == clk_count1*3 - 1) begin
      pulse  <= 3;
      count1 <= count1 + 1;
    end else if (count1 == clk_count1*4 - 1) begin
      pulse  <= 0;
      count1 <= 0;
    end else begin
      count1 <= count1 + 1;
    end
  end

  logic [3:0] bitcount;
  logic [7:0] data_addr, data_tx;
  logic       r_ack;
  logic [7:0] rx_data;

  typedef enum logic [3:0] {
    IDLE       = 0, START     = 1, WRITE_ADDR = 2, ACK_1      = 3,
    WRITE_DATA = 4, READ_DATA = 5, STOP       = 6, ACK_2      = 7,
    MASTER_ACK = 8
  } state_t;
  state_t state;

  // Main FSM
  always_ff @(posedge clk) begin
    if (rst) begin
      bitcount  <= 0;
      data_addr <= 0;
      data_tx   <= 0;
      scl_t     <= 1;
      sda_t     <= 1;
      state     <= IDLE;
      busy      <= 1'b0;
      ack_err   <= 1'b0;
      done      <= 1'b0;
      sda_en    <= 1'b0;
      r_ack     <= 1'b0;
      rx_data   <= 8'b0;
    end else begin
      case (state)
        IDLE: begin
          done <= 1'b0;
          if (newd) begin
            data_addr <= {addr, op};
            data_tx   <= din;
            busy      <= 1'b1;
            state     <= START;
            ack_err   <= 1'b0;
          end else begin
            data_addr <= 0;
            data_tx   <= 0;
            busy      <= 1'b0;
            ack_err   <= 1'b0;
          end
        end

        START: begin
          sda_en <= 1'b1;
          case (pulse)
            0: begin scl_t <= 1'b1; sda_t <= 1'b1; end
            1: begin scl_t <= 1'b1; sda_t <= 1'b1; end
            2: begin scl_t <= 1'b1; sda_t <= 1'b0; end
            3: begin scl_t <= 1'b1; sda_t <= 1'b0; end
          endcase
          if (count1 == clk_count1*4 - 1) begin
            state <= WRITE_ADDR;
            scl_t <= 1'b0;
          end
        end

        WRITE_ADDR: begin
          sda_en <= 1'b1;
          if (bitcount <= 7) begin
            case (pulse)
              0: begin scl_t <= 1'b0; sda_t <= 1'b0; end
              1: begin scl_t <= 1'b0; sda_t <= data_addr[7 - bitcount]; end
              2: begin scl_t <= 1'b1; end
              3: begin scl_t <= 1'b1; end
            endcase
            if (count1 == clk_count1*4 - 1) begin
              scl_t    <= 1'b0;
              bitcount <= bitcount + 1;
            end
          end else begin
            state    <= ACK_1;
            bitcount <= 0;
            sda_en   <= 1'b0;
          end
        end

        ACK_1: begin
          sda_en <= 1'b0;
          case (pulse)
            0: begin scl_t <= 1'b0; sda_t <= 1'b0; end
            1: begin scl_t <= 1'b0; sda_t <= 1'b0; end
            2: begin scl_t <= 1'b1; sda_t <= 1'b0; r_ack <= sda; end
            3: begin scl_t <= 1'b1; end
          endcase
          if (count1 == clk_count1*4 - 1) begin
            if (r_ack == 1'b0 && data_addr[0] == 1'b0) begin
              state    <= WRITE_DATA;
              sda_t    <= 1'b0;
              sda_en   <= 1'b1;
              bitcount <= 0;
            end else if (r_ack == 1'b0 && data_addr[0] == 1'b1) begin
              state    <= READ_DATA;
              sda_t    <= 1'b1;
              sda_en   <= 1'b0;
              bitcount <= 0;
            end else begin
              state   <= STOP;
              sda_en  <= 1'b1;
              ack_err <= 1'b1;
            end
          end
        end

        WRITE_DATA: begin
          if (bitcount <= 7) begin
            case (pulse)
              0: begin scl_t <= 1'b0; end
              1: begin scl_t <= 1'b0; sda_en <= 1'b1; sda_t <= data_tx[7 - bitcount]; end
              2: begin scl_t <= 1'b1; end
              3: begin scl_t <= 1'b1; end
            endcase
            if (count1 == clk_count1*4 - 1) begin
              scl_t    <= 1'b0;
              bitcount <= bitcount + 1;
            end
          end else begin
            state    <= ACK_2;
            bitcount <= 0;
            sda_en   <= 1'b0;
          end
        end

        READ_DATA: begin
          sda_en <= 1'b0;
          if (bitcount <= 7) begin
            case (pulse)
              0: begin scl_t <= 1'b0; sda_t <= 1'b0; end
              1: begin scl_t <= 1'b0; sda_t <= 1'b0; end
              2: begin scl_t <= 1'b1; rx_data <= (count1 == 200) ? {rx_data[6:0], sda} : rx_data; end
              3: begin scl_t <= 1'b1; end
            endcase
            if (count1 == clk_count1*4 - 1) begin
              scl_t    <= 1'b0;
              bitcount <= bitcount + 1;
            end
          end else begin
            state    <= MASTER_ACK;
            bitcount <= 0;
            sda_en   <= 1'b1;
          end
        end

        MASTER_ACK: begin
          sda_en <= 1'b1;
          case (pulse)
            0: begin scl_t <= 1'b0; sda_t <= 1'b1; end
            1: begin scl_t <= 1'b0; sda_t <= 1'b1; end
            2: begin scl_t <= 1'b1; sda_t <= 1'b1; end
            3: begin scl_t <= 1'b1; sda_t <= 1'b1; end
          endcase
          if (count1 == clk_count1*4 - 1) begin
            sda_t  <= 1'b0;
            state  <= STOP;
            sda_en <= 1'b1;
          end
        end

        ACK_2: begin
          sda_en <= 1'b0;
          case (pulse)
            0: begin scl_t <= 1'b0; sda_t <= 1'b0; end
            1: begin scl_t <= 1'b0; sda_t <= 1'b0; end
            2: begin scl_t <= 1'b1; sda_t <= 1'b0; r_ack <= sda; end
            3: begin scl_t <= 1'b1; end
          endcase
          if (count1 == clk_count1*4 - 1) begin
            sda_t  <= 1'b0;
            sda_en <= 1'b1;
            state  <= STOP;
            ack_err <= (r_ack != 1'b0);
          end
        end

        STOP: begin
          sda_en <= 1'b1;
          case (pulse)
            0: begin scl_t <= 1'b1; sda_t <= 1'b0; end
            1: begin scl_t <= 1'b1; sda_t <= 1'b0; end
            2: begin scl_t <= 1'b1; sda_t <= 1'b1; end
            3: begin scl_t <= 1'b1; sda_t <= 1'b1; end
          endcase
          if (count1 == clk_count1*4 - 1) begin
            state  <= IDLE;
            scl_t  <= 1'b0;
            busy   <= 1'b0;
            sda_en <= 1'b1;
            done   <= 1'b1;
          end
        end

        default: state <= IDLE;
      endcase
    end
  end

  assign sda  = (sda_en) ? ((sda_t == 0) ? 1'b0 : 1'bz) : 1'bz;
  assign scl  = scl_t;
  assign dout = rx_data;

endmodule

// =============================================================================
// I2C Slave — responds to master, has 128-byte internal memory
// =============================================================================

module i2c_slave (
  input  wire         scl,
  input  logic        clk, rst,
  inout  wire         sda,
  output logic        ack_err, done
);

  typedef enum logic [3:0] {
    IDLE = 0, READ_ADDR = 1, SEND_ACK1 = 2, SEND_DATA = 3,
    MASTER_ACK = 4, READ_DATA = 5, SEND_ACK2 = 6,
    WAIT_P = 7, DETECT_STOP = 8
  } state_t;
  state_t state;

  logic [7:0] mem [128];
  logic [7:0] r_addr;
  logic [6:0] addr;
  logic       r_mem, w_mem;
  logic [7:0] dout, din;
  logic       sda_t, sda_en;
  logic [3:0] bitcnt;
  logic       busy;
  logic       r_ack;

  parameter sys_freq   = 40000000;
  parameter i2c_freq   = 100000;
  parameter clk_count4 = (sys_freq / i2c_freq);
  parameter clk_count1 = clk_count4 / 4;

  integer count1;
  logic [1:0] pulse;

  // Memory read/write
  always_ff @(posedge clk) begin
    if (rst) begin
      for (int i = 0; i < 128; i++)
        mem[i] <= i;
      dout <= 8'h0;
    end else if (r_mem)
      dout <= mem[addr];
    else if (w_mem)
      mem[addr] <= din;
  end

  // 4x clock pulse generator
  always_ff @(posedge clk) begin
    if (rst) begin
      pulse  <= 0;
      count1 <= 0;
    end else if (busy == 1'b0) begin
      pulse  <= 2;
      count1 <= 202;
    end else if (count1 == clk_count1 - 1) begin
      pulse  <= 1;
      count1 <= count1 + 1;
    end else if (count1 == clk_count1*2 - 1) begin
      pulse  <= 2;
      count1 <= count1 + 1;
    end else if (count1 == clk_count1*3 - 1) begin
      pulse  <= 3;
      count1 <= count1 + 1;
    end else if (count1 == clk_count1*4 - 1) begin
      pulse  <= 0;
      count1 <= 0;
    end else begin
      count1 <= count1 + 1;
    end
  end

  logic scl_prev;
  wire  start_det;

  always_ff @(posedge clk)
    scl_prev <= scl;

  assign start_det = ~scl & scl_prev;

  // Slave FSM
  always_ff @(posedge clk) begin
    if (rst) begin
      bitcnt  <= 0;
      state   <= IDLE;
      r_addr  <= 0;
      sda_en  <= 1'b0;
      sda_t   <= 1'b0;
      addr    <= 0;
      r_mem   <= 0;
      w_mem   <= 0;
      din     <= 8'h00;
      ack_err <= 0;
      done    <= 1'b0;
      busy    <= 1'b0;
      r_ack   <= 1'b0;
    end else begin
      case (state)
        IDLE: begin
          done <= 1'b0;
          if (scl == 1'b1 && sda == 1'b0) begin
            busy  <= 1'b1;
            state <= WAIT_P;
          end
        end

        WAIT_P: begin
          if (pulse == 2'b11 && count1 == 399)
            state <= READ_ADDR;
        end

        READ_ADDR: begin
          sda_en <= 1'b0;
          if (bitcnt <= 7) begin
            case (pulse)
              2: r_addr <= (count1 == 200) ? {r_addr[6:0], sda} : r_addr;
              default: ;
            endcase
            if (count1 == clk_count1*4 - 1)
              bitcnt <= bitcnt + 1;
          end else begin
            state  <= SEND_ACK1;
            bitcnt <= 0;
            sda_en <= 1'b1;
            addr   <= r_addr[7:1];
          end
        end

        SEND_ACK1: begin
          case (pulse)
            0: sda_t <= 1'b0;
            default: ;
          endcase
          if (count1 == clk_count1*4 - 1) begin
            if (r_addr[0] == 1'b1) begin
              state <= SEND_DATA;
              r_mem <= 1'b1;
            end else begin
              state <= READ_DATA;
              r_mem <= 1'b0;
            end
          end
        end

        READ_DATA: begin
          sda_en <= 1'b0;
          if (bitcnt <= 7) begin
            case (pulse)
              2: din <= (count1 == 200) ? {din[6:0], sda} : din;
              default: ;
            endcase
            if (count1 == clk_count1*4 - 1)
              bitcnt <= bitcnt + 1;
          end else begin
            state  <= SEND_ACK2;
            bitcnt <= 0;
            sda_en <= 1'b1;
            w_mem  <= 1'b1;
          end
        end

        SEND_ACK2: begin
          case (pulse)
            0: sda_t <= 1'b0;
            1: w_mem <= 1'b0;
            default: ;
          endcase
          if (count1 == clk_count1*4 - 1) begin
            state  <= DETECT_STOP;
            sda_en <= 1'b0;
          end
        end

        SEND_DATA: begin
          sda_en <= 1'b1;
          if (bitcnt <= 7) begin
            r_mem <= 1'b0;
            case (pulse)
              1: sda_t <= (count1 == 100) ? dout[7 - bitcnt] : sda_t;
              default: ;
            endcase
            if (count1 == clk_count1*4 - 1)
              bitcnt <= bitcnt + 1;
          end else begin
            state  <= MASTER_ACK;
            bitcnt <= 0;
            sda_en <= 1'b0;
          end
        end

        MASTER_ACK: begin
          case (pulse)
            2: r_ack <= (count1 == 200) ? sda : r_ack;
            default: ;
          endcase
          if (count1 == clk_count1*4 - 1) begin
            ack_err <= (r_ack != 1'b1);
            state   <= DETECT_STOP;
            sda_en  <= 1'b0;
          end
        end

        DETECT_STOP: begin
          if (pulse == 2'b11 && count1 == 399) begin
            state <= IDLE;
            busy  <= 1'b0;
            done  <= 1'b1;
          end
        end

        default: state <= IDLE;
      endcase
    end
  end

  assign sda = (sda_en) ? sda_t : 1'bz;

endmodule

// =============================================================================
// I2C Top — connects master and slave
// =============================================================================

module i2c_top (
  input  logic       clk, rst, newd, op,
  input  logic [6:0] addr,
  input  logic [7:0] din,
  output logic [7:0] dout,
  output logic       busy, ack_err,
  output logic       done
);

  wire sda, scl;
  wire ack_errm, ack_errs;

  i2c_master master (clk, rst, newd, addr, op, sda, scl, din, dout, busy, ack_errm, done);
  i2c_slave  slave  (scl, clk, rst, sda, ack_errs, );

  assign ack_err = ack_errs | ack_errm;

endmodule

// =============================================================================
// Interface
// =============================================================================

interface i2c_if;

  logic        clk;
  logic        rst;
  logic        newd;
  logic        op;
  logic [7:0]  din;
  logic [6:0]  addr;
  logic [7:0]  dout;
  logic        done;
  logic        busy;
  logic        ack_err;

  modport DUT (input clk, rst, newd, op, addr, din, output dout, done, busy, ack_err);
  modport TB  (input dout, done, busy, ack_err, output clk, rst, newd, op, addr, din);

endinterface
