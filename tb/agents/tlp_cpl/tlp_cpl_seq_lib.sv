// Phase 3+: always-ready, random-duty, and long-stall sequences live here.
// The long-stall one is how we push the response FIFO to 16 and then 32.

class tlp_cpl_dummy_seq extends uvm_sequence #(tlp_cpl_item);
  `uvm_object_utils(tlp_cpl_dummy_seq)

  int unsigned num_items = 5;

  function new(string name = "tlp_cpl_dummy_seq");
    super.new(name);
  endfunction

  task body();
    repeat (num_items) begin
      req = tlp_cpl_item::type_id::create("req");
      start_item(req);
      if (!req.randomize())
        `uvm_error(get_type_name(), "randomize failed")
      finish_item(req);
    end
  endtask

endclass
