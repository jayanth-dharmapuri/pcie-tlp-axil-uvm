`timescale 1ns/1ps

// Clock and reset live here, not in tb_top, so the test can grab this
// interface and pulse reset whenever it wants (reset-mid-transaction test).
// DUT reset is active-high and synchronous.
interface clk_rst_if;

  logic clk = 1'b0;
  logic rst = 1'b1;       // held in reset from time 0 until the test releases it
  logic rst_req = 1'b1;

  always #5 clk = ~clk;   // 100 MHz

  // The test only touches rst_req; rst itself is only ever written here.
  // Under Verilator 5.046, rst didn't propagate to the other interfaces' rst ports
  // when a class wrote it directly through the vif. Registering it here also
  // keeps every reset edge lined up with a clock edge.
  always @(posedge clk) rst <= rst_req;

  // Nonblocking so the always block above sees a clean value at the edge the
  // task writes on, instead of racing it.
  task automatic apply_reset(int unsigned cycles = 5);
    rst_req <= 1'b1;
    repeat (cycles) @(posedge clk);
    rst_req <= 1'b0;
    @(posedge clk);   // return once rst has actually dropped
  endtask

endinterface
