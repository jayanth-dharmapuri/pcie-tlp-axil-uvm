// Two output ports because two different consumers want two different moments:
//   req_ap -- fires on the address handshake, feeds the slave sequencer
//             so the reactive sequence knows a response is needed
//   ap     -- fires once the whole transaction completes (B or R done),
//             goes to the scoreboard
class axil_monitor extends uvm_monitor;
  `uvm_component_utils(axil_monitor)

  axil_vif_t vif;
  uvm_analysis_port #(axil_item) ap;
  uvm_analysis_port #(axil_item) req_ap;

  // Skeleton-only: with no stimulus the DUT should never raise a valid here.
  int unsigned valid_cycles;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    ap     = new("ap", this);
    req_ap = new("req_ap", this);
  endfunction

  task run_phase(uvm_phase phase);
    forever begin
      @(vif.mon_cb);
      if (vif.mon_cb.rst) continue;

      // DUT-driven control signals only; the data buses can legitimately
      // hold anything while valid is low.
      if ($isunknown({vif.mon_cb.m_axil_awvalid, vif.mon_cb.m_axil_wvalid,
                      vif.mon_cb.m_axil_arvalid, vif.mon_cb.m_axil_bready,
                      vif.mon_cb.m_axil_rready}))
        `uvm_error(get_type_name(), "DUT AXI-Lite control output is X/Z out of reset -- check the tb_top hookup")
      else if (vif.mon_cb.m_axil_awvalid || vif.mon_cb.m_axil_wvalid ||
               vif.mon_cb.m_axil_arvalid)
        valid_cycles++;

      // TODO(phase3): AW+W / AR handshakes -> req_ap.write(),
      //               B / R handshakes     -> ap.write()
    end
  endtask

endclass
