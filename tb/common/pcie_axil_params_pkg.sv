`timescale 1ns/1ps

// One place for every width the TB and the DUT instance agree on.
// TLP_DATA_WIDTH is the only one we sweep; override at compile time with
// +define+TB_TLP_DATA_WIDTH=256. Everything else is pinned by the DUT's own
// initial-block checks (SEG_COUNT=1, HDR=128, AXIL data=32).
`ifndef TB_TLP_DATA_WIDTH
  `define TB_TLP_DATA_WIDTH 64
`endif

package pcie_axil_params_pkg;

  localparam int TLP_DATA_WIDTH  = `TB_TLP_DATA_WIDTH;
  localparam int TLP_STRB_WIDTH  = TLP_DATA_WIDTH / 32;
  localparam int TLP_HDR_WIDTH   = 128;
  localparam int TLP_SEG_COUNT   = 1;

  localparam int AXIL_DATA_WIDTH = 32;
  // 64 (the DUT default), not 32 like the smoke TB -- with 32 the upper
  // address bits of a 4DW request get truncated and the 3DW-vs-4DW tests
  // can't see them.
  localparam int AXIL_ADDR_WIDTH = 64;
  localparam int AXIL_STRB_WIDTH = AXIL_DATA_WIDTH / 8;

  // Tied to the DUT's completer_id input in tb_top; the scoreboard will
  // read the same constant when it checks completion headers.
  localparam logic [15:0] COMPLETER_ID = 16'h0100;

endpackage
