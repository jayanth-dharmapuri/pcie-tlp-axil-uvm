// Connectivity smoke test. No real TLP goes in; this checks that:
//   - every vif made it from tb_top through config_db into its agent
//     (a miss would already have fataled in build)
//   - all three sequencer -> driver paths hand items across and finish
//   - the DUT comes out of reset and its outputs reach the monitors: ready
//     goes high, nothing is X/Z
//   - with no stimulus the DUT stays quiet: no AXI valids, no completions,
//     no error pulses
class dummy_test extends base_test;
  `uvm_component_utils(dummy_test)

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  task run_phase(uvm_phase phase);
    tlp_req_dummy_seq    req_seq;
    axil_slave_dummy_seq axil_seq;
    tlp_cpl_dummy_seq    cpl_seq;

    phase.raise_objection(this);

    reset_dut();

    req_seq  = tlp_req_dummy_seq::type_id::create("req_seq");
    axil_seq = axil_slave_dummy_seq::type_id::create("axil_seq");
    cpl_seq  = tlp_cpl_dummy_seq::type_id::create("cpl_seq");

    fork
      req_seq.start(m_env.m_req_agent.m_sqr);
      axil_seq.start(m_env.m_axil_agent.m_sqr);
      cpl_seq.start(m_env.m_cpl_agent.m_sqr);
    join

    wait_cycles(10);
    phase.drop_objection(this);
  endtask

  function void check_phase(uvm_phase phase);
    super.check_phase(phase);

    if (m_env.m_req_agent.m_mon.ready_cycles == 0)
      `uvm_error(get_type_name(), "rx_req_tlp_ready never went high after reset")

    if (m_env.m_axil_agent.m_mon.valid_cycles != 0)
      `uvm_error(get_type_name(), $sformatf("saw %0d AXI valid cycles with no stimulus",
                                            m_env.m_axil_agent.m_mon.valid_cycles))

    if (m_env.m_cpl_agent.m_mon.cpl_valid_cycles != 0)
      `uvm_error(get_type_name(), $sformatf("saw %0d completion valid cycles with no stimulus",
                                            m_env.m_cpl_agent.m_mon.cpl_valid_cycles))

    if (m_env.m_cpl_agent.m_mon.err_cor_pulses != 0 ||
        m_env.m_cpl_agent.m_mon.err_uncor_pulses != 0)
      `uvm_error(get_type_name(), "status_error pulse with no stimulus")

    `uvm_info(get_type_name(),
              $sformatf("ready_cycles=%0d -- connectivity OK if no errors above",
                        m_env.m_req_agent.m_mon.ready_cycles),
              UVM_LOW)
  endfunction

endclass
