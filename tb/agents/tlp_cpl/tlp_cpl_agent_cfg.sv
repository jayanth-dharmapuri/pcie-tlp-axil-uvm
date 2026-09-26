class tlp_cpl_agent_cfg extends uvm_object;
  `uvm_object_utils(tlp_cpl_agent_cfg)

  tlp_cpl_vif_t           vif;
  // ACTIVE = our driver owns tx_cpl_tlp_ready. If a test ever runs this
  // PASSIVE, nothing drives ready, so tb_top would need to tie it.
  uvm_active_passive_enum is_active = UVM_ACTIVE;

  function new(string name = "tlp_cpl_agent_cfg");
    super.new(name);
  endfunction

endclass
