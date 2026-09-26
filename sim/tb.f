// Compile list, paths relative to the repo root (run the simulator from there).
// Order matters: params pkg -> interfaces -> agent pkgs -> env -> tests -> DUT -> top.
// sim/flatten_for_edaplayground.sh reads this same file to build the EDA
// Playground bundle, so keep one path per line.

+incdir+tb/common
+incdir+tb/agents/tlp_req
+incdir+tb/agents/axil_slave
+incdir+tb/agents/tlp_cpl
+incdir+tb/env
+incdir+tb/tests

tb/common/pcie_axil_params_pkg.sv
tb/common/clk_rst_if.sv
tb/agents/tlp_req/tlp_req_if.sv
tb/agents/axil_slave/axil_if.sv
tb/agents/tlp_cpl/tlp_cpl_if.sv

tb/agents/tlp_req/tlp_req_pkg.sv
tb/agents/axil_slave/axil_slave_pkg.sv
tb/agents/tlp_cpl/tlp_cpl_pkg.sv
tb/env/pcie_axil_env_pkg.sv
tb/tests/pcie_axil_test_pkg.sv

third_party/verilog-pcie/rtl/pcie_axil_master_minimal.v
tb/top/tb_top.sv
