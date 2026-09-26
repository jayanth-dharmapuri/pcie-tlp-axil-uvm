// Phase 2 placeholder. The only field is how long the driver sits on the
// item, which is enough to prove sequence -> sequencer -> driver works.
// Phase 3 swaps this for the real request: fmt/type/length/first_be/addr/
// requester_id/tag/tc/attr + write data.
class tlp_req_item extends uvm_sequence_item;
  `uvm_object_utils(tlp_req_item)

  rand int unsigned idle_cycles;
  constraint c_idle { idle_cycles inside {[1:5]}; }

  function new(string name = "tlp_req_item");
    super.new(name);
  endfunction

  virtual function string convert2string();
    return $sformatf("idle_cycles=%0d", idle_cycles);
  endfunction

endclass
