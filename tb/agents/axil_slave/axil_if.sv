`timescale 1ns/1ps

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
