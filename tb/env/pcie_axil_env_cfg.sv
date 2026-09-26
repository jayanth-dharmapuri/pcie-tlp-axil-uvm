// The test fills this in (vifs, active/passive, knobs) and hands it to the
// env; the env hands each agent its own sub-config. No component below the
// test ever touches config_db for a virtual interface.
class pcie_axil_env_cfg extends uvm_object;
  `uvm_object_utils(pcie_axil_env_cfg)

  tlp_req_agent_cfg    req_cfg;
  axil_slave_agent_cfg axil_cfg;
  tlp_cpl_agent_cfg    cpl_cfg;

  bit has_scoreboard = 1;

  function new(string name = "pcie_axil_env_cfg");
    super.new(name);
    req_cfg  = tlp_req_agent_cfg::type_id::create("req_cfg");
    axil_cfg = axil_slave_agent_cfg::type_id::create("axil_cfg");
    cpl_cfg  = tlp_cpl_agent_cfg::type_id::create("cpl_cfg");
  endfunction

endclass
