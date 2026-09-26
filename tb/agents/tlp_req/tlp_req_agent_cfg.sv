class tlp_req_agent_cfg extends uvm_object;
  `uvm_object_utils(tlp_req_agent_cfg)

  tlp_req_vif_t           vif;
  uvm_active_passive_enum is_active = UVM_ACTIVE;

  function new(string name = "tlp_req_agent_cfg");
    super.new(name);
  endfunction

endclass
