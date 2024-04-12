// Verible directive
// verilog_lint: waive-start parameter-name-style
// verilog_lint: waive-start line-length

`include "../axi4_lite_if.svh"

`default_nettype none

//! demonstration using AXI Verification IP without Vivado project
module test_bench;

timeunit 1ns;
timeprecision 1ps;

// ---------- parameters ----------
localparam int CLK_PERIOD_NS = 8; //! clock period in ns
localparam int SIM_TIME_LIMIT_NS = 500; //! simulation time limit in ns
//! Reset signal deasserts right after this clock rising-edge.
//! 'Holding AXI ARESETN asserted for 16 cycles of the slowest AXI clock is generally a sufficient reset pulse width for Xilinx IP. --UG1037.' (AXI VIP message)
localparam int RELEASE_RST_AFTER_CLK = 20;

localparam int AXI4_LITE_ADDR_BIT_WIDTH = 32; //! bit width of AXI4-Lite address bus
localparam int AXI4_LITE_DATA_BIT_WIDTH = 32; //! bit width of AXI4-Lite data bus
// --------------------

// ---------- internal signal and storage ----------
var bit r_clk; //! clock signal
var bit r_sync_rst; //! clock synchronous reset signal

// interface instance
axi4_lite_if axi4_lite_if__vip_dut (); // interface between AXI4 VIP and DUT

// AXI4-Lite signals
typedef struct {
    logic [AXI4_LITE_ADDR_BIT_WIDTH-1:0] awaddr;
    logic [2:0] awprot;
    logic awvalid;
    logic awready;
    logic [AXI4_LITE_DATA_BIT_WIDTH-1:0] wdata;
    logic [(AXI4_LITE_DATA_BIT_WIDTH/8)-1:0] wstrb;
    logic wvalid;
    logic wready;
    logic [1:0] bresp;
    logic bvalid;
    logic bready;
    logic [AXI4_LITE_ADDR_BIT_WIDTH-1:0] araddr;
    logic [2:0] arprot;
    logic arvalid;
    logic arready;
    logic [AXI4_LITE_DATA_BIT_WIDTH-1:0] rdata;
    logic [1:0] rresp;
    logic rvalid;
    logic rready;
} axi4_lite_sigs_t;

// AXI4-Lite master output signals
typedef struct {
    logic [AXI4_LITE_ADDR_BIT_WIDTH-1:0] awaddr;
    logic [2:0] awprot;
    logic awvalid;
    //logic awready;
    logic [AXI4_LITE_DATA_BIT_WIDTH-1:0] wdata;
    logic [(AXI4_LITE_DATA_BIT_WIDTH/8)-1:0] wstrb;
    logic wvalid;
    //logic wready;
    //logic [1:0] bresp;
    //logic bvalid;
    logic bready;
    logic [AXI4_LITE_ADDR_BIT_WIDTH-1:0] araddr;
    logic [2:0] arprot;
    logic arvalid;
    //logic arready;
    //logic [AXI4_LITE_DATA_BIT_WIDTH-1:0] rdata;
    //logic [1:0] rresp;
    //logic rvalid;
    logic rready;
} axi4_lite_mst_out_sigs_t;

wire axi4_lite_sigs_t w_vip_slv_port_sigs; //! AXI4 VIP slave port signals
var axi4_lite_sigs_t g_vip_slv_port_mon_sigs; //! AXI4 VIP slave port monitor signals
var axi4_lite_mst_out_sigs_t r_axi4_vip_slv_port_drv_sigs; //! signals to drive AXI4 VIP slave port

assign w_vip_slv_port_sigs.awaddr = r_axi4_vip_slv_port_drv_sigs.awaddr;
assign w_vip_slv_port_sigs.awprot = r_axi4_vip_slv_port_drv_sigs.awprot;
assign w_vip_slv_port_sigs.awvalid = r_axi4_vip_slv_port_drv_sigs.awvalid;
assign w_vip_slv_port_sigs.wdata = r_axi4_vip_slv_port_drv_sigs.wdata;
assign w_vip_slv_port_sigs.wstrb = r_axi4_vip_slv_port_drv_sigs.wstrb;
assign w_vip_slv_port_sigs.wvalid = r_axi4_vip_slv_port_drv_sigs.wvalid;
assign w_vip_slv_port_sigs.bready = r_axi4_vip_slv_port_drv_sigs.bready;
assign w_vip_slv_port_sigs.araddr = r_axi4_vip_slv_port_drv_sigs.araddr;
assign w_vip_slv_port_sigs.arprot = r_axi4_vip_slv_port_drv_sigs.arprot;
assign w_vip_slv_port_sigs.arvalid = r_axi4_vip_slv_port_drv_sigs.arvalid;
assign w_vip_slv_port_sigs.rready = r_axi4_vip_slv_port_drv_sigs.rready;
// --------------------

//! Perform AXI4-Lite read transaction.
//! This task is based on the following blog post.
//! [Testing Verilog AXI4-Lite Peripherals](https://klickverbot.at/blog/2016/01/testing-verilog-axi4-lite-peripherals/)
task automatic axi4_lite_read(
    // const ref axi4_lite_sigs_t dut_if_mon_sigs, // `const` leads to failure in xsim. The argument is NOT updated in real-time.
    ref axi4_lite_sigs_t dut_if_mon_sigs, //! A reference to the variable for monitoring the DUT interface. This variable is expected to be a mirror of the DUT interface signals.
    ref axi4_lite_mst_out_sigs_t dut_if_drv_sigs, //! A reference to the variable for driving the DUT interface. DUT interface signals are expected to be assigned to this variable.
    input bit [AXI4_LITE_ADDR_BIT_WIDTH-1:0] addr, //! address
    output bit [AXI4_LITE_DATA_BIT_WIDTH-1:0] data //! storage for read data
);
    if (dut_if_mon_sigs.arvalid) begin
        $info("There is a read transaction in progress. Waiting for it to complete.");
        wait(!dut_if_mon_sigs.arvalid);
        @(posedge r_clk); #1;
    end

    dut_if_drv_sigs.araddr = addr; // non-blocking assignment cannot be used due to VRFC 10-3140
    dut_if_drv_sigs.arvalid = 1'b1;
    dut_if_drv_sigs.rready = 1'b1;

    wait(dut_if_mon_sigs.arready);

    if (dut_if_mon_sigs.rvalid) begin
        data = dut_if_mon_sigs.rdata;
        @(posedge r_clk); #1;
        dut_if_drv_sigs.arvalid = 1'b0;
        dut_if_drv_sigs.rready = 1'b0;
    end else begin
        @(posedge r_clk); #1;
        dut_if_drv_sigs.arvalid = 1'b0; // Should be de-asserted here, otherwise protocol violation may occur (AXI4_ERRM_ARVALID_STABLE).

        wait(dut_if_mon_sigs.rvalid); // Note that RVALID may come AFTER the ARREADY's falling edge.
        data = dut_if_mon_sigs.rdata;
        @(posedge r_clk); #1;
        dut_if_drv_sigs.rready = 1'b0;
    end
endtask

//! Perform AXI4-Lite write transaction.
//! This task is based on the following blog post.
//! [Testing Verilog AXI4-Lite Peripherals](https://klickverbot.at/blog/2016/01/testing-verilog-axi4-lite-peripherals/)
task automatic axi4_lite_write(
    // const ref axi4_lite_sigs_t dut_if_mon_sigs, // `const` leads to failure in xsim. The argument is NOT updated in real-time.
    ref axi4_lite_sigs_t dut_if_mon_sigs, //! A reference to the variable for monitoring the DUT interface. This variable is expected to be a mirror of the DUT interface signals.
    ref axi4_lite_mst_out_sigs_t dut_if_drv_sigs, //! A reference to the variable for driving the DUT interface. DUT interface signals are expected to be assigned to this variable
    input bit [AXI4_LITE_ADDR_BIT_WIDTH-1:0] addr, //! address
    input bit [AXI4_LITE_DATA_BIT_WIDTH-1:0] data, //! data
    input bit [(AXI4_LITE_DATA_BIT_WIDTH/8)-1:0] wstrb = '1 //! write strobe
);
    if (dut_if_mon_sigs.awvalid || dut_if_mon_sigs.wvalid) begin
        $info("There is a write transaction in progress. Waiting for it to complete.");
        wait(!dut_if_mon_sigs.awvalid && !dut_if_mon_sigs.wvalid);
        @(posedge r_clk); #1;
    end

    dut_if_drv_sigs.awaddr = addr;
    dut_if_drv_sigs.awvalid = 1'b1;
    dut_if_drv_sigs.wdata = data;
    dut_if_drv_sigs.wstrb = wstrb;
    dut_if_drv_sigs.wvalid = 1'b1;
    dut_if_drv_sigs.bready = 1'b1;

    wait(dut_if_mon_sigs.awready && dut_if_mon_sigs.wready);

    @(posedge r_clk); #1;
    dut_if_drv_sigs.awvalid = 1'b0;
    dut_if_drv_sigs.wvalid = 1'b0;
endtask

//! DUT instance
my_axi4_lite_slv_template dut (
    .i_clk(r_clk),
    .i_sync_rst(r_sync_rst),
    .if_s_axi4_lite(axi4_lite_if__vip_dut.slv_port)
);

//! AXI4 VIP instance
axi_vip_passthrough vip (
    .aclk(r_clk),
    .aresetn(~r_sync_rst),
    .s_axi_awaddr(w_vip_slv_port_sigs.awaddr),
    .s_axi_awprot(w_vip_slv_port_sigs.awprot),
    .s_axi_awvalid(w_vip_slv_port_sigs.awvalid),
    .s_axi_awready(w_vip_slv_port_sigs.awready),
    .s_axi_wdata(w_vip_slv_port_sigs.wdata),
    .s_axi_wstrb(w_vip_slv_port_sigs.wstrb),
    .s_axi_wvalid(w_vip_slv_port_sigs.wvalid),
    .s_axi_wready(w_vip_slv_port_sigs.wready),
    .s_axi_bresp(w_vip_slv_port_sigs.bresp),
    .s_axi_bvalid(w_vip_slv_port_sigs.bvalid),
    .s_axi_bready(w_vip_slv_port_sigs.bready),
    .s_axi_araddr(w_vip_slv_port_sigs.araddr),
    .s_axi_arprot(w_vip_slv_port_sigs.arprot),
    .s_axi_arvalid(w_vip_slv_port_sigs.arvalid),
    .s_axi_arready(w_vip_slv_port_sigs.arready),
    .s_axi_rdata(w_vip_slv_port_sigs.rdata),
    .s_axi_rresp(w_vip_slv_port_sigs.rresp),
    .s_axi_rvalid(w_vip_slv_port_sigs.rvalid),
    .s_axi_rready(w_vip_slv_port_sigs.rready),
    .m_axi_awaddr(axi4_lite_if__vip_dut.awaddr),
    .m_axi_awprot(axi4_lite_if__vip_dut.awprot),
    .m_axi_awvalid(axi4_lite_if__vip_dut.awvalid),
    .m_axi_awready(axi4_lite_if__vip_dut.awready),
    .m_axi_wdata(axi4_lite_if__vip_dut.wdata),
    .m_axi_wstrb(axi4_lite_if__vip_dut.wstrb),
    .m_axi_wvalid(axi4_lite_if__vip_dut.wvalid),
    .m_axi_wready(axi4_lite_if__vip_dut.wready),
    .m_axi_bresp(axi4_lite_if__vip_dut.bresp),
    .m_axi_bvalid(axi4_lite_if__vip_dut.bvalid),
    .m_axi_bready(axi4_lite_if__vip_dut.bready),
    .m_axi_araddr(axi4_lite_if__vip_dut.araddr),
    .m_axi_arprot(axi4_lite_if__vip_dut.arprot),
    .m_axi_arvalid(axi4_lite_if__vip_dut.arvalid),
    .m_axi_arready(axi4_lite_if__vip_dut.arready),
    .m_axi_rdata(axi4_lite_if__vip_dut.rdata),
    .m_axi_rresp(axi4_lite_if__vip_dut.rresp),
    .m_axi_rvalid(axi4_lite_if__vip_dut.rvalid),
    .m_axi_rready(axi4_lite_if__vip_dut.rready)
);

//! storage initialization
initial begin
    r_axi4_vip_slv_port_drv_sigs = '{default:'0};
end

//! Drive the clock.
initial forever #(CLK_PERIOD_NS/2) r_clk = ~r_clk;

//! Drive the reset signal.
task automatic drive_rst();
    r_sync_rst <= 1'b1;
    repeat (RELEASE_RST_AFTER_CLK) begin
        @(posedge r_clk);
    end
    r_sync_rst <= 1'b0;
endtask

//! Monitor the AXI4 VIP interface signals.
always_comb begin: mon_dut_if_sig
    g_vip_slv_port_mon_sigs.awaddr = w_vip_slv_port_sigs.awaddr;
    g_vip_slv_port_mon_sigs.awprot = w_vip_slv_port_sigs.awprot;
    g_vip_slv_port_mon_sigs.awvalid = w_vip_slv_port_sigs.awvalid;
    g_vip_slv_port_mon_sigs.awready = w_vip_slv_port_sigs.awready;
    g_vip_slv_port_mon_sigs.wdata = w_vip_slv_port_sigs.wdata;
    g_vip_slv_port_mon_sigs.wstrb = w_vip_slv_port_sigs.wstrb;
    g_vip_slv_port_mon_sigs.wvalid = w_vip_slv_port_sigs.wvalid;
    g_vip_slv_port_mon_sigs.wready = w_vip_slv_port_sigs.wready;
    g_vip_slv_port_mon_sigs.bresp = w_vip_slv_port_sigs.bresp;
    g_vip_slv_port_mon_sigs.bvalid = w_vip_slv_port_sigs.bvalid;
    g_vip_slv_port_mon_sigs.bready = w_vip_slv_port_sigs.bready;
    g_vip_slv_port_mon_sigs.araddr = w_vip_slv_port_sigs.araddr;
    g_vip_slv_port_mon_sigs.arprot = w_vip_slv_port_sigs.arprot;
    g_vip_slv_port_mon_sigs.arvalid = w_vip_slv_port_sigs.arvalid;
    g_vip_slv_port_mon_sigs.arready = w_vip_slv_port_sigs.arready;
    g_vip_slv_port_mon_sigs.rdata = w_vip_slv_port_sigs.rdata;
    g_vip_slv_port_mon_sigs.rresp = w_vip_slv_port_sigs.rresp;
    g_vip_slv_port_mon_sigs.rvalid = w_vip_slv_port_sigs.rvalid;
    g_vip_slv_port_mon_sigs.rready = w_vip_slv_port_sigs.rready;
end

task automatic reg_check();
    const var bit [AXI4_LITE_DATA_BIT_WIDTH-1:0] write_data[4] = {'h12345678, 'h87654321, 'hABCDEF01, 'h10FEDCBA};
    var bit [AXI4_LITE_DATA_BIT_WIDTH-1:0] read_back_data;

    for (int i=0; i<4; ++i) begin
        axi4_lite_write(g_vip_slv_port_mon_sigs, r_axi4_vip_slv_port_drv_sigs, AXI4_LITE_ADDR_BIT_WIDTH'(i*4), write_data[i]);
        @(posedge r_clk);
    end

    for (int i=0; i<4; ++i) begin
        axi4_lite_read(g_vip_slv_port_mon_sigs, r_axi4_vip_slv_port_drv_sigs, AXI4_LITE_ADDR_BIT_WIDTH'(i*4), read_back_data);
        $info("Read back data from address %0H: %0H", i*4, read_back_data);
        @(posedge r_clk);
    end
endtask

task automatic scenario();
    drive_rst();
    @(posedge r_clk);
    reg_check();
    @(posedge r_clk);
    $finish;
endtask

//! Launch scenario and manage time limit.
initial begin
    fork
        scenario();
    join_none
    #SIM_TIME_LIMIT_NS;
    $fatal(2, "Simulation timeout.");
end

endmodule

`default_nettype wire
