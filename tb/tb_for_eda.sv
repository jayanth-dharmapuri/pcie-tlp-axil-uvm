// Code your testbench here
// or browse Examples
// ======================= pcie_axil_params_pkg.sv =======================
`timescale 1ns/1ps

// One place for every width the TB and the DUT instance agree on.
// TLP_DATA_WIDTH is the only one we sweep; override at compile time with
// +define+TB_TLP_DATA_WIDTH=256. Everything else is pinned by the DUT's own
// initial-block checks (SEG_COUNT=1, HDR=128, AXIL data=32).
`ifndef TB_TLP_DATA_WIDTH
  `define TB_TLP_DATA_WIDTH 64
`endif

package pcie_axil_params_pkg;

  localparam int TLP_DATA_WIDTH  = `TB_TLP_DATA_WIDTH;
  localparam int TLP_STRB_WIDTH  = TLP_DATA_WIDTH / 32;
  localparam int TLP_HDR_WIDTH   = 128;
  localparam int TLP_SEG_COUNT   = 1;

  localparam int AXIL_DATA_WIDTH = 32;
  // 64 (the DUT default), not 32 like the smoke TB -- with 32 the upper
  // address bits of a 4DW request get truncated and the 3DW-vs-4DW tests
  // can't see them.
  localparam int AXIL_ADDR_WIDTH = 64;
  localparam int AXIL_STRB_WIDTH = AXIL_DATA_WIDTH / 8;

  // Tied to the DUT's completer_id input in tb_top; the scoreboard will
  // read the same constant when it checks completion headers.
  localparam logic [15:0] COMPLETER_ID = 16'h0100;

endpackage

// ======================= clk_rst_if.sv =======================
// Clock and reset live here, not in tb_top, so the test can grab this
// interface and pulse reset whenever it wants (reset-mid-transaction test).
// DUT reset is active-high and synchronous.
interface clk_rst_if;

  logic clk = 1'b0;
  logic rst = 1'b1;       // held in reset from time 0 until the test releases it
  logic rst_req = 1'b1;

  always #5 clk = ~clk;   // 100 MHz

  // The test only touches rst_req; rst itself is only ever written here.
  // Under Verilator 5.046, rst didn't propagate to the other interfaces' rst ports
  // when a class wrote it directly through the vif. Registering it here also
  // keeps every reset edge lined up with a clock edge.
  always @(posedge clk) rst <= rst_req;

  // Nonblocking so the always block above sees a clean value at the edge the
  // task writes on, instead of racing it.
  task automatic apply_reset(int unsigned cycles = 5);
    rst_req <= 1'b1;
    repeat (cycles) @(posedge clk);
    rst_req <= 1'b0;
    @(posedge clk);   // return once rst has actually dropped
  endtask

endinterface

// ======================= tlp_req_if.sv =======================
// Request side of the DUT: rx_req_tlp_* (TB drives, DUT sinks).
// Signal names match the DUT ports exactly so tb_top is a straight 1:1 hookup.
// TLP_SEG_COUNT is fixed at 1 by the DUT, so valid/sop/eop are single bits.
interface tlp_req_if #(parameter int DATA_W = 64) (input logic clk, input logic rst);

  logic [DATA_W-1:0] rx_req_tlp_data;
  logic [127:0]      rx_req_tlp_hdr;
  logic              rx_req_tlp_valid;
  logic              rx_req_tlp_sop;
  logic              rx_req_tlp_eop;
  logic              rx_req_tlp_ready;

  clocking drv_cb @(posedge clk);
    default input #1step output #1;
    output rx_req_tlp_data, rx_req_tlp_hdr, rx_req_tlp_valid,
           rx_req_tlp_sop, rx_req_tlp_eop;
    input  rx_req_tlp_ready;
  endclocking

  clocking mon_cb @(posedge clk);
    default input #1step;
    input rst, rx_req_tlp_data, rx_req_tlp_hdr, rx_req_tlp_valid,
          rx_req_tlp_sop, rx_req_tlp_eop, rx_req_tlp_ready;
  endclocking

endinterface

// ======================= axil_if.sv =======================
// AXI4-Lite between the DUT (master) and our slave agent. Names keep the
// DUT's m_axil_ prefix on purpose -- easier to eyeball against the RTL than
// a renamed generic AXI interface.
// awprot/arprot are hardwired to 3'b010 inside the DUT; still carried here
// so the monitor can check them.
interface axil_if #(parameter int ADDR_W = 64) (input logic clk, input logic rst);

  // write address
  logic [ADDR_W-1:0] m_axil_awaddr;
  logic [2:0]        m_axil_awprot;
  logic              m_axil_awvalid;
  logic              m_axil_awready;
  // write data
  logic [31:0]       m_axil_wdata;
  logic [3:0]        m_axil_wstrb;
  logic              m_axil_wvalid;
  logic              m_axil_wready;
  // write response
  logic [1:0]        m_axil_bresp;
  logic              m_axil_bvalid;
  logic              m_axil_bready;
  // read address
  logic [ADDR_W-1:0] m_axil_araddr;
  logic [2:0]        m_axil_arprot;
  logic              m_axil_arvalid;
  logic              m_axil_arready;
  // read data
  logic [31:0]       m_axil_rdata;
  logic [1:0]        m_axil_rresp;
  logic              m_axil_rvalid;
  logic              m_axil_rready;

  // slave side: we drive the readys and the B/R channels
  clocking drv_cb @(posedge clk);
    default input #1step output #1;
    output m_axil_awready, m_axil_wready,
           m_axil_bresp, m_axil_bvalid,
           m_axil_arready,
           m_axil_rdata, m_axil_rresp, m_axil_rvalid;
    input  m_axil_awaddr, m_axil_awprot, m_axil_awvalid,
           m_axil_wdata, m_axil_wstrb, m_axil_wvalid,
           m_axil_bready,
           m_axil_araddr, m_axil_arprot, m_axil_arvalid,
           m_axil_rready;
  endclocking

  clocking mon_cb @(posedge clk);
    default input #1step;
    input rst, m_axil_awaddr, m_axil_awprot, m_axil_awvalid, m_axil_awready,
          m_axil_wdata, m_axil_wstrb, m_axil_wvalid, m_axil_wready,
          m_axil_bresp, m_axil_bvalid, m_axil_bready,
          m_axil_araddr, m_axil_arprot, m_axil_arvalid, m_axil_arready,
          m_axil_rdata, m_axil_rresp, m_axil_rvalid, m_axil_rready;
  endclocking

endinterface

// ======================= tlp_cpl_if.sv =======================
// Completion side of the DUT: tx_cpl_tlp_* (DUT drives, TB sinks) plus the
// sideband signals that don't belong to either stream on their own:
//   completer_id        -- DUT input, tied to a constant in tb_top
//   status_error_cor/   -- DUT outputs, 1-cycle pulses. They ride along here
//   status_error_uncor     so the scoreboard sees them next to completions.
// tx_cpl_tlp_sop/eop are hardwired to 1 in the DUT (single-beat completions).
interface tlp_cpl_if #(parameter int DATA_W = 64) (input logic clk, input logic rst);

  localparam int STRB_W = DATA_W / 32;

  logic [DATA_W-1:0] tx_cpl_tlp_data;
  logic [STRB_W-1:0] tx_cpl_tlp_strb;
  logic [127:0]      tx_cpl_tlp_hdr;
  logic              tx_cpl_tlp_valid;
  logic              tx_cpl_tlp_sop;
  logic              tx_cpl_tlp_eop;
  logic              tx_cpl_tlp_ready;

  logic [15:0]       completer_id;
  logic              status_error_cor;
  logic              status_error_uncor;

  // the only thing the cpl driver owns is ready (backpressure)
  clocking drv_cb @(posedge clk);
    default input #1step output #1;
    output tx_cpl_tlp_ready;
    input  tx_cpl_tlp_valid;
  endclocking

  clocking mon_cb @(posedge clk);
    default input #1step;
    input rst, tx_cpl_tlp_data, tx_cpl_tlp_strb, tx_cpl_tlp_hdr,
          tx_cpl_tlp_valid, tx_cpl_tlp_sop, tx_cpl_tlp_eop, tx_cpl_tlp_ready,
          status_error_cor, status_error_uncor;
  endclocking

endinterface

// ======================= tlp_req_pkg.sv =======================
package tlp_req_pkg;

  import uvm_pkg::*;
  `include "uvm_macros.svh"
  import pcie_axil_params_pkg::*;

  // Pin the interface specialization once; every class uses this typedef so
  // a width change can't leave one component pointing at a different type.
  typedef virtual tlp_req_if #(.DATA_W(TLP_DATA_WIDTH)) tlp_req_vif_t;

  // ---- tlp_req_item.sv ----
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

  // ---- tlp_req_agent_cfg.sv ----
  class tlp_req_agent_cfg extends uvm_object;
    `uvm_object_utils(tlp_req_agent_cfg)

    tlp_req_vif_t           vif;
    uvm_active_passive_enum is_active = UVM_ACTIVE;

    function new(string name = "tlp_req_agent_cfg");
      super.new(name);
    endfunction

  endclass

  typedef uvm_sequencer #(tlp_req_item) tlp_req_sequencer;

  // ---- tlp_req_driver.sv ----
  class tlp_req_driver extends uvm_driver #(tlp_req_item);
    `uvm_component_utils(tlp_req_driver)

    tlp_req_vif_t vif;   // set by the agent in connect_phase

    function new(string name, uvm_component parent);
      super.new(name, parent);
    endfunction

    task run_phase(uvm_phase phase);
      drive_idle();
      wait (vif.rst === 1'b0);

      forever begin
        seq_item_port.get_next_item(req);
        `uvm_info(get_type_name(), {"got ", req.convert2string()}, UVM_HIGH)
        // TODO(phase3): put hdr/data on the bus with valid/sop/eop, hold until
        // rx_req_tlp_ready, then drop valid. For now just burn the idle time.
        repeat (req.idle_cycles) @(vif.drv_cb);
        seq_item_port.item_done();
      end
    endtask

    // Direct assignment, not through drv_cb: this runs at time 0 before the
    // first clock edge, and a clocking-block drive wouldn't land until then.
    task drive_idle();
      vif.rx_req_tlp_valid <= 1'b0;
      vif.rx_req_tlp_sop   <= 1'b0;
      vif.rx_req_tlp_eop   <= 1'b0;
      vif.rx_req_tlp_hdr   <= '0;
      vif.rx_req_tlp_data  <= '0;
    endtask

  endclass

  // ---- tlp_req_monitor.sv ----
  class tlp_req_monitor extends uvm_monitor;
    `uvm_component_utils(tlp_req_monitor)

    tlp_req_vif_t vif;
    uvm_analysis_port #(tlp_req_item) ap;

    // Skeleton-only: counts cycles the DUT's ready was high out of reset.
    // Non-zero proves rx_req_tlp_ready makes it from the DUT back to the TB.
    int unsigned ready_cycles;

    function new(string name, uvm_component parent);
      super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      ap = new("ap", this);
    endfunction

    task run_phase(uvm_phase phase);
      forever begin
        @(vif.mon_cb);
        if (vif.mon_cb.rst) continue;

        if ($isunknown(vif.mon_cb.rx_req_tlp_ready))
          `uvm_error(get_type_name(), "rx_req_tlp_ready is X/Z out of reset -- check the tb_top hookup")
        else if (vif.mon_cb.rx_req_tlp_ready)
          ready_cycles++;

        // TODO(phase3): on valid && ready && sop, capture hdr/data into a
        // tlp_req_item and ap.write() it.
      end
    endtask

  endclass

  // ---- tlp_req_agent.sv ----
  class tlp_req_agent extends uvm_agent;
    `uvm_component_utils(tlp_req_agent)

    tlp_req_agent_cfg m_cfg;
    tlp_req_sequencer m_sqr;
    tlp_req_driver    m_drv;
    tlp_req_monitor   m_mon;

    uvm_analysis_port #(tlp_req_item) ap;   // re-exports the monitor's port

    function new(string name, uvm_component parent);
      super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      if (!uvm_config_db #(tlp_req_agent_cfg)::get(this, "", "cfg", m_cfg))
        `uvm_fatal(get_type_name(), "no tlp_req_agent_cfg in config_db")
      if (m_cfg.vif == null)
        `uvm_fatal(get_type_name(), "tlp_req_agent_cfg.vif is null")

      ap    = new("ap", this);
      m_mon = tlp_req_monitor::type_id::create("m_mon", this);
      if (m_cfg.is_active == UVM_ACTIVE) begin
        m_sqr = tlp_req_sequencer::type_id::create("m_sqr", this);
        m_drv = tlp_req_driver::type_id::create("m_drv", this);
      end
    endfunction

    function void connect_phase(uvm_phase phase);
      m_mon.vif = m_cfg.vif;
      m_mon.ap.connect(ap);
      if (m_cfg.is_active == UVM_ACTIVE) begin
        m_drv.vif = m_cfg.vif;
        m_drv.seq_item_port.connect(m_sqr.seq_item_export);
      end
    endfunction

  endclass

  // ---- tlp_req_seq_lib.sv ----
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

endpackage

// ======================= axil_slave_pkg.sv =======================
package axil_slave_pkg;

  import uvm_pkg::*;
  `include "uvm_macros.svh"
  import pcie_axil_params_pkg::*;

  typedef virtual axil_if #(.ADDR_W(AXIL_ADDR_WIDTH)) axil_vif_t;

  // ---- axil_item.sv ----
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

  // ---- axil_slave_agent_cfg.sv ----
  class axil_slave_agent_cfg extends uvm_object;
    `uvm_object_utils(axil_slave_agent_cfg)

    axil_vif_t              vif;
    uvm_active_passive_enum is_active = UVM_ACTIVE;

    function new(string name = "axil_slave_agent_cfg");
      super.new(name);
    endfunction

  endclass

  // ---- axil_slave_sequencer.sv ----
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

  // ---- axil_slave_driver.sv ----
  class axil_slave_driver extends uvm_driver #(axil_item);
    `uvm_component_utils(axil_slave_driver)

    axil_vif_t vif;

    function new(string name, uvm_component parent);
      super.new(name, parent);
    endfunction

    task run_phase(uvm_phase phase);
      drive_idle();
      wait (vif.rst === 1'b0);

      forever begin
        seq_item_port.get_next_item(req);
        `uvm_info(get_type_name(), {"got ", req.convert2string()}, UVM_HIGH)
        // TODO(phase3): accept AW+W / AR (with the item's ready delays), then
        // drive B or R with the item's resp/rdata.
        repeat (req.idle_cycles) @(vif.drv_cb);
        seq_item_port.item_done();
      end
    endtask

    // readys low while idle is safe for the skeleton since the DUT never
    // issues anything. Phase 3 decides whether the default slave is
    // always-ready or waits to be told.
    task drive_idle();
      vif.m_axil_awready <= 1'b0;
      vif.m_axil_wready  <= 1'b0;
      vif.m_axil_arready <= 1'b0;
      vif.m_axil_bvalid  <= 1'b0;
      vif.m_axil_bresp   <= 2'b00;
      vif.m_axil_rvalid  <= 1'b0;
      vif.m_axil_rresp   <= 2'b00;
      vif.m_axil_rdata   <= '0;
    endtask

  endclass

  // ---- axil_monitor.sv ----
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

  // ---- axil_slave_agent.sv ----
  class axil_slave_agent extends uvm_agent;
    `uvm_component_utils(axil_slave_agent)

    axil_slave_agent_cfg m_cfg;
    axil_slave_sequencer m_sqr;
    axil_slave_driver    m_drv;
    axil_monitor         m_mon;

    uvm_analysis_port #(axil_item) ap;

    function new(string name, uvm_component parent);
      super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      if (!uvm_config_db #(axil_slave_agent_cfg)::get(this, "", "cfg", m_cfg))
        `uvm_fatal(get_type_name(), "no axil_slave_agent_cfg in config_db")
      if (m_cfg.vif == null)
        `uvm_fatal(get_type_name(), "axil_slave_agent_cfg.vif is null")

      ap    = new("ap", this);
      m_mon = axil_monitor::type_id::create("m_mon", this);
      if (m_cfg.is_active == UVM_ACTIVE) begin
        m_sqr = axil_slave_sequencer::type_id::create("m_sqr", this);
        m_drv = axil_slave_driver::type_id::create("m_drv", this);
      end
    endfunction

    function void connect_phase(uvm_phase phase);
      m_mon.vif = m_cfg.vif;
      m_mon.ap.connect(ap);
      if (m_cfg.is_active == UVM_ACTIVE) begin
        m_drv.vif = m_cfg.vif;
        m_drv.seq_item_port.connect(m_sqr.seq_item_export);
        m_mon.req_ap.connect(m_sqr.obs_req_fifo.analysis_export);
      end
    endfunction

  endclass

  // ---- axil_slave_seq_lib.sv ----
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

endpackage

// ======================= tlp_cpl_pkg.sv =======================
package tlp_cpl_pkg;

  import uvm_pkg::*;
  `include "uvm_macros.svh"
  import pcie_axil_params_pkg::*;

  typedef virtual tlp_cpl_if #(.DATA_W(TLP_DATA_WIDTH)) tlp_cpl_vif_t;

  // ---- tlp_cpl_item.sv ----
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

  // ---- tlp_cpl_agent_cfg.sv ----
  class tlp_cpl_agent_cfg extends uvm_object;
    `uvm_object_utils(tlp_cpl_agent_cfg)

    tlp_cpl_vif_t           vif;
    // ACTIVE = our driver owns tx_cpl_tlp_ready. If a test ever runs this
    // PASSIVE, nothing drives ready, so tb_top would need to tie it.
    uvm_active_passive_enum is_active = UVM_ACTIVE;

    function new(string name = "tlp_cpl_agent_cfg");
      super.new(name);
    endfunction

  endclass

  typedef uvm_sequencer #(tlp_cpl_item) tlp_cpl_sequencer;

  // ---- tlp_cpl_driver.sv ----
  // Drives exactly one signal: tx_cpl_tlp_ready. Everything else on this
  // interface belongs to the DUT.
  class tlp_cpl_driver extends uvm_driver #(tlp_cpl_item);
    `uvm_component_utils(tlp_cpl_driver)

    tlp_cpl_vif_t vif;

    function new(string name, uvm_component parent);
      super.new(name, parent);
    endfunction

    task run_phase(uvm_phase phase);
      drive_idle();
      wait (vif.rst === 1'b0);

      forever begin
        seq_item_port.get_next_item(req);
        `uvm_info(get_type_name(), {"got ", req.convert2string()}, UVM_HIGH)
        // TODO(phase3): apply the item's ready pattern (stall N / random duty).
        repeat (req.idle_cycles) @(vif.drv_cb);
        seq_item_port.item_done();
      end
    endtask

    // Idle = always-ready sink, so completions never get stuck just because
    // no backpressure sequence happens to be running.
    task drive_idle();
      vif.tx_cpl_tlp_ready <= 1'b1;
    endtask

  endclass

  // ---- tlp_cpl_monitor.sv ----
  class tlp_cpl_monitor extends uvm_monitor;
    `uvm_component_utils(tlp_cpl_monitor)

    tlp_cpl_vif_t vif;
    uvm_analysis_port #(tlp_cpl_item) ap;

    // Skeleton-only counters. With no stimulus all three should stay at 0.
    int unsigned cpl_valid_cycles;
    int unsigned err_cor_pulses;
    int unsigned err_uncor_pulses;

    function new(string name, uvm_component parent);
      super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      ap = new("ap", this);
    endfunction

    task run_phase(uvm_phase phase);
      forever begin
        @(vif.mon_cb);
        if (vif.mon_cb.rst) continue;

        if ($isunknown({vif.mon_cb.tx_cpl_tlp_valid,
                        vif.mon_cb.status_error_cor,
                        vif.mon_cb.status_error_uncor}))
          `uvm_error(get_type_name(), "DUT completion/status output is X/Z out of reset -- check the tb_top hookup")
        else begin
          if (vif.mon_cb.tx_cpl_tlp_valid)   cpl_valid_cycles++;
          if (vif.mon_cb.status_error_cor)   err_cor_pulses++;
          if (vif.mon_cb.status_error_uncor) err_uncor_pulses++;
        end

        // TODO(phase3): on valid && ready, unpack hdr/data into an item and
        // ap.write() it. Also decide how the status_error pulses reach the
        // scoreboard: a field on the item, or their own analysis port. They
        // don't line up 1:1 with completions (a dropped MWr pulses uncor with
        // no completion at all).
      end
    endtask

  endclass

  // ---- tlp_cpl_agent.sv ----
  class tlp_cpl_agent extends uvm_agent;
    `uvm_component_utils(tlp_cpl_agent)

    tlp_cpl_agent_cfg m_cfg;
    tlp_cpl_sequencer m_sqr;
    tlp_cpl_driver    m_drv;
    tlp_cpl_monitor   m_mon;

    uvm_analysis_port #(tlp_cpl_item) ap;

    function new(string name, uvm_component parent);
      super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      if (!uvm_config_db #(tlp_cpl_agent_cfg)::get(this, "", "cfg", m_cfg))
        `uvm_fatal(get_type_name(), "no tlp_cpl_agent_cfg in config_db")
      if (m_cfg.vif == null)
        `uvm_fatal(get_type_name(), "tlp_cpl_agent_cfg.vif is null")

      ap    = new("ap", this);
      m_mon = tlp_cpl_monitor::type_id::create("m_mon", this);
      if (m_cfg.is_active == UVM_ACTIVE) begin
        m_sqr = tlp_cpl_sequencer::type_id::create("m_sqr", this);
        m_drv = tlp_cpl_driver::type_id::create("m_drv", this);
      end
    endfunction

    function void connect_phase(uvm_phase phase);
      m_mon.vif = m_cfg.vif;
      m_mon.ap.connect(ap);
      if (m_cfg.is_active == UVM_ACTIVE) begin
        m_drv.vif = m_cfg.vif;
        m_drv.seq_item_port.connect(m_sqr.seq_item_export);
      end
    endfunction

  endclass

  // ---- tlp_cpl_seq_lib.sv ----
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

endpackage

// ======================= pcie_axil_env_pkg.sv =======================
package pcie_axil_env_pkg;

  import uvm_pkg::*;
  `include "uvm_macros.svh"
  import pcie_axil_params_pkg::*;
  import tlp_req_pkg::*;
  import axil_slave_pkg::*;
  import tlp_cpl_pkg::*;

  // One write_*() per incoming stream on the scoreboard. These macros have to
  // sit at package scope, outside any class.
  `uvm_analysis_imp_decl(_req)
  `uvm_analysis_imp_decl(_axil)
  `uvm_analysis_imp_decl(_cpl)

  // ---- pcie_axil_env_cfg.sv ----
  // The test fills this in (vifs, active/passive, knobs) and hands it to the
  // env; the env hands each agent its own sub-config. No component below the
  // test ever touches config_db for a virtual interface.
  class pcie_axil_env_cfg extends uvm_object;
    `uvm_object_utils(pcie_axil_env_cfg)

    tlp_req_agent_cfg    req_cfg;
    axil_slave_agent_cfg axil_cfg;
    tlp_cpl_agent_cfg    cpl_cfg;

    bit has_scoreboard = 1;

    function new(string name = "pcie_axil_env_cfg");
      super.new(name);
      req_cfg  = tlp_req_agent_cfg::type_id::create("req_cfg");
      axil_cfg = axil_slave_agent_cfg::type_id::create("axil_cfg");
      cpl_cfg  = tlp_cpl_agent_cfg::type_id::create("cpl_cfg");
    endfunction

  endclass

  // ---- pcie_axil_scoreboard.sv ----
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

  // ---- pcie_axil_env.sv ----
  // Phase 5 adds a coverage subscriber next to the scoreboard, fed from the
  // same three agent ports.
  class pcie_axil_env extends uvm_env;
    `uvm_component_utils(pcie_axil_env)

    pcie_axil_env_cfg    m_cfg;
    tlp_req_agent        m_req_agent;
    axil_slave_agent     m_axil_agent;
    tlp_cpl_agent        m_cpl_agent;
    pcie_axil_scoreboard m_scb;

    function new(string name, uvm_component parent);
      super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      if (!uvm_config_db #(pcie_axil_env_cfg)::get(this, "", "cfg", m_cfg))
        `uvm_fatal(get_type_name(), "no pcie_axil_env_cfg in config_db")

      // Scoped to each agent's instance name so no agent picks up another's.
      uvm_config_db #(tlp_req_agent_cfg)::set(this, "m_req_agent", "cfg", m_cfg.req_cfg);
      uvm_config_db #(axil_slave_agent_cfg)::set(this, "m_axil_agent", "cfg", m_cfg.axil_cfg);
      uvm_config_db #(tlp_cpl_agent_cfg)::set(this, "m_cpl_agent", "cfg", m_cfg.cpl_cfg);

      m_req_agent  = tlp_req_agent::type_id::create("m_req_agent", this);
      m_axil_agent = axil_slave_agent::type_id::create("m_axil_agent", this);
      m_cpl_agent  = tlp_cpl_agent::type_id::create("m_cpl_agent", this);

      if (m_cfg.has_scoreboard)
        m_scb = pcie_axil_scoreboard::type_id::create("m_scb", this);
    endfunction

    function void connect_phase(uvm_phase phase);
      if (m_cfg.has_scoreboard) begin
        m_req_agent.ap.connect(m_scb.req_imp);
        m_axil_agent.ap.connect(m_scb.axil_imp);
        m_cpl_agent.ap.connect(m_scb.cpl_imp);
      end
    endfunction

  endclass

endpackage

// ======================= pcie_axil_test_pkg.sv =======================
package pcie_axil_test_pkg;

  import uvm_pkg::*;
  `include "uvm_macros.svh"
  import pcie_axil_params_pkg::*;
  import tlp_req_pkg::*;
  import axil_slave_pkg::*;
  import tlp_cpl_pkg::*;
  import pcie_axil_env_pkg::*;

  // ---- base_test.sv ----
  // Every test extends this. It is the only place that reads virtual
  // interfaces out of config_db (tb_top put them there); from here they flow
  // down inside cfg objects.
  class base_test extends uvm_test;
    `uvm_component_utils(base_test)

    pcie_axil_env      m_env;
    pcie_axil_env_cfg  m_cfg;
    virtual clk_rst_if m_clk_rst_vif;

    function new(string name, uvm_component parent);
      super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      m_cfg = pcie_axil_env_cfg::type_id::create("m_cfg");

      if (!uvm_config_db #(virtual clk_rst_if)::get(this, "", "clk_rst_vif", m_clk_rst_vif))
        `uvm_fatal(get_type_name(), "clk_rst_vif not found in config_db")
      if (!uvm_config_db #(tlp_req_vif_t)::get(this, "", "req_vif", m_cfg.req_cfg.vif))
        `uvm_fatal(get_type_name(), "req_vif not found in config_db")
      if (!uvm_config_db #(axil_vif_t)::get(this, "", "axil_vif", m_cfg.axil_cfg.vif))
        `uvm_fatal(get_type_name(), "axil_vif not found in config_db")
      if (!uvm_config_db #(tlp_cpl_vif_t)::get(this, "", "cpl_vif", m_cfg.cpl_cfg.vif))
        `uvm_fatal(get_type_name(), "cpl_vif not found in config_db")

      // Derived tests change knobs on m_cfg after super.build_phase() and
      // before the env builds (the env reads m_cfg in its own build_phase,
      // which runs after this one).
      uvm_config_db #(pcie_axil_env_cfg)::set(this, "m_env", "cfg", m_cfg);
      m_env = pcie_axil_env::type_id::create("m_env", this);

      // Stops a hung test from running forever: a missing ready or a
      // sequence that never finishes.
      uvm_root::get().set_timeout(100us, 1);
    endfunction

    function void end_of_elaboration_phase(uvm_phase phase);
      uvm_root::get().print_topology();
    endfunction

    task reset_dut(int unsigned cycles = 5);
      m_clk_rst_vif.apply_reset(cycles);
    endtask

    task wait_cycles(int unsigned n);
      repeat (n) @(posedge m_clk_rst_vif.clk);
    endtask

  endclass

  // ---- dummy_test.sv ----
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

endpackage

// ======================= tb_top.sv =======================
module tb_top;

  import uvm_pkg::*;
  `include "uvm_macros.svh"
  import pcie_axil_params_pkg::*;
  // Imported so the tests get elaborated and registered with the factory;
  // some tools drop a package nothing references.
  import pcie_axil_test_pkg::*;

  clk_rst_if clk_rst ();

  tlp_req_if #(.DATA_W(TLP_DATA_WIDTH))  req_if   (.clk(clk_rst.clk), .rst(clk_rst.rst));
  axil_if    #(.ADDR_W(AXIL_ADDR_WIDTH)) axil_bus (.clk(clk_rst.clk), .rst(clk_rst.rst));
  tlp_cpl_if #(.DATA_W(TLP_DATA_WIDTH))  cpl_if   (.clk(clk_rst.clk), .rst(clk_rst.rst));

  assign cpl_if.completer_id = COMPLETER_ID;

  pcie_axil_master_minimal #(
    .TLP_DATA_WIDTH        (TLP_DATA_WIDTH),
    .TLP_STRB_WIDTH        (TLP_STRB_WIDTH),
    .TLP_HDR_WIDTH         (TLP_HDR_WIDTH),
    .TLP_SEG_COUNT         (TLP_SEG_COUNT),
    .AXIL_DATA_WIDTH       (AXIL_DATA_WIDTH),
    .AXIL_ADDR_WIDTH       (AXIL_ADDR_WIDTH),
    .AXIL_STRB_WIDTH       (AXIL_STRB_WIDTH),
    .TLP_FORCE_64_BIT_ADDR (0)
  ) dut (
    .clk                (clk_rst.clk),
    .rst                (clk_rst.rst),

    .rx_req_tlp_data    (req_if.rx_req_tlp_data),
    .rx_req_tlp_hdr     (req_if.rx_req_tlp_hdr),
    .rx_req_tlp_valid   (req_if.rx_req_tlp_valid),
    .rx_req_tlp_sop     (req_if.rx_req_tlp_sop),
    .rx_req_tlp_eop     (req_if.rx_req_tlp_eop),
    .rx_req_tlp_ready   (req_if.rx_req_tlp_ready),

    .tx_cpl_tlp_data    (cpl_if.tx_cpl_tlp_data),
    .tx_cpl_tlp_strb    (cpl_if.tx_cpl_tlp_strb),
    .tx_cpl_tlp_hdr     (cpl_if.tx_cpl_tlp_hdr),
    .tx_cpl_tlp_valid   (cpl_if.tx_cpl_tlp_valid),
    .tx_cpl_tlp_sop     (cpl_if.tx_cpl_tlp_sop),
    .tx_cpl_tlp_eop     (cpl_if.tx_cpl_tlp_eop),
    .tx_cpl_tlp_ready   (cpl_if.tx_cpl_tlp_ready),

    .m_axil_awaddr      (axil_bus.m_axil_awaddr),
    .m_axil_awprot      (axil_bus.m_axil_awprot),
    .m_axil_awvalid     (axil_bus.m_axil_awvalid),
    .m_axil_awready     (axil_bus.m_axil_awready),
    .m_axil_wdata       (axil_bus.m_axil_wdata),
    .m_axil_wstrb       (axil_bus.m_axil_wstrb),
    .m_axil_wvalid      (axil_bus.m_axil_wvalid),
    .m_axil_wready      (axil_bus.m_axil_wready),
    .m_axil_bresp       (axil_bus.m_axil_bresp),
    .m_axil_bvalid      (axil_bus.m_axil_bvalid),
    .m_axil_bready      (axil_bus.m_axil_bready),
    .m_axil_araddr      (axil_bus.m_axil_araddr),
    .m_axil_arprot      (axil_bus.m_axil_arprot),
    .m_axil_arvalid     (axil_bus.m_axil_arvalid),
    .m_axil_arready     (axil_bus.m_axil_arready),
    .m_axil_rdata       (axil_bus.m_axil_rdata),
    .m_axil_rresp       (axil_bus.m_axil_rresp),
    .m_axil_rvalid      (axil_bus.m_axil_rvalid),
    .m_axil_rready      (axil_bus.m_axil_rready),

    .completer_id       (cpl_if.completer_id),
    .status_error_cor   (cpl_if.status_error_cor),
    .status_error_uncor (cpl_if.status_error_uncor)
  );

  initial begin
    // Scoped to uvm_test_top: only the test reads these. Keeps the rest of
    // the hierarchy from quietly grabbing a vif on its own.
    uvm_config_db #(virtual clk_rst_if)::set(null, "uvm_test_top", "clk_rst_vif", clk_rst);
    uvm_config_db #(tlp_req_pkg::tlp_req_vif_t)::set(null, "uvm_test_top", "req_vif", req_if);
    uvm_config_db #(axil_slave_pkg::axil_vif_t)::set(null, "uvm_test_top", "axil_vif", axil_bus);
    uvm_config_db #(tlp_cpl_pkg::tlp_cpl_vif_t)::set(null, "uvm_test_top", "cpl_vif", cpl_if);
    // dummy_test is the default; +UVM_TESTNAME=<name> still overrides it
    run_test("dummy_test");
  end

`ifndef NO_WAVES
  initial begin
    $dumpfile("dump.vcd");
    $dumpvars(0, tb_top);
  end
`endif

endmodule
