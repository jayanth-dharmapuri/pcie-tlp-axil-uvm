// Phase 2 placeholder. Phase 3: is_write, addr, wdata/wstrb (observed from
// the DUT), rdata/resp (chosen by the slave sequence), plus ready/valid
// delay knobs for the slow-slave backpressure tests.
class axil_item extends uvm_sequence_item;
  `uvm_object_utils(axil_item)

  rand int unsigned idle_cycles;
  constraint c_idle { idle_cycles inside {[1:5]}; }

  function new(string name = "axil_item");
    super.new(name);
  endfunction

  virtual function string convert2string();
    return $sformatf("idle_cycles=%0d", idle_cycles);
  endfunction

endclass
