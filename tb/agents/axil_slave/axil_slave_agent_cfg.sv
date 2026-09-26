class axil_slave_agent_cfg extends uvm_object;
  `uvm_object_utils(axil_slave_agent_cfg)

  axil_vif_t              vif;
  uvm_active_passive_enum is_active = UVM_ACTIVE;

  function new(string name = "axil_slave_agent_cfg");
    super.new(name);
  endfunction

endclass
