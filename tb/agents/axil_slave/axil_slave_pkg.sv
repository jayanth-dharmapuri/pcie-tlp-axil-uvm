`timescale 1ns/1ps

package axil_slave_pkg;

  import uvm_pkg::*;
  `include "uvm_macros.svh"
  import pcie_axil_params_pkg::*;

  typedef virtual axil_if #(.ADDR_W(AXIL_ADDR_WIDTH)) axil_vif_t;

  `include "axil_item.sv"
  `include "axil_slave_agent_cfg.sv"
  `include "axil_slave_sequencer.sv"
  `include "axil_slave_driver.sv"
  `include "axil_monitor.sv"
  `include "axil_slave_agent.sv"
  `include "axil_slave_seq_lib.sv"

endpackage
