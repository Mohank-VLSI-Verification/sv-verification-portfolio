// =============================================================================
// Driver: Drives FIFO inputs via virtual interface
// =============================================================================
// Fix: Uses transaction's data_in instead of generating its own random data
//      This maintains generator → driver data flow integrity
// =============================================================================

class driver;

  virtual fifo_if fif;
  mailbox #(transaction) mbx;
  transaction datac;

  function new(mailbox #(transaction) mbx);
    this.mbx = mbx;
  endfunction

  task reset();
    fif.rst      <= 1'b1;
    fif.rd       <= 1'b0;
    fif.wr       <= 1'b0;
    fif.data_in  <= 8'b0;
    repeat (5) @(posedge fif.clock);
    fif.rst <= 1'b0;
    $display("[DRV] : DUT Reset Done @ %0t", $time);
    $display("------------------------------------------");
  endtask

  task write(input bit [7:0] data);
    @(posedge fif.clock);
    fif.rst     <= 1'b0;
    fif.rd      <= 1'b0;
    fif.wr      <= 1'b1;
    fif.data_in <= data;       // use transaction data, not $urandom_range
    @(posedge fif.clock);
    fif.wr      <= 1'b0;
    $display("[DRV] : DATA WRITE  data:%0d @ %0t", data, $time);
    @(posedge fif.clock);
  endtask

  task read();
    @(posedge fif.clock);
    fif.rst <= 1'b0;
    fif.rd  <= 1'b1;
    fif.wr  <= 1'b0;
    @(posedge fif.clock);
    fif.rd  <= 1'b0;
    $display("[DRV] : DATA READ @ %0t", $time);
    @(posedge fif.clock);
  endtask

  task run();
    forever begin
      mbx.get(datac);
      if (datac.oper == 1'b1)
        write(datac.data_in);
      else
        read();
    end
  endtask

endclass
