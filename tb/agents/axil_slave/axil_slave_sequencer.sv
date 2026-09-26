// A slave can't decide what to send until the master asks, so this
// sequencer carries a FIFO the monitor fills with observed AR/AW requests.
// The slave sequence blocks on obs_req_fifo.get(), then builds the response
// (data, resp code, delays) and hands it to the driver. The FIFO is wired up
// now; nothing writes into it until the Phase 3 monitor does.
class axil_slave_sequencer extends uvm_sequencer #(axil_item);
  `uvm_component_utils(axil_slave_sequencer)

  // Not "req_fifo": uvm_sequencer already owns a child component by that
  // name, and the duplicate is a UVM_FATAL at build.
  uvm_tlm_analysis_fifo #(axil_item) obs_req_fifo;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    obs_req_fifo = new("obs_req_fifo", this);
  endfunction

endclass
