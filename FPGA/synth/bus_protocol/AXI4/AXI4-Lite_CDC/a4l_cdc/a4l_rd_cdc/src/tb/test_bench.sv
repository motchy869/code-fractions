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
localparam uint_t SIM_TIME_LIMIT_NS = 700; //! simulation time limit in ns

localparam uint_t AXI4_LITE_ADDR_BIT_WIDTH = 32;
localparam uint_t AXI4_LITE_DATA_BIT_WIDTH = 32;
localparam uint_t NUM_TEST_ADDR = 8; //! number of test addresses
// --------------------

// ---------- parameter validation ----------
// --------------------

// ---------- functions ----------
// --------------------

// ---------- signals and storage ----------
typedef enum logic [1:0] {
    AXI4_RESP_OKAY = 2'b00,
    AXI4_RESP_EXOKAY = 2'b01,
    AXI4_RESP_SLVERR = 2'b10,
    AXI4_RESP_DECERR = 2'b11
} axi4_resp_t;

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

// Mocks the manager.
task automatic mock_manager(ref dut_v_s_if_t v_s_if);
    typedef struct packed {
        logic [AXI4_LITE_DATA_BIT_WIDTH-1:0] rdata;
        logic [1:0] rresp;
    } resp_t;
    const logic [AXI4_LITE_ADDR_BIT_WIDTH-1:0] addr[NUM_TEST_ADDR] = {'h9EC58EAF, 'hD543A4FA, 'h81EF1E1F, 'h1CAA6E39, 'h37E0780D, 'hEB94D829, 'h6830C3D9, 'h22F4F123};
    resp_t resp;
    logic [AXI4_LITE_DATA_BIT_WIDTH-1:0] expected_rdata;
    bit is_error = 1'b0;

    for (uint_t i=0; i<NUM_TEST_ADDR; ++i) begin
        // Shows address to the DUT.
        @(posedge v_s_if.s0_aclk);
        v_s_if.s0_araddr <= addr[i];
        v_s_if.s0_arprot <= '0;
        v_s_if.s0_arvalid <= 1'b1;

        // Waits the DUT accepts the address.
        while (1'b1) begin
            @(posedge v_s_if.s0_aclk);
            if (v_s_if.s0_arready) begin
                v_s_if.s0_araddr <= '0;
                v_s_if.s0_arvalid <= 1'b0;
                v_s_if.s0_rready <= 1'b1;
                break;
            end
        end

        // Waits the DUT returns data.
        while (1'b1) begin
            @(posedge v_s_if.s0_aclk);
            if (v_s_if.s0_rvalid) begin
                resp.rdata = v_s_if.s0_rdata;
                resp.rresp = v_s_if.s0_rresp;
                v_s_if.s0_rready <= 1'b0;
                break;
            end
        end

        // Check the response. RDATA should be bit order reversed version of ARADDR, and RRESP should be OKAY.
        expected_rdata = {<<1{addr[i]}};
        if (resp.rdata != expected_rdata || resp.rresp != AXI4_RESP_OKAY) begin
            is_error = 1'b1;
            $fatal(2, $sformatf("Unexpected response: addr=%h, rdata=%h, rresp=%h", addr[i], resp.rdata, resp.rresp));
        end
    end

    if (!is_error) begin
        $display("All test cases passed.");
    end
endtask

// Mocks the subordinate.
task automatic mock_subordinate(ref dut_v_m_if_t v_m_if);
    logic [AXI4_LITE_ADDR_BIT_WIDTH-1:0] received_addr;
    logic [AXI4_LITE_DATA_BIT_WIDTH-1:0] response_data;

    for (uint_t i=0; i<NUM_TEST_ADDR; ++i) begin
        // Waits read request from the DUT.
        @(posedge v_m_if.m0_aclk);
        v_m_if.m0_arready <= 1'b1;
        while (1'b1) begin
            @(posedge v_m_if.m0_aclk);
            if (v_m_if.m0_arvalid) begin
                received_addr = v_m_if.m0_araddr;
                v_m_if.m0_arready <= 1'b0;
                break;
            end
        end

        // Sends response to the DUT.
        response_data = {<<1{received_addr}};
        @(posedge v_m_if.m0_aclk);
        v_m_if.m0_rdata <= response_data;
        v_m_if.m0_rresp <= AXI4_RESP_OKAY;
        v_m_if.m0_rvalid <= 1'b1;

        // Waits the DUT accepts the response.
        while (1'b1) begin
            @(posedge v_m_if.m0_aclk);
            if (v_m_if.m0_rready) begin
                v_m_if.m0_rvalid <= 1'b0;
                break;
            end
        end
    end
endtask

task automatic scenario();
    fork
        drive_m_rst(dut_v_s_if);
        drive_s_rst(dut_v_m_if);
    join
    @(posedge r_m_clk);
    @(posedge r_s_clk);
    fork
        mock_manager(dut_v_s_if);
        mock_subordinate(dut_v_m_if);
    join
    $finish;
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
