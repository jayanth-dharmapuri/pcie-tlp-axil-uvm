`timescale 1ns/1ps

// Request side of the DUT: rx_req_tlp_* (TB drives, DUT sinks).
// Signal names match the DUT ports exactly so tb_top is a straight 1:1 hookup.
// TLP_SEG_COUNT is fixed at 1 by the DUT, so valid/sop/eop are single bits.
interface tlp_req_if #(parameter int DATA_W = 64) (input logic clk, input logic rst);

  logic [DATA_W-1:0] rx_req_tlp_data;
  logic [127:0]      rx_req_tlp_hdr;
  logic              rx_req_tlp_valid;
  logic              rx_req_tlp_sop;
  logic              rx_req_tlp_eop;
  logic              rx_req_tlp_ready;

  clocking drv_cb @(posedge clk);
    default input #1step output #1;
    output rx_req_tlp_data, rx_req_tlp_hdr, rx_req_tlp_valid,
           rx_req_tlp_sop, rx_req_tlp_eop;
    input  rx_req_tlp_ready;
  endclocking

  clocking mon_cb @(posedge clk);
    default input #1step;
    input rst, rx_req_tlp_data, rx_req_tlp_hdr, rx_req_tlp_valid,
          rx_req_tlp_sop, rx_req_tlp_eop, rx_req_tlp_ready;
  endclocking

endinterface
