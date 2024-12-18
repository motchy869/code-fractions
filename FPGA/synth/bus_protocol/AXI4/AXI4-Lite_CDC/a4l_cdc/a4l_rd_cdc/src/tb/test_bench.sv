// Verible directive
// verilog_lint: waive-start parameter-name-style
// verilog_lint: waive-start line-length

`default_nettype none

// timescale is defined in Makefile.

module test_bench;
// ---------- parameters ----------
typedef int unsigned uint_t;

localparam uint_t M_CLK_PERIOD_NS = 5; //! manager clock period in ns
localparam uint_t S_CLK_PERIOD_NS = 8; //! subordinate clock period in ns
localparam uint_t M_RST_DURATION_CYCLE = 1; //! manager reset duration in cycles
localparam uint_t S_RST_DURATION_CYCLE = 1; //! subordinate reset duration in cycles
localparam uint_t SIM_TIME_LIMIT_NS = 200; //! simulation time limit in ns

localparam uint_t AXI4_LITE_ADDR_BIT_WIDTH = 32;
localparam uint_t AXI4_LITE_DATA_BIT_WIDTH = 32;
// --------------------

// ---------- parameter validation ----------
// --------------------

// ---------- functions ----------
// --------------------

// ---------- signals and storage ----------
var bit r_m_clk; //! manager clock signal
var bit r_s_clk; //! subordinate clock signal

interface dut_m_if #(
    parameter int AXI4_LITE_ADDR_BIT_WIDTH = 32,
    parameter int AXI4_LITE_DATA_BIT_WIDTH = 32
)(
    input wire logic m0_aclk
);
    // signals between subordinate-in-bench and DUT
    logic m0_sync_rst;
    logic [AXI4_LITE_ADDR_BIT_WIDTH-1:0] m0_araddr;
    logic [2:0] m0_arprot;
    logic m0_arvalid;
    logic m0_arready;
    logic [AXI4_LITE_DATA_BIT_WIDTH-1:0] m0_rdata;
    logic [1:0] m0_rresp;
    logic m0_rvalid;
    logic m0_rready;

    task automatic reset_bench_driven_sigs();
        m0_arready <= 1'b0;
        m0_rdata <= '0;
        m0_rresp <= '0;
        m0_rvalid <= 1'b0;
    endtask
endinterface

interface dut_s_if #(
    parameter int AXI4_LITE_ADDR_BIT_WIDTH = 32,
    parameter int AXI4_LITE_DATA_BIT_WIDTH = 32
)(
    input wire logic s0_aclk
);
    // signals between manager-in-bench and DUT
    logic s0_sync_rst;
    logic [AXI4_LITE_ADDR_BIT_WIDTH-1:0] s0_araddr;
    logic [2:0] s0_arprot;
    logic s0_arvalid;
    logic s0_arready;
    logic [AXI4_LITE_DATA_BIT_WIDTH-1:0] s0_rdata;
    logic [1:0] s0_rresp;
    logic s0_rvalid;
    logic s0_rready;

    task automatic reset_bench_driven_sigs();
        s0_araddr <= '0;
        s0_arprot <= '0;
        s0_arvalid <= 1'b0;
        s0_rready <= 1'b0;
    endtask
endinterface

typedef virtual interface dut_m_if #(
    .AXI4_LITE_ADDR_BIT_WIDTH(AXI4_LITE_ADDR_BIT_WIDTH),
    .AXI4_LITE_DATA_BIT_WIDTH(AXI4_LITE_DATA_BIT_WIDTH)
) dut_v_m_if_t;

typedef virtual interface dut_s_if #(
    .AXI4_LITE_ADDR_BIT_WIDTH(AXI4_LITE_ADDR_BIT_WIDTH),
    .AXI4_LITE_DATA_BIT_WIDTH(AXI4_LITE_DATA_BIT_WIDTH)
) dut_v_s_if_t;

dut_v_m_if_t dut_v_m_if; //! virtual interface to DUT's manager interface
dut_v_s_if_t dut_v_s_if; //! virtual interface to DUT's subordinate interface
// --------------------

// ---------- instances ----------
//! interface to DUT' subordinate interface
dut_s_if #(
    .AXI4_LITE_ADDR_BIT_WIDTH(AXI4_LITE_ADDR_BIT_WIDTH),
    .AXI4_LITE_DATA_BIT_WIDTH(AXI4_LITE_DATA_BIT_WIDTH)
) dut_s_if_0 (
    .s0_aclk(r_m_clk)
);

//! interface to DUT' manager interface
dut_m_if #(
    .AXI4_LITE_ADDR_BIT_WIDTH(AXI4_LITE_ADDR_BIT_WIDTH),
    .AXI4_LITE_DATA_BIT_WIDTH(AXI4_LITE_DATA_BIT_WIDTH)
) dut_m_if_0 (
    .m0_aclk(r_s_clk)
);

//! DUT instance
a4l_rd_cdc_v0_1_0 #(
    .AXI4_LITE_ADDR_BIT_WIDTH(AXI4_LITE_ADDR_BIT_WIDTH),
    .AXI4_LITE_DATA_BIT_WIDTH(AXI4_LITE_DATA_BIT_WIDTH)
) dut (
    .s0_aclk(r_m_clk),
    .s0_sync_rst(dut_s_if_0.s0_sync_rst),
    .s0_araddr(dut_s_if_0.s0_araddr),
    .s0_arprot(dut_s_if_0.s0_arprot),
    .s0_arvalid(dut_s_if_0.s0_arvalid),
    .s0_arready(dut_s_if_0.s0_arready),
    .s0_rdata(dut_s_if_0.s0_rdata),
    .s0_rresp(dut_s_if_0.s0_rresp),
    .s0_rvalid(dut_s_if_0.s0_rvalid),
    .s0_rready(dut_s_if_0.s0_rready),

    .m0_aclk(r_s_clk),
    .m0_sync_rst(dut_m_if_0.m0_sync_rst),
    .m0_araddr(dut_m_if_0.m0_araddr),
    .m0_arprot(dut_m_if_0.m0_arprot),
    .m0_arvalid(dut_m_if_0.m0_arvalid),
    .m0_arready(dut_m_if_0.m0_arready),
    .m0_rdata(dut_m_if_0.m0_rdata),
    .m0_rresp(dut_m_if_0.m0_rresp),
    .m0_rvalid(dut_m_if_0.m0_rvalid),
    .m0_rready(dut_m_if_0.m0_rready)
);
// --------------------

// ---------- blocks ----------
//! Drives the clock.
initial forever #(M_CLK_PERIOD_NS/2) r_m_clk = ~r_m_clk;
initial forever #(S_CLK_PERIOD_NS/2) r_s_clk = ~r_s_clk;

//! Drives the manager clock domain reset signal.
task automatic drive_m_rst(ref dut_v_s_if_t v_s_if);
    @(posedge r_m_clk);
    v_s_if.s0_sync_rst <= 1'b1;
    v_s_if.reset_bench_driven_sigs();
    repeat (M_RST_DURATION_CYCLE) begin
        @(posedge r_m_clk);
    end
    v_s_if.s0_sync_rst <= 1'b0;
endtask

//! Drives the subordinate clock domain reset signal.
task automatic drive_s_rst(ref dut_v_m_if_t v_m_if);
    @(posedge r_s_clk);
    v_m_if.m0_sync_rst <= 1'b1;
    v_m_if.reset_bench_driven_sigs();
    repeat (S_RST_DURATION_CYCLE) begin
        @(posedge r_s_clk);
    end
    v_m_if.m0_sync_rst <= 1'b0;
endtask

// Issues read requests to DUT.
task automatic issue_rd_req(ref dut_v_s_if_t v_s_if);
    // TODO: Implement this.
endtask

// Issues read responses to DUT.
task automatic issue_rd_resp(ref dut_v_m_if_t v_m_if);
    // TODO: Implement this.
endtask

task automatic scenario();
    fork
        drive_m_rst(dut_v_s_if);
        drive_s_rst(dut_v_m_if);
    join
    @(posedge r_m_clk);
    @(posedge r_s_clk);
    fork
        issue_rd_req(dut_v_s_if);
        issue_rd_resp(dut_v_m_if);
    join
endtask

//! Launches scenario and manage time limit.
initial begin
    dut_v_m_if = dut_m_if_0;
    dut_v_s_if = dut_s_if_0;
    fork
        scenario();
    join_none
    #SIM_TIME_LIMIT_NS;
    $fatal(2, "Simulation timeout.");
    $finish;
end
// --------------------
endmodule

`default_nettype wire
