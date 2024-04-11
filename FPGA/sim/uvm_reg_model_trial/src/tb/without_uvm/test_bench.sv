// Verible directive
// verilog_lint: waive-start parameter-name-style
// verilog_lint: waive-start line-length

`include "axi4_lite_if.svh"

`default_nettype none

// `timeunit` and `timeprecision` should NOT be placed in the module.
timeunit 1ns;
timeprecision 1ps;

//! test bench for my_axi4_lite_slv_template without UVM
module test_bench;
// ---------- parameters ----------
localparam int CLK_PERIOD_NS = 8; //! clock period in ns
localparam int SIM_DURATION_NS = 100; //! simulation duration in ns
localparam int RELEASE_RST_AFTER_CLK = 2; //! Reset signal deasserts right after this clock rising-edge.

localparam int AXI4_LITE_ADDR_BIT_WIDTH = 4; //! bit width of AXI4-Lite address bus
localparam int AXI4_LITE_DATA_BIT_WIDTH = 32; //! bit width of AXI4-Lite data bus
// --------------------

// ---------- internal signal and storage ----------
var bit r_clk; //! clock signal
var bit r_sync_rst; //! clock synchronous reset signal

// interface instance
axi4_lite_if axi4_lite_if_0 ();


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
var axi4_lite_mst_out_sigs_t axi4_lite_mst_out_sigs_0;

assign axi4_lite_if_0.awaddr = axi4_lite_mst_out_sigs_0.awaddr;
assign axi4_lite_if_0.awprot = axi4_lite_mst_out_sigs_0.awprot;
assign axi4_lite_if_0.awvalid = axi4_lite_mst_out_sigs_0.awvalid;
assign axi4_lite_if_0.wdata = axi4_lite_mst_out_sigs_0.wdata;
assign axi4_lite_if_0.wstrb = axi4_lite_mst_out_sigs_0.wstrb;
assign axi4_lite_if_0.wvalid = axi4_lite_mst_out_sigs_0.wvalid;
assign axi4_lite_if_0.bready = axi4_lite_mst_out_sigs_0.bready;
assign axi4_lite_if_0.araddr = axi4_lite_mst_out_sigs_0.araddr;
assign axi4_lite_if_0.arprot = axi4_lite_mst_out_sigs_0.arprot;
assign axi4_lite_if_0.arvalid = axi4_lite_mst_out_sigs_0.arvalid;
assign axi4_lite_if_0.rready = axi4_lite_mst_out_sigs_0.rready;
// --------------------

//! DUT instance
my_axi4_lite_slv_template dut (
    .i_clk(r_clk),
    .i_sync_rst(r_sync_rst),
    .if_s_axi4_lite(axi4_lite_if_0.slv_port)
);

task automatic axi4_lite_read(
    const ref axi4_lite_if axi4_lite_if_inst,
    ref axi4_lite_mst_out_sigs_t axi4_lite_mst_out_sigs,
    input bit [AXI4_LITE_ADDR_BIT_WIDTH-1:0] addr,
    output bit [AXI4_LITE_DATA_BIT_WIDTH-1:0] data
);
    axi4_lite_mst_out_sigs.araddr = addr;
    axi4_lite_mst_out_sigs.arvalid = 1'b1;
    axi4_lite_mst_out_sigs.rready = 1'b1;

    wait(axi4_lite_if_inst.arready);
    wait(axi4_lite_if_inst.arvalid);

    @(posedge r_clk) #1;
    axi4_lite_mst_out_sigs.arvalid = 1'b0;
    axi4_lite_mst_out_sigs.rready = 1'b0;
endtask

task automatic axi4_lite_write(
    const ref axi4_lite_if axi4_lite_if_inst,
    ref axi4_lite_mst_out_sigs_t axi4_lite_mst_out_sigs,
    input bit [AXI4_LITE_ADDR_BIT_WIDTH-1:0] addr,
    input bit [AXI4_LITE_DATA_BIT_WIDTH-1:0] data
);
    axi4_lite_mst_out_sigs.awaddr = addr;
    axi4_lite_mst_out_sigs.awvalid = 1'b1;
    axi4_lite_mst_out_sigs.wdata = data;
    axi4_lite_mst_out_sigs.wvalid = 1'b1;

    wait(axi4_lite_if_inst.awready && axi4_lite_if_inst.wready);

    @(posedge r_clk) #1;
    axi4_lite_mst_out_sigs.awvalid = 1'b0;
    axi4_lite_mst_out_sigs.wvalid = 1'b0;
endtask

//! Drive the clock.
initial forever #(CLK_PERIOD_NS/2) r_clk = ~r_clk;

//! Drive the reset signal.
task automatic drive_rst();
    r_sync_rst = 1;
    repeat (RELEASE_RST_AFTER_CLK) begin
        @(posedge r_clk);
    end
    r_sync_rst <= 0;
endtask

//! scenario
initial begin
    fork drive_rst(); join_none
    #SIM_DURATION_NS;
    $finish;
end

endmodule

`default_nettype wire
