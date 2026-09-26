`timescale 1ns/1ps

package pcie_axil_test_pkg;

  import uvm_pkg::*;
  `include "uvm_macros.svh"
  import pcie_axil_params_pkg::*;
  import tlp_req_pkg::*;
  import axil_slave_pkg::*;
  import tlp_cpl_pkg::*;
  import pcie_axil_env_pkg::*;

  `include "base_test.sv"
  `include "dummy_test.sv"

endpackage
