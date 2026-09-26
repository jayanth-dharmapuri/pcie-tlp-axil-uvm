// Agent-level sequences. Phase 3+ adds the real ones here (single MRd/MWr,
// BE sweep, bad-length, IO/Cfg, Message, back-to-back to fill the FIFO...).

class tlp_req_dummy_seq extends uvm_sequence #(tlp_req_item);
  `uvm_object_utils(tlp_req_dummy_seq)

  int unsigned num_items = 5;

  function new(string name = "tlp_req_dummy_seq");
    super.new(name);
  endfunction

  task body();
    repeat (num_items) begin
      req = tlp_req_item::type_id::create("req");
      start_item(req);
      if (!req.randomize())
        `uvm_error(get_type_name(), "randomize failed")
      finish_item(req);
    end
  endtask

endclass
