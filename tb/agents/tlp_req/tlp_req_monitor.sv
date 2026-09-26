class tlp_req_monitor extends uvm_monitor;
  `uvm_component_utils(tlp_req_monitor)

  tlp_req_vif_t vif;
  uvm_analysis_port #(tlp_req_item) ap;

  // Skeleton-only: counts cycles the DUT's ready was high out of reset.
  // Non-zero proves rx_req_tlp_ready makes it from the DUT back to the TB.
  int unsigned ready_cycles;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    ap = new("ap", this);
  endfunction

  task run_phase(uvm_phase phase);
    forever begin
      @(vif.mon_cb);
      if (vif.mon_cb.rst) continue;

      if ($isunknown(vif.mon_cb.rx_req_tlp_ready))
        `uvm_error(get_type_name(), "rx_req_tlp_ready is X/Z out of reset -- check the tb_top hookup")
      else if (vif.mon_cb.rx_req_tlp_ready)
        ready_cycles++;

      // TODO(phase3): on valid && ready && sop, capture hdr/data into a
      // tlp_req_item and ap.write() it.
    end
  endtask

endclass
