// Verible directive
// verilog_lint: waive-start parameter-name-style
// verilog_lint: waive-start line-length

`include "../axi4_lite_if_pkg.svh"
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
axi4_lite_if if__vip_dut (.i_clk(r_clk)); // interface between AXI4 VIP and DUT
axi4_lite_if if__tb_vip (.i_clk(r_clk)); // interface between test bench and AXI4 VIP
virtual interface axi4_lite_if vif__tb_vip; //! virtual interface between test bench and AXI4 VIP
// --------------------

//! DUT instance
my_axi4_lite_slv_template dut (
    .i_clk(r_clk),
    .i_sync_rst(r_sync_rst),
    .if_s_axi4_lite(if__vip_dut.slv_port)
);

//! AXI4 VIP instance
axi_vip_passthrough vip (
    .aclk(r_clk),
    .aresetn(~r_sync_rst),
    .s_axi_awaddr(if__tb_vip.awaddr),
    .s_axi_awprot(if__tb_vip.awprot),
    .s_axi_awvalid(if__tb_vip.awvalid),
    .s_axi_awready(if__tb_vip.awready),
    .s_axi_wdata(if__tb_vip.wdata),
    .s_axi_wstrb(if__tb_vip.wstrb),
    .s_axi_wvalid(if__tb_vip.wvalid),
    .s_axi_wready(if__tb_vip.wready),
    .s_axi_bresp(if__tb_vip.bresp),
    .s_axi_bvalid(if__tb_vip.bvalid),
    .s_axi_bready(if__tb_vip.bready),
    .s_axi_araddr(if__tb_vip.araddr),
    .s_axi_arprot(if__tb_vip.arprot),
    .s_axi_arvalid(if__tb_vip.arvalid),
    .s_axi_arready(if__tb_vip.arready),
    .s_axi_rdata(if__tb_vip.rdata),
    .s_axi_rresp(if__tb_vip.rresp),
    .s_axi_rvalid(if__tb_vip.rvalid),
    .s_axi_rready(if__tb_vip.rready),
    .m_axi_awaddr(if__vip_dut.awaddr),
    .m_axi_awprot(if__vip_dut.awprot),
    .m_axi_awvalid(if__vip_dut.awvalid),
    .m_axi_awready(if__vip_dut.awready),
    .m_axi_wdata(if__vip_dut.wdata),
    .m_axi_wstrb(if__vip_dut.wstrb),
    .m_axi_wvalid(if__vip_dut.wvalid),
    .m_axi_wready(if__vip_dut.wready),
    .m_axi_bresp(if__vip_dut.bresp),
    .m_axi_bvalid(if__vip_dut.bvalid),
    .m_axi_bready(if__vip_dut.bready),
    .m_axi_araddr(if__vip_dut.araddr),
    .m_axi_arprot(if__vip_dut.arprot),
    .m_axi_arvalid(if__vip_dut.arvalid),
    .m_axi_arready(if__vip_dut.arready),
    .m_axi_rdata(if__vip_dut.rdata),
    .m_axi_rresp(if__vip_dut.rresp),
    .m_axi_rvalid(if__vip_dut.rvalid),
    .m_axi_rready(if__vip_dut.rready)
);

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

task automatic reg_check();
    const bit [AXI4_LITE_DATA_BIT_WIDTH-1:0] write_data[4] = {'h12345678, 'h87654321, 'hABCDEF01, 'h10FEDCBA};
    bit [AXI4_LITE_DATA_BIT_WIDTH-1:0] read_back_data;
    axi4_lite_if_pkg::axi4_resp_t resp;

    for (int i=0; i<4; ++i) begin
        axi4_lite_if_pkg::axi4_lite_access#(
            .AXI4_LITE_ADDR_BIT_WIDTH(AXI4_LITE_ADDR_BIT_WIDTH),
            .AXI4_LITE_DATA_BIT_WIDTH(AXI4_LITE_DATA_BIT_WIDTH)
        )::axi4_lite_write(vif__tb_vip, AXI4_LITE_ADDR_BIT_WIDTH'(i*4), write_data[i], '1, resp);
        @(posedge r_clk);
    end

    for (int i=0; i<4; ++i) begin
        axi4_lite_if_pkg::axi4_lite_access#(
            .AXI4_LITE_ADDR_BIT_WIDTH(AXI4_LITE_ADDR_BIT_WIDTH),
            .AXI4_LITE_DATA_BIT_WIDTH(AXI4_LITE_DATA_BIT_WIDTH)
        )::axi4_lite_read(vif__tb_vip, AXI4_LITE_ADDR_BIT_WIDTH'(i*4), read_back_data, resp);
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
    vif__tb_vip = if__tb_vip;
    if__tb_vip.reset_mst_out_sigs();
    fork
        scenario();
    join_none
    #SIM_TIME_LIMIT_NS;
    $fatal(2, "Simulation timeout.");
end

endmodule

`default_nettype wire
