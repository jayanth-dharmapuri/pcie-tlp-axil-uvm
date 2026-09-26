`timescale 1ns/1ps

// Completion side of the DUT: tx_cpl_tlp_* (DUT drives, TB sinks) plus the
// sideband signals that don't belong to either stream on their own:
//   completer_id        -- DUT input, tied to a constant in tb_top
//   status_error_cor/   -- DUT outputs, 1-cycle pulses. They ride along here
//   status_error_uncor     so the scoreboard sees them next to completions.
// tx_cpl_tlp_sop/eop are hardwired to 1 in the DUT (single-beat completions).
interface tlp_cpl_if #(parameter int DATA_W = 64) (input logic clk, input logic rst);

  localparam int STRB_W = DATA_W / 32;

  logic [DATA_W-1:0] tx_cpl_tlp_data;
  logic [STRB_W-1:0] tx_cpl_tlp_strb;
  logic [127:0]      tx_cpl_tlp_hdr;
  logic              tx_cpl_tlp_valid;
  logic              tx_cpl_tlp_sop;
  logic              tx_cpl_tlp_eop;
  logic              tx_cpl_tlp_ready;

  logic [15:0]       completer_id;
  logic              status_error_cor;
  logic              status_error_uncor;

  // the only thing the cpl driver owns is ready (backpressure)
  clocking drv_cb @(posedge clk);
    default input #1step output #1;
    output tx_cpl_tlp_ready;
    input  tx_cpl_tlp_valid;
  endclocking

  clocking mon_cb @(posedge clk);
    default input #1step;
    input rst, tx_cpl_tlp_data, tx_cpl_tlp_strb, tx_cpl_tlp_hdr,
          tx_cpl_tlp_valid, tx_cpl_tlp_sop, tx_cpl_tlp_eop, tx_cpl_tlp_ready,
          status_error_cor, status_error_uncor;
  endclocking

endinterface
