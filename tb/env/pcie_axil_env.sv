// Phase 5 adds a coverage subscriber next to the scoreboard, fed from the
// same three agent ports.
class pcie_axil_env extends uvm_env;
  `uvm_component_utils(pcie_axil_env)

  pcie_axil_env_cfg    m_cfg;
  tlp_req_agent        m_req_agent;
  axil_slave_agent     m_axil_agent;
  tlp_cpl_agent        m_cpl_agent;
  pcie_axil_scoreboard m_scb;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db #(pcie_axil_env_cfg)::get(this, "", "cfg", m_cfg))
      `uvm_fatal(get_type_name(), "no pcie_axil_env_cfg in config_db")

    // Scoped to each agent's instance name so no agent picks up another's.
    uvm_config_db #(tlp_req_agent_cfg)::set(this, "m_req_agent", "cfg", m_cfg.req_cfg);
    uvm_config_db #(axil_slave_agent_cfg)::set(this, "m_axil_agent", "cfg", m_cfg.axil_cfg);
    uvm_config_db #(tlp_cpl_agent_cfg)::set(this, "m_cpl_agent", "cfg", m_cfg.cpl_cfg);

    m_req_agent  = tlp_req_agent::type_id::create("m_req_agent", this);
    m_axil_agent = axil_slave_agent::type_id::create("m_axil_agent", this);
    m_cpl_agent  = tlp_cpl_agent::type_id::create("m_cpl_agent", this);

    if (m_cfg.has_scoreboard)
      m_scb = pcie_axil_scoreboard::type_id::create("m_scb", this);
  endfunction

  function void connect_phase(uvm_phase phase);
    if (m_cfg.has_scoreboard) begin
      m_req_agent.ap.connect(m_scb.req_imp);
      m_axil_agent.ap.connect(m_scb.axil_imp);
      m_cpl_agent.ap.connect(m_scb.cpl_imp);
    end
  endfunction

endclass
