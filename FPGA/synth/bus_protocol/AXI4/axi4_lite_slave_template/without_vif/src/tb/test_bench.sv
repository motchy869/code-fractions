// Verible directive
// verilog_lint: waive-start parameter-name-style
// verilog_lint: waive-start line-length

`include "../axi4_lite_if.svh"

`default_nettype none

// timescale is defined in Makefile.
// timeunit 1ns;
// timeprecision 1ps;

//! test bench for my_axi4_lite_slv_template without UVM
module test_bench;
// ---------- parameters ----------
localparam int CLK_PERIOD_NS = 8; //! clock period in ns
localparam int SIM_TIME_LIMIT_NS = 300; //! simulation time limit in ns
localparam int RELEASE_RST_AFTER_CLK = 2; //! Reset signal deasserts right after this clock rising-edge.

localparam int AXI4_LITE_ADDR_BIT_WIDTH = 32; //! bit width of AXI4-Lite address bus
localparam int AXI4_LITE_DATA_BIT_WIDTH = 32; //! bit width of AXI4-Lite data bus
// --------------------

// ---------- internal signal and storage ----------
var bit r_clk; //! clock signal
var bit r_sync_rst; //! clock synchronous reset signal

// interface instance
axi4_lite_if axi4_lite_if_0 ();

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
// Note that struct has to be initialized explicitly.

var axi4_lite_sigs_t g_dut_if_mon_sigs; //! monitored signals of interface between test bench and DUT
var axi4_lite_mst_out_sigs_t r_dut_if_drv_sigs; //! driver signals of interface between test bench and DUT

assign axi4_lite_if_0.awaddr = r_dut_if_drv_sigs.awaddr;
assign axi4_lite_if_0.awprot = r_dut_if_drv_sigs.awprot;
assign axi4_lite_if_0.awvalid = r_dut_if_drv_sigs.awvalid;
assign axi4_lite_if_0.wdata = r_dut_if_drv_sigs.wdata;
assign axi4_lite_if_0.wstrb = r_dut_if_drv_sigs.wstrb;
assign axi4_lite_if_0.wvalid = r_dut_if_drv_sigs.wvalid;
assign axi4_lite_if_0.bready = r_dut_if_drv_sigs.bready;
assign axi4_lite_if_0.araddr = r_dut_if_drv_sigs.araddr;
assign axi4_lite_if_0.arprot = r_dut_if_drv_sigs.arprot;
assign axi4_lite_if_0.arvalid = r_dut_if_drv_sigs.arvalid;
assign axi4_lite_if_0.rready = r_dut_if_drv_sigs.rready;
// --------------------

//! Perform AXI4-Lite read transaction.
//! This task is based on the following blog post.
//! [Testing Verilog AXI4-Lite Peripherals](https://klickverbot.at/blog/2016/01/testing-verilog-axi4-lite-peripherals/)
task automatic axi4_lite_read(
    ref bit clk, //! clock signal
    // const ref axi4_lite_sigs_t dut_if_mon_sigs, // `const` leads to failure in xsim. The argument is NOT updated in real-time.
    ref axi4_lite_sigs_t dut_if_mon_sigs, //! A reference to the variable for monitoring the DUT interface. This variable is expected to be a mirror of the DUT interface signals.
    ref axi4_lite_mst_out_sigs_t dut_if_drv_sigs, //! A reference to the variable for driving the DUT interface. DUT interface signals are expected to be assigned to this variable.
    input bit [AXI4_LITE_ADDR_BIT_WIDTH-1:0] addr, //! address
    output bit [AXI4_LITE_DATA_BIT_WIDTH-1:0] data //! storage for read data
);
    if (dut_if_mon_sigs.arvalid) begin
        $info("There is a read transaction in progress. Waiting for it to complete.");
        wait(!dut_if_mon_sigs.arvalid);
        @(posedge clk); #1;
    end

    dut_if_drv_sigs.araddr = addr; // non-blocking assignment cannot be used due to VRFC 10-3140
    dut_if_drv_sigs.arvalid = 1'b1;
    dut_if_drv_sigs.rready = 1'b1;

    wait(dut_if_mon_sigs.arready);

    if (dut_if_mon_sigs.rvalid) begin
        data = dut_if_mon_sigs.rdata;
        @(posedge clk); #1;
        dut_if_drv_sigs.arvalid = 1'b0;
        dut_if_drv_sigs.rready = 1'b0;
    end else begin
        @(posedge clk); #1;
        dut_if_drv_sigs.arvalid = 1'b0; // Should be de-asserted here, otherwise possible protocol violation (AXI4_ERRM_ARVALID_STABLE: Once ARVALID is asserted, it must remain asserted until ARREADY is high. Spec: section A3.2.1.)

        wait(dut_if_mon_sigs.rvalid); // Note that RVALID may come AFTER the ARREADY's falling edge.
        data = dut_if_mon_sigs.rdata;
        @(posedge clk); #1;
        dut_if_drv_sigs.rready = 1'b0;
    end
endtask

//! Perform AXI4-Lite write transaction.
//! This task is based on the following blog post.
//! [Testing Verilog AXI4-Lite Peripherals](https://klickverbot.at/blog/2016/01/testing-verilog-axi4-lite-peripherals/)
task automatic axi4_lite_write(
    ref bit clk, //! clock signal
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
        @(posedge clk); #1;
    end

    dut_if_drv_sigs.awaddr = addr;
    dut_if_drv_sigs.awvalid = 1'b1;
    dut_if_drv_sigs.wdata = data;
    dut_if_drv_sigs.wstrb = wstrb;
    dut_if_drv_sigs.wvalid = 1'b1;
    dut_if_drv_sigs.bready = 1'b1;

    // debug code
    // repeat (10) begin
    //     @(posedge clk);
    //     $info("MON wready: %0d, awready: %0d", dut_if_mon_sigs.wready, dut_if_mon_sigs.awready);
    //     $info("IF wready: %0d, awready: %0d", axi4_lite_if_0.wready, axi4_lite_if_0.awready);
    // end

    wait(dut_if_mon_sigs.awready && dut_if_mon_sigs.wready);

    @(posedge clk); #1;
    dut_if_drv_sigs.awvalid = 1'b0;
    dut_if_drv_sigs.wvalid = 1'b0;
endtask

//! DUT instance
my_axi4_lite_slv_template dut (
    .i_clk(r_clk),
    .i_sync_rst(r_sync_rst),
    .if_s_axi4_lite(axi4_lite_if_0.slv_port)
);

//! storage initialization
initial begin
    r_dut_if_drv_sigs = '{default:'0};
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

//! Monitor the DUT interface signals.
always_comb begin: mon_dut_if_sig
    g_dut_if_mon_sigs.awaddr = axi4_lite_if_0.awaddr;
    g_dut_if_mon_sigs.awprot = axi4_lite_if_0.awprot;
    g_dut_if_mon_sigs.awvalid = axi4_lite_if_0.awvalid;
    g_dut_if_mon_sigs.awready = axi4_lite_if_0.awready;
    g_dut_if_mon_sigs.wdata = axi4_lite_if_0.wdata;
    g_dut_if_mon_sigs.wstrb = axi4_lite_if_0.wstrb;
    g_dut_if_mon_sigs.wvalid = axi4_lite_if_0.wvalid;
    g_dut_if_mon_sigs.wready = axi4_lite_if_0.wready;
    g_dut_if_mon_sigs.bresp = axi4_lite_if_0.bresp;
    g_dut_if_mon_sigs.bvalid = axi4_lite_if_0.bvalid;
    g_dut_if_mon_sigs.bready = axi4_lite_if_0.bready;
    g_dut_if_mon_sigs.araddr = axi4_lite_if_0.araddr;
    g_dut_if_mon_sigs.arprot = axi4_lite_if_0.arprot;
    g_dut_if_mon_sigs.arvalid = axi4_lite_if_0.arvalid;
    g_dut_if_mon_sigs.arready = axi4_lite_if_0.arready;
    g_dut_if_mon_sigs.rdata = axi4_lite_if_0.rdata;
    g_dut_if_mon_sigs.rresp = axi4_lite_if_0.rresp;
    g_dut_if_mon_sigs.rvalid = axi4_lite_if_0.rvalid;
    g_dut_if_mon_sigs.rready = axi4_lite_if_0.rready;
end

task automatic reg_check();
    const var bit [AXI4_LITE_DATA_BIT_WIDTH-1:0] write_data[4] = {'h12345678, 'h87654321, 'hABCDEF01, 'h10FEDCBA};
    var bit [AXI4_LITE_DATA_BIT_WIDTH-1:0] read_back_data;

    for (int i=0; i<4; ++i) begin
        axi4_lite_write(r_clk, g_dut_if_mon_sigs, r_dut_if_drv_sigs, AXI4_LITE_ADDR_BIT_WIDTH'(i*4), write_data[i]);
        @(posedge r_clk);
    end

    for (int i=0; i<4; ++i) begin
        axi4_lite_read(r_clk, g_dut_if_mon_sigs, r_dut_if_drv_sigs, AXI4_LITE_ADDR_BIT_WIDTH'(i*4), read_back_data);
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
