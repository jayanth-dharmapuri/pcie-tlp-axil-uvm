// Phase 3 turns the body into the usual reactive-slave loop:
//   forever { p_sequencer.obs_req_fifo.get(obs); build response from obs; send it }
// p_sequencer is declared now so that loop has somewhere to go.

class axil_slave_dummy_seq extends uvm_sequence #(axil_item);
  `uvm_object_utils(axil_slave_dummy_seq)
  `uvm_declare_p_sequencer(axil_slave_sequencer)

  int unsigned num_items = 5;

  function new(string name = "axil_slave_dummy_seq");
    super.new(name);
  endfunction

  task body();
    repeat (num_items) begin
      req = axil_item::type_id::create("req");
      start_item(req);
      if (!req.randomize())
        `uvm_error(get_type_name(), "randomize failed")
      finish_item(req);
    end
  endtask

endclass
