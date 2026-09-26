`timescale 1ns/1ps

package tlp_cpl_pkg;

  import uvm_pkg::*;
  `include "uvm_macros.svh"
  import pcie_axil_params_pkg::*;

  typedef virtual tlp_cpl_if #(.DATA_W(TLP_DATA_WIDTH)) tlp_cpl_vif_t;

  `include "tlp_cpl_item.sv"
  `include "tlp_cpl_agent_cfg.sv"

  typedef uvm_sequencer #(tlp_cpl_item) tlp_cpl_sequencer;

  `include "tlp_cpl_driver.sv"
  `include "tlp_cpl_monitor.sv"
  `include "tlp_cpl_agent.sv"
  `include "tlp_cpl_seq_lib.sv"

endpackage
