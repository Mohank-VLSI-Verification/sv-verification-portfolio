// =============================================================================
// AXI4-Lite Slave — 128 x 32-bit word memory
// =============================================================================

module axilite_s (
  input  logic         s_axi_aclk,
  input  logic         s_axi_aresetn,

  // Write address channel
  input  logic         s_axi_awvalid,
  output logic         s_axi_awready,
  input  logic [31:0]  s_axi_awaddr,

  // Write data channel
  input  logic         s_axi_wvalid,
  output logic         s_axi_wready,
  input  logic [31:0]  s_axi_wdata,

  // Write response channel
  output logic         s_axi_bvalid,
  input  logic         s_axi_bready,
  output logic [1:0]   s_axi_bresp,

  // Read address channel
  input  logic         s_axi_arvalid,
  output logic         s_axi_arready,
  input  logic [31:0]  s_axi_araddr,

  // Read data channel
  output logic         s_axi_rvalid,
  input  logic         s_axi_rready,
  output logic [31:0]  s_axi_rdata,
  output logic [1:0]   s_axi_rresp
);

  // ---------------------------------------------------------------------------
  // FSM state encoding
  // ---------------------------------------------------------------------------
  typedef enum logic [2:0] {
    IDLE           = 3'd0,
    SEND_WADDR_ACK = 3'd1,
    SEND_WDATA_ACK = 3'd2,
    SEND_WR_RESP   = 3'd3,
    SEND_WR_ERR    = 3'd4,
    SEND_RADDR_ACK = 3'd5,
    SEND_RDATA     = 3'd6,
    SEND_RD_ERR    = 3'd7
  } state_t;

  state_t state;

  // ---------------------------------------------------------------------------
  // Internal storage
  // ---------------------------------------------------------------------------
  logic [31:0] waddr, raddr, wdata;
  logic [31:0] mem [128];

  // Byte-address -> word-index (drop bottom 2 bits, take 7 bits for 128 words)
  wire [6:0] waddr_idx = waddr[8:2];
  wire [6:0] raddr_idx = raddr[8:2];

  // Valid if within range (128 words * 4 bytes = 512) and word-aligned
  wire waddr_valid = (waddr < 32'd512) && (waddr[1:0] == 2'b00);
  wire raddr_valid = (raddr < 32'd512) && (raddr[1:0] == 2'b00);

  // ---------------------------------------------------------------------------
  // Main FSM
  // ---------------------------------------------------------------------------
  always_ff @(posedge s_axi_aclk) begin
    if (!s_axi_aresetn) begin
      state         <= IDLE;
      for (int i = 0; i < 128; i++)
        mem[i] <= 32'd0;
      s_axi_awready <= 1'b0;
      s_axi_wready  <= 1'b0;
      s_axi_bvalid  <= 1'b0;
      s_axi_bresp   <= 2'b00;
      s_axi_arready <= 1'b0;
      s_axi_rvalid  <= 1'b0;
      s_axi_rdata   <= 32'd0;
      s_axi_rresp   <= 2'b00;
      waddr         <= 32'd0;
      raddr         <= 32'd0;
      wdata         <= 32'd0;
    end else begin
      case (state)

        // -------------------------------------------------------------------
        IDLE: begin
          s_axi_awready <= 1'b0;
          s_axi_wready  <= 1'b0;
          s_axi_bvalid  <= 1'b0;
          s_axi_arready <= 1'b0;
          s_axi_rvalid  <= 1'b0;

          if (s_axi_awvalid) begin
            waddr         <= s_axi_awaddr;
            s_axi_awready <= 1'b1;
            state         <= SEND_WADDR_ACK;
          end else if (s_axi_arvalid) begin
            raddr         <= s_axi_araddr;
            s_axi_arready <= 1'b1;
            state         <= SEND_RADDR_ACK;
          end
        end

        // -------------------------------------------------------------------
        SEND_WADDR_ACK: begin
          s_axi_awready <= 1'b0;
          if (s_axi_wvalid) begin
            wdata        <= s_axi_wdata;
            s_axi_wready <= 1'b1;
            state        <= SEND_WDATA_ACK;
          end
        end

        // -------------------------------------------------------------------
        SEND_WDATA_ACK: begin
          s_axi_wready <= 1'b0;
          if (waddr_valid) begin
            mem[waddr_idx] <= wdata;
            s_axi_bresp    <= 2'b00;       // OKAY
            s_axi_bvalid   <= 1'b1;
            state          <= SEND_WR_RESP;
          end else begin
            s_axi_bresp    <= 2'b11;       // DECERR
            s_axi_bvalid   <= 1'b1;
            state          <= SEND_WR_ERR;
          end
        end

        // -------------------------------------------------------------------
        SEND_WR_RESP, SEND_WR_ERR: begin
          if (s_axi_bready) begin
            s_axi_bvalid <= 1'b0;
            s_axi_bresp  <= 2'b00;
            state        <= IDLE;
          end
        end

        // -------------------------------------------------------------------
        SEND_RADDR_ACK: begin
          s_axi_arready <= 1'b0;
          if (raddr_valid) begin
            s_axi_rdata  <= mem[raddr_idx];
            s_axi_rresp  <= 2'b00;         // OKAY
            s_axi_rvalid <= 1'b1;
            state        <= SEND_RDATA;
          end else begin
            s_axi_rdata  <= 32'd0;
            s_axi_rresp  <= 2'b11;         // DECERR
            s_axi_rvalid <= 1'b1;
            state        <= SEND_RD_ERR;
          end
        end

        // -------------------------------------------------------------------
        SEND_RDATA, SEND_RD_ERR: begin
          if (s_axi_rready) begin
            s_axi_rvalid <= 1'b0;
            s_axi_rresp  <= 2'b00;
            s_axi_rdata  <= 32'd0;
            state        <= IDLE;
          end
        end

        // -------------------------------------------------------------------
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
  logic [1:0]  bresp, rresp;        // fixed: was 'wresp', now matches DUT

  modport DUT (
    input  clk, resetn,
    input  awvalid, awaddr, wvalid, wdata, bready,
    input  arvalid, araddr, rready,
    output awready, wready, bvalid, bresp,
    output arready, rvalid, rdata, rresp
  );

  modport TB (
    input  awready, wready, bvalid, bresp,
    input  arready, rvalid, rdata, rresp,
    output clk, resetn,
    output awvalid, awaddr, wvalid, wdata, bready,
    output arvalid, araddr, rready
  );

endinterface