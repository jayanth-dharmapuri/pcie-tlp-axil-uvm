`timescale 1ns/1ps

module tb_top;

  import uvm_pkg::*;
  `include "uvm_macros.svh"
  import pcie_axil_params_pkg::*;
  // Imported so the tests get elaborated and registered with the factory;
  // some tools drop a package nothing references.
  import pcie_axil_test_pkg::*;

  clk_rst_if clk_rst ();

  tlp_req_if #(.DATA_W(TLP_DATA_WIDTH))  req_if  (.clk(clk_rst.clk), .rst(clk_rst.rst));
  axil_if    #(.ADDR_W(AXIL_ADDR_WIDTH)) axil_bus (.clk(clk_rst.clk), .rst(clk_rst.rst));
  tlp_cpl_if #(.DATA_W(TLP_DATA_WIDTH))  cpl_if  (.clk(clk_rst.clk), .rst(clk_rst.rst));

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
    run_test();   // pick the test with +UVM_TESTNAME=dummy_test
  end

`ifndef NO_WAVES
  initial begin
    $dumpfile("dump.vcd");
    $dumpvars(0, tb_top);
  end
`endif

endmodule
