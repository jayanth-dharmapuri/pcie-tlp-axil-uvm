// Every test extends this. It is the only place that reads virtual
// interfaces out of config_db (tb_top put them there); from here they flow
// down inside cfg objects.
class base_test extends uvm_test;
  `uvm_component_utils(base_test)

  pcie_axil_env      m_env;
  pcie_axil_env_cfg  m_cfg;
  virtual clk_rst_if m_clk_rst_vif;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    m_cfg = pcie_axil_env_cfg::type_id::create("m_cfg");

    if (!uvm_config_db #(virtual clk_rst_if)::get(this, "", "clk_rst_vif", m_clk_rst_vif))
      `uvm_fatal(get_type_name(), "clk_rst_vif not found in config_db")
    if (!uvm_config_db #(tlp_req_vif_t)::get(this, "", "req_vif", m_cfg.req_cfg.vif))
      `uvm_fatal(get_type_name(), "req_vif not found in config_db")
    if (!uvm_config_db #(axil_vif_t)::get(this, "", "axil_vif", m_cfg.axil_cfg.vif))
      `uvm_fatal(get_type_name(), "axil_vif not found in config_db")
    if (!uvm_config_db #(tlp_cpl_vif_t)::get(this, "", "cpl_vif", m_cfg.cpl_cfg.vif))
      `uvm_fatal(get_type_name(), "cpl_vif not found in config_db")

    // Derived tests change knobs on m_cfg after super.build_phase() and
    // before the env builds (the env reads m_cfg in its own build_phase,
    // which runs after this one).
    uvm_config_db #(pcie_axil_env_cfg)::set(this, "m_env", "cfg", m_cfg);
    m_env = pcie_axil_env::type_id::create("m_env", this);

    // Stops a hung test from running forever: a missing ready or a
    // sequence that never finishes.
    uvm_root::get().set_timeout(100us, 1);
  endfunction

  function void end_of_elaboration_phase(uvm_phase phase);
    uvm_root::get().print_topology();
  endfunction

  task reset_dut(int unsigned cycles = 5);
    m_clk_rst_vif.apply_reset(cycles);
  endtask

  task wait_cycles(int unsigned n);
    repeat (n) @(posedge m_clk_rst_vif.clk);
  endtask

endclass
