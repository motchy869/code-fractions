// Verible directive
// verilog_lint: waive-start parameter-name-style
// verilog_lint: waive-start line-length

`include "../axi4_lite_if.svh"

`default_nettype none

// timescale is defined in Makefile.
// timeunit 1ns;
// timeprecision 1ps;

//! A test bench for my_axi4_lite_slv_template.
//! Some techniques used in this test bench are based on the following blog post.
//!
//! [仮想インターフェース　(Virtual interface)](http://japanese.sugawara-systems.com/systemverilog/virtual_interface.htm)
//!
//! Vivado 2023.2 crushes with SIGSEGV.
module test_bench;
// ---------- parameters ----------
localparam int CLK_PERIOD_NS = 8; //! clock period in ns
localparam int SIM_TIME_LIMIT_NS = 400; //! simulation time limit in ns
localparam int RELEASE_RST_AFTER_CLK = 2; //! Reset signal deasserts right after this clock rising-edge.

localparam int AXI4_LITE_ADDR_BIT_WIDTH = 32; //! bit width of AXI4-Lite address bus
localparam int AXI4_LITE_DATA_BIT_WIDTH = 32; //! bit width of AXI4-Lite data bus
// --------------------

// ---------- internal signal and storage ----------
var bit r_clk; //! clock signal
var bit r_sync_rst; //! clock synchronous reset signal

// interface instance
axi4_lite_if dut_if (.clk(r_clk));
virtual interface axi4_lite_if dut_vif; //! virtual interface to DUT
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
    .if_s_axi4_lite(dut_if.slv_port)
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
        axi4_lite_write(dut_vif, AXI4_LITE_ADDR_BIT_WIDTH'(i*4), write_data[i]);
        @(posedge r_clk);
    end

    for (int i=0; i<4; ++i) begin
        axi4_lite_read(dut_vif, AXI4_LITE_ADDR_BIT_WIDTH'(i*4), read_back_data);
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
    dut_vif = dut_if;
    dut_vif.reset();
    fork
        scenario();
    join_none
    #SIM_TIME_LIMIT_NS;
    $fatal(2, "Simulation timeout.");
end

endmodule

`default_nettype wire
