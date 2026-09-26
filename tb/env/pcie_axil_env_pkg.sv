`timescale 1ns/1ps

package pcie_axil_env_pkg;

  import uvm_pkg::*;
  `include "uvm_macros.svh"
  import pcie_axil_params_pkg::*;
  import tlp_req_pkg::*;
  import axil_slave_pkg::*;
  import tlp_cpl_pkg::*;

  // One write_*() per incoming stream on the scoreboard. These macros have to
  // sit at package scope, outside any class.
  `uvm_analysis_imp_decl(_req)
  `uvm_analysis_imp_decl(_axil)
  `uvm_analysis_imp_decl(_cpl)

  `include "pcie_axil_env_cfg.sv"
  `include "pcie_axil_scoreboard.sv"
  `include "pcie_axil_env.sv"

endpackage
