`timescale 1ns/1ps

package tlp_req_pkg;

  import uvm_pkg::*;
  `include "uvm_macros.svh"
  import pcie_axil_params_pkg::*;

  // Pin the interface specialization once; every class uses this typedef so
  // a width change can't leave one component pointing at a different type.
  typedef virtual tlp_req_if #(.DATA_W(TLP_DATA_WIDTH)) tlp_req_vif_t;

  `include "tlp_req_item.sv"
  `include "tlp_req_agent_cfg.sv"

  typedef uvm_sequencer #(tlp_req_item) tlp_req_sequencer;

  `include "tlp_req_driver.sv"
  `include "tlp_req_monitor.sv"
  `include "tlp_req_agent.sv"
  `include "tlp_req_seq_lib.sv"

endpackage
