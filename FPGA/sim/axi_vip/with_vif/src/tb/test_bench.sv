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
axi4_lite_if if__vip_dut (.clk(r_clk)); // interface between AXI4 VIP and DUT
axi4_lite_if if__tb_vip (.clk(r_clk)); // interface between test bench and AXI4 VIP
virtual interface axi4_lite_if vif__tb_vip; //! virtual interface between test bench and AXI4 VIP
// --------------------

//! Perform AXI4-Lite read transaction.
//! This task is based on the following blog post.
//! [Testing Verilog AXI4-Lite Peripherals](https://klickverbot.at/blog/2016/01/testing-verilog-axi4-lite-peripherals/)
task automatic axi4_lite_read(
    virtual interface axi4_lite_if vif, //! virtual interface to DUT
    input bit [AXI4_LITE_ADDR_BIT_WIDTH-1:0] addr, //! address
    output bit [AXI4_LITE_DATA_BIT_WIDTH-1:0] data //! storage for read data
);
    if (vif.arvalid) begin
        $info("There is a read transaction in progress. Waiting for it to complete.");
        wait(!vif.arvalid);
    end

    `ifdef XILINX_SIMULATOR // Vivado 2023.2 crushes with SIGSEGV when clocking block is used.
        `define WAIT_CLK_POSEDGE @(posedge vif.clk)
    `else
        `define WAIT_CLK_POSEDGE @vif.mst_cb
    `endif

    `WAIT_CLK_POSEDGE begin
        vif.araddr <= addr;
        vif.arvalid <= 1'b1;
        vif.rready <= 1'b1;
    end

    wait(vif.arready);

    if (vif.rvalid) begin
        data = vif.rdata;
        `WAIT_CLK_POSEDGE begin
            vif.arvalid <= 1'b0;
            vif.rready <= 1'b0;
        end
    end else begin
        `WAIT_CLK_POSEDGE begin
            vif.arvalid <= 1'b0; // Should be de-asserted here, otherwise possible protocol violation (AXI4_ERRM_ARVALID_STABLE: Once ARVALID is asserted, it must remain asserted until ARREADY is high. Spec: section A3.2.1.)
        end

        wait(vif.rvalid); // Note that RVALID may come AFTER the ARREADY's falling edge.
        data = vif.rdata;
        `WAIT_CLK_POSEDGE begin
            vif.rready <= 1'b0;
        end
    end

    `undef WAIT_CLK_POSEDGE
endtask

//! Perform AXI4-Lite write transaction.
//! This task is based on the following blog post.
//! [Testing Verilog AXI4-Lite Peripherals](https://klickverbot.at/blog/2016/01/testing-verilog-axi4-lite-peripherals/)
task automatic axi4_lite_write(
    virtual interface axi4_lite_if vif, //! virtual interface to DUT
    input bit [AXI4_LITE_ADDR_BIT_WIDTH-1:0] addr, //! address
    input bit [AXI4_LITE_DATA_BIT_WIDTH-1:0] data, //! data
    input bit [(AXI4_LITE_DATA_BIT_WIDTH/8)-1:0] wstrb = '1 //! write strobe
);
    if (vif.awvalid || vif.wvalid) begin
        $info("There is a write transaction in progress. Waiting for it to complete.");
        wait(!vif.awvalid && !vif.wvalid);
    end

    `ifdef XILINX_SIMULATOR // Vivado 2023.2 crushes with SIGSEGV when clocking block is used.
        `define WAIT_CLK_POSEDGE @(posedge vif.clk)
    `else
        `define WAIT_CLK_POSEDGE @vif.mst_cb
    `endif

    `WAIT_CLK_POSEDGE begin
        vif.awaddr <= addr;
        vif.awvalid <= 1'b1;
        vif.wdata <= data;
        vif.wstrb <= wstrb;
        vif.wvalid <= 1'b1;
        vif.bready <= 1'b1;
    end

    wait(vif.awready && vif.wready);

    `WAIT_CLK_POSEDGE begin
        vif.awvalid <= 1'b0;
        vif.wvalid <= 1'b0;
    end

    `undef WAIT_CLK_POSEDGE
endtask

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
    const var bit [AXI4_LITE_DATA_BIT_WIDTH-1:0] write_data[4] = {'h12345678, 'h87654321, 'hABCDEF01, 'h10FEDCBA};
    var bit [AXI4_LITE_DATA_BIT_WIDTH-1:0] read_back_data;

    for (int i=0; i<4; ++i) begin
        axi4_lite_write(vif__tb_vip, AXI4_LITE_ADDR_BIT_WIDTH'(i*4), write_data[i]);
        @(posedge r_clk);
    end

    for (int i=0; i<4; ++i) begin
        axi4_lite_read(vif__tb_vip, AXI4_LITE_ADDR_BIT_WIDTH'(i*4), read_back_data);
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
    if__tb_vip.reset_mst_port();
    fork
        scenario();
    join_none
    #SIM_TIME_LIMIT_NS;
    $fatal(2, "Simulation timeout.");
end

endmodule

`default_nettype wire
