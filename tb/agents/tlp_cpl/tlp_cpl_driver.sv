// Drives exactly one signal: tx_cpl_tlp_ready. Everything else on this
// interface belongs to the DUT.
class tlp_cpl_driver extends uvm_driver #(tlp_cpl_item);
  `uvm_component_utils(tlp_cpl_driver)

  tlp_cpl_vif_t vif;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  task run_phase(uvm_phase phase);
    drive_idle();
    wait (vif.rst === 1'b0);

    forever begin
      seq_item_port.get_next_item(req);
      `uvm_info(get_type_name(), {"got ", req.convert2string()}, UVM_HIGH)
      // TODO(phase3): apply the item's ready pattern (stall N / random duty).
      repeat (req.idle_cycles) @(vif.drv_cb);
      seq_item_port.item_done();
    end
  endtask

  // Idle = always-ready sink, so completions never get stuck just because
  // no backpressure sequence happens to be running.
  task drive_idle();
    vif.tx_cpl_tlp_ready <= 1'b1;
  endtask

endclass
