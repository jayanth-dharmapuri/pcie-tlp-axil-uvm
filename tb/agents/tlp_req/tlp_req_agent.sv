class tlp_req_agent extends uvm_agent;
  `uvm_component_utils(tlp_req_agent)

  tlp_req_agent_cfg m_cfg;
  tlp_req_sequencer m_sqr;
  tlp_req_driver    m_drv;
  tlp_req_monitor   m_mon;

  uvm_analysis_port #(tlp_req_item) ap;   // re-exports the monitor's port

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db #(tlp_req_agent_cfg)::get(this, "", "cfg", m_cfg))
      `uvm_fatal(get_type_name(), "no tlp_req_agent_cfg in config_db")
    if (m_cfg.vif == null)
      `uvm_fatal(get_type_name(), "tlp_req_agent_cfg.vif is null")

    ap    = new("ap", this);
    m_mon = tlp_req_monitor::type_id::create("m_mon", this);
    if (m_cfg.is_active == UVM_ACTIVE) begin
      m_sqr = tlp_req_sequencer::type_id::create("m_sqr", this);
      m_drv = tlp_req_driver::type_id::create("m_drv", this);
    end
  endfunction

  function void connect_phase(uvm_phase phase);
    m_mon.vif = m_cfg.vif;
    m_mon.ap.connect(ap);
    if (m_cfg.is_active == UVM_ACTIVE) begin
      m_drv.vif = m_cfg.vif;
      m_drv.seq_item_port.connect(m_sqr.seq_item_export);
    end
  endfunction

endclass
