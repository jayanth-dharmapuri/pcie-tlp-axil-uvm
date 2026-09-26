// Phase 2 placeholder, shared by driver and monitor for now.
// Phase 3 needs a call here: the driver wants a backpressure pattern
// (ready high/low for N cycles), the monitor produces a completion (status,
// byte_count, lower_addr, req_id, tag, tc, attr, data). Those may be better
// off as two separate classes.
class tlp_cpl_item extends uvm_sequence_item;
  `uvm_object_utils(tlp_cpl_item)

  rand int unsigned idle_cycles;
  constraint c_idle { idle_cycles inside {[1:5]}; }

  function new(string name = "tlp_cpl_item");
    super.new(name);
  endfunction

  virtual function string convert2string();
    return $sformatf("idle_cycles=%0d", idle_cycles);
  endfunction

endclass
