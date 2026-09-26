class tlp_cpl_monitor extends uvm_monitor;
  `uvm_component_utils(tlp_cpl_monitor)

  tlp_cpl_vif_t vif;
  uvm_analysis_port #(tlp_cpl_item) ap;

  // Skeleton-only counters. With no stimulus all three should stay at 0.
  int unsigned cpl_valid_cycles;
  int unsigned err_cor_pulses;
  int unsigned err_uncor_pulses;

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

      if ($isunknown({vif.mon_cb.tx_cpl_tlp_valid,
                      vif.mon_cb.status_error_cor,
                      vif.mon_cb.status_error_uncor}))
        `uvm_error(get_type_name(), "DUT completion/status output is X/Z out of reset -- check the tb_top hookup")
      else begin
        if (vif.mon_cb.tx_cpl_tlp_valid)   cpl_valid_cycles++;
        if (vif.mon_cb.status_error_cor)   err_cor_pulses++;
        if (vif.mon_cb.status_error_uncor) err_uncor_pulses++;
      end

      // TODO(phase3): on valid && ready, unpack hdr/data into an item and
      // ap.write() it. Also decide how the status_error pulses reach the
      // scoreboard: a field on the item, or their own analysis port. They
      // don't line up 1:1 with completions (a dropped MWr pulses uncor with
      // no completion at all).
    end
  endtask

endclass
