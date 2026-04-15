// =============================================================================
// AXI4-Lite Slave — 128x32-bit memory with read/write channels
// =============================================================================
// Improvements: always_ff, fixed blocking assignment, reset handles init,
//               modport on interface
// =============================================================================

module axilite_s (
  input  wire         s_axi_aclk,
  input  wire         s_axi_aresetn,

  // Write address channel
  input  wire         s_axi_awvalid,
  output reg          s_axi_awready,
  input  wire [31:0]  s_axi_awaddr,

  // Write data channel
  input  wire         s_axi_wvalid,
  output reg          s_axi_wready,
  input  wire [31:0]  s_axi_wdata,

  // Write response channel
  output reg          s_axi_bvalid,
  input  wire         s_axi_bready,
  output reg  [1:0]   s_axi_bresp,

  // Read address channel
  input  wire         s_axi_arvalid,
  output reg          s_axi_arready,
  input  wire [31:0]  s_axi_araddr,

  // Read data channel
  output reg          s_axi_rvalid,
  input  wire         s_axi_rready,
  output reg  [31:0]  s_axi_rdata,
  output reg  [1:0]   s_axi_rresp
);

  localparam IDLE           = 0,
             SEND_WADDR_ACK = 1,
             SEND_RADDR_ACK = 2,
             SEND_WDATA_ACK = 3,
             UPDATE_MEM     = 4,
             SEND_WR_ERR    = 5,
             SEND_WR_RESP   = 6,
             GEN_DATA       = 7,
             SEND_RD_ERR    = 8,
             SEND_RDATA     = 9;

  reg [3:0]  state;
  reg [1:0]  count;
  reg [31:0] waddr, raddr, wdata, rdata;
  reg [31:0] mem [128];

  always_ff @(posedge s_axi_aclk) begin
    if (s_axi_aresetn == 1'b0) begin
      state         <= IDLE;
      for (int i = 0; i < 128; i++)
        mem[i] <= 0;
      s_axi_awready <= 0;
      s_axi_wready  <= 0;
      s_axi_bvalid  <= 0;
      s_axi_bresp   <= 0;
      s_axi_arready <= 0;
      s_axi_rvalid  <= 0;
      s_axi_rdata   <= 0;
      s_axi_rresp   <= 0;
      waddr         <= 0;
      raddr         <= 0;
      wdata         <= 0;
      rdata         <= 0;
      count         <= 0;
    end else begin
      case (state)

        IDLE: begin
          s_axi_awready <= 0;
          s_axi_wready  <= 0;
          s_axi_bvalid  <= 0;
          s_axi_bresp   <= 0;
          s_axi_arready <= 0;
          s_axi_rvalid  <= 0;
          s_axi_rdata   <= 0;
          s_axi_rresp   <= 0;
          waddr         <= 0;
          raddr         <= 0;
          wdata         <= 0;
          rdata         <= 0;
          count         <= 0;

          if (s_axi_awvalid) begin
            state         <= SEND_WADDR_ACK;
            waddr         <= s_axi_awaddr;
            s_axi_awready <= 1'b1;
          end else if (s_axi_arvalid) begin
            state         <= SEND_RADDR_ACK;
            raddr         <= s_axi_araddr;
            s_axi_arready <= 1'b1;
          end
        end

        SEND_WADDR_ACK: begin
          s_axi_awready <= 1'b0;
          if (s_axi_wvalid) begin
            wdata        <= s_axi_wdata;
            s_axi_wready <= 1'b1;
            state        <= SEND_WDATA_ACK;
          end
        end

        SEND_WDATA_ACK: begin
          s_axi_wready <= 1'b0;
          if (waddr < 128) begin
            state      <= UPDATE_MEM;
            mem[waddr] <= wdata;
          end else begin
            state        <= SEND_WR_ERR;
            s_axi_bresp  <= 2'b11;
            s_axi_bvalid <= 1'b1;
          end
        end

        UPDATE_MEM: begin
          mem[waddr] <= wdata;
          state      <= SEND_WR_RESP;
        end

        SEND_WR_RESP: begin
          s_axi_bresp  <= 2'b00;
          s_axi_bvalid <= 1'b1;
          if (s_axi_bready)
            state <= IDLE;
        end

        SEND_WR_ERR: begin
          if (s_axi_bready)
            state <= IDLE;
        end

        SEND_RADDR_ACK: begin
          s_axi_arready <= 1'b0;    // fixed: was blocking assignment
          if (raddr < 128)
            state <= GEN_DATA;
          else begin
            s_axi_rvalid <= 1'b1;
            state        <= SEND_RD_ERR;
            s_axi_rdata  <= 0;
            s_axi_rresp  <= 2'b11;
          end
        end

        GEN_DATA: begin
          if (count < 2) begin
            rdata <= mem[raddr];
            count <= count + 1;
          end else begin
            s_axi_rvalid <= 1'b1;
            s_axi_rdata  <= rdata;
            s_axi_rresp  <= 2'b00;
            if (s_axi_rready)
              state <= IDLE;
          end
        end

        SEND_RD_ERR: begin
          if (s_axi_rready)
            state <= IDLE;
        end

        default: state <= IDLE;
      endcase
    end
  end

endmodule

// =============================================================================
// Interface
// =============================================================================

interface axi_if;

  logic        clk, resetn;
  logic        awvalid, awready;
  logic        arvalid, arready;
  logic        wvalid, wready;
  logic        bready, bvalid;
  logic        rvalid, rready;
  logic [31:0] awaddr, araddr, wdata, rdata;
  logic [1:0]  wresp, rresp;

  modport DUT (
    input  clk, resetn,
    input  awvalid, awaddr, wvalid, wdata, bready,
    input  arvalid, araddr, rready,
    output awready, wready, bvalid, wresp,
    output arready, rvalid, rdata, rresp
  );

  modport TB (
    input  awready, wready, bvalid, wresp,
    input  arready, rvalid, rdata, rresp,
    output clk, resetn,
    output awvalid, awaddr, wvalid, wdata, bready,
    output arvalid, araddr, rready
  );

endinterface
