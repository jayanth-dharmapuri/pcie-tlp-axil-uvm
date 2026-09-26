class axil_slave_driver extends uvm_driver #(axil_item);
  `uvm_component_utils(axil_slave_driver)

  axil_vif_t vif;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  task run_phase(uvm_phase phase);
    drive_idle();
    wait (vif.rst === 1'b0);

    forever begin
      seq_item_port.get_next_item(req);
      `uvm_info(get_type_name(), {"got ", req.convert2string()}, UVM_HIGH)
      // TODO(phase3): accept AW+W / AR (with the item's ready delays), then
      // drive B or R with the item's resp/rdata.
      repeat (req.idle_cycles) @(vif.drv_cb);
      seq_item_port.item_done();
    end
  endtask

  // readys low while idle is safe for the skeleton since the DUT never
  // issues anything. Phase 3 decides whether the default slave is
  // always-ready or waits to be told.
  task drive_idle();
    vif.m_axil_awready <= 1'b0;
    vif.m_axil_wready  <= 1'b0;
    vif.m_axil_arready <= 1'b0;
    vif.m_axil_bvalid  <= 1'b0;
    vif.m_axil_bresp   <= 2'b00;
    vif.m_axil_rvalid  <= 1'b0;
    vif.m_axil_rresp   <= 2'b00;
    vif.m_axil_rdata   <= '0;
  endtask

endclass
