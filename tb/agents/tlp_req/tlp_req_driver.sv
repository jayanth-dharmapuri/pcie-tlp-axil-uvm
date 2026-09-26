class tlp_req_driver extends uvm_driver #(tlp_req_item);
  `uvm_component_utils(tlp_req_driver)

  tlp_req_vif_t vif;   // set by the agent in connect_phase

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  task run_phase(uvm_phase phase);
    drive_idle();
    wait (vif.rst === 1'b0);

    forever begin
      seq_item_port.get_next_item(req);
      `uvm_info(get_type_name(), {"got ", req.convert2string()}, UVM_HIGH)
      // TODO(phase3): put hdr/data on the bus with valid/sop/eop, hold until
      // rx_req_tlp_ready, then drop valid. For now just burn the idle time.
      repeat (req.idle_cycles) @(vif.drv_cb);
      seq_item_port.item_done();
    end
  endtask

  // Direct assignment, not through drv_cb: this runs at time 0 before the
  // first clock edge, and a clocking-block drive wouldn't land until then.
  task drive_idle();
    vif.rx_req_tlp_valid <= 1'b0;
    vif.rx_req_tlp_sop   <= 1'b0;
    vif.rx_req_tlp_eop   <= 1'b0;
    vif.rx_req_tlp_hdr   <= '0;
    vif.rx_req_tlp_data  <= '0;
  endtask

endclass
