// Phase 2: only proves the three monitor streams are connected; it counts
// what arrives and checks nothing.
// Phase 4: each request goes through the reference model, which predicts
// (a) the AXI transaction, if any, and (b) the completion, if any, plus the
// cor/uncor pulse. Predictions are queued and compared in order against
// write_axil / write_cpl. On reset the queues get flushed.
class pcie_axil_scoreboard extends uvm_scoreboard;
  `uvm_component_utils(pcie_axil_scoreboard)

  uvm_analysis_imp_req  #(tlp_req_item, pcie_axil_scoreboard) req_imp;
  uvm_analysis_imp_axil #(axil_item,    pcie_axil_scoreboard) axil_imp;
  uvm_analysis_imp_cpl  #(tlp_cpl_item, pcie_axil_scoreboard) cpl_imp;

  int unsigned num_req, num_axil, num_cpl;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    req_imp  = new("req_imp",  this);
    axil_imp = new("axil_imp", this);
    cpl_imp  = new("cpl_imp",  this);
  endfunction

  function void write_req(tlp_req_item t);
    num_req++;
    `uvm_info(get_type_name(), {"req: ", t.convert2string()}, UVM_HIGH)
  endfunction

  function void write_axil(axil_item t);
    num_axil++;
    `uvm_info(get_type_name(), {"axil: ", t.convert2string()}, UVM_HIGH)
  endfunction

  function void write_cpl(tlp_cpl_item t);
    num_cpl++;
    `uvm_info(get_type_name(), {"cpl: ", t.convert2string()}, UVM_HIGH)
  endfunction

  function void report_phase(uvm_phase phase);
    `uvm_info(get_type_name(),
              $sformatf("received req=%0d axil=%0d cpl=%0d", num_req, num_axil, num_cpl),
              UVM_LOW)
  endfunction

endclass
