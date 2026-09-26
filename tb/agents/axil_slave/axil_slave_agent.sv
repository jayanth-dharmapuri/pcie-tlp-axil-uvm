class axil_slave_agent extends uvm_agent;
  `uvm_component_utils(axil_slave_agent)

  axil_slave_agent_cfg m_cfg;
  axil_slave_sequencer m_sqr;
  axil_slave_driver    m_drv;
  axil_monitor         m_mon;

  uvm_analysis_port #(axil_item) ap;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db #(axil_slave_agent_cfg)::get(this, "", "cfg", m_cfg))
      `uvm_fatal(get_type_name(), "no axil_slave_agent_cfg in config_db")
    if (m_cfg.vif == null)
      `uvm_fatal(get_type_name(), "axil_slave_agent_cfg.vif is null")

    ap    = new("ap", this);
    m_mon = axil_monitor::type_id::create("m_mon", this);
    if (m_cfg.is_active == UVM_ACTIVE) begin
      m_sqr = axil_slave_sequencer::type_id::create("m_sqr", this);
      m_drv = axil_slave_driver::type_id::create("m_drv", this);
    end
  endfunction

  function void connect_phase(uvm_phase phase);
    m_mon.vif = m_cfg.vif;
    m_mon.ap.connect(ap);
    if (m_cfg.is_active == UVM_ACTIVE) begin
      m_drv.vif = m_cfg.vif;
      m_drv.seq_item_port.connect(m_sqr.seq_item_export);
      m_mon.req_ap.connect(m_sqr.obs_req_fifo.analysis_export);
    end
  endfunction

endclass
