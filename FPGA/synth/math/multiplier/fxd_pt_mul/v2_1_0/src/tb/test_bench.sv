// Verible directive
// verilog_lint: waive-start parameter-name-style
// verilog_lint: waive-start line-length

`default_nettype none

// timescale is defined in Makefile.

module test_bench;
// ---------- parameters ----------
localparam int unsigned CLK_PERIOD_NS = 8; //! clock period in ns
localparam int unsigned SIM_TIME_LIMIT_NS = 200; //! simulation time limit in ns
localparam int unsigned RST_DURATION_CYCLE = 1; //! reset duration in cycles

localparam int unsigned DUT_BIT_WIDTH_IN_A = 16; //! Details are in the DUT documentation.
localparam int unsigned DUT_BIT_WIDTH_IN_B = 16; //! ditto
localparam int unsigned DUT_BIT_WIDTH_OUT = 12; //! ditto
localparam int unsigned DUT_BIT_SLICE_OFFSET_OUT = 15; //! ditto
localparam int unsigned DUT_MULT_INPUT_STG_PIPELINE_DEPTH = 1; //! ditto
localparam int unsigned DUT_MULT_OUTPUT_STG_PIPELINE_DEPTH = 1; //! ditto
localparam bit DUT_ENABLE_ROUNDING_HALF_TO_EVEN = 1'b1; //! ditto
localparam int unsigned DUT_CYCLE_LAT = DUT_MULT_INPUT_STG_PIPELINE_DEPTH + DUT_MULT_OUTPUT_STG_PIPELINE_DEPTH + DUT_ENABLE_ROUNDING_HALF_TO_EVEN; //! DUT cycle latency
// --------------------

// ---------- parameter validation ----------
// --------------------

// ---------- functions ----------
// --------------------

// ---------- signals and storage ----------
interface dut_if #(
    parameter int unsigned BIT_WIDTH_IN_A = 16,
    parameter int unsigned BIT_WIDTH_IN_B = 16,
    parameter int unsigned BIT_WIDTH_OUT = 16,
    parameter int unsigned BIT_SLICE_OFFSET_OUT = 0
)(
    input wire logic i_clk //! clock signal
);
    // signals between upstream-side and DUT
    logic ready_to_us;
    logic input_valid;
    logic signed [BIT_WIDTH_IN_A-1:0] a;
    logic signed [BIT_WIDTH_IN_B-1:0] b;

    // signals between DUT and downstream-side
    logic ready_from_ds;
    logic output_valid;
    logic signed [BIT_WIDTH_OUT-1:0] c;

    task automatic reset_bench_driven_sigs();
        input_valid <= 1'b0;
        a <= '0;
        b <= '0;
        ready_from_ds <= 1'b0;
    endtask
endinterface

typedef virtual interface dut_if #(
    .BIT_WIDTH_IN_A(DUT_BIT_WIDTH_IN_A),
    .BIT_WIDTH_IN_B(DUT_BIT_WIDTH_IN_B),
    .BIT_WIDTH_OUT(DUT_BIT_WIDTH_OUT),
    .BIT_SLICE_OFFSET_OUT(DUT_BIT_SLICE_OFFSET_OUT)
) dut_vif_t;

var bit r_clk; //! clock signal
var bit r_sync_rst; //! clock synchronous reset signal

dut_vif_t dut_vif; //! virtual interface to DUT
// --------------------

// ---------- instances ----------
//! interface to DUT
dut_if #(
    .BIT_WIDTH_IN_A(DUT_BIT_WIDTH_IN_A),
    .BIT_WIDTH_IN_B(DUT_BIT_WIDTH_IN_B),
    .BIT_WIDTH_OUT(DUT_BIT_WIDTH_OUT),
    .BIT_SLICE_OFFSET_OUT(DUT_BIT_SLICE_OFFSET_OUT)
) dut_if_0 (.i_clk(r_clk));

//! DUT instance
fxd_pt_mul_v2_1_0 #(
    .BIT_WIDTH_IN_A(DUT_BIT_WIDTH_IN_A),
    .BIT_WIDTH_IN_B(DUT_BIT_WIDTH_IN_B),
    .BIT_WIDTH_OUT(DUT_BIT_WIDTH_OUT),
    .BIT_SLICE_OFFSET_OUT(DUT_BIT_SLICE_OFFSET_OUT),
    .MULT_INPUT_STG_PIPELINE_DEPTH(DUT_MULT_INPUT_STG_PIPELINE_DEPTH),
    .MULT_OUTPUT_STG_PIPELINE_DEPTH(DUT_MULT_OUTPUT_STG_PIPELINE_DEPTH),
    .ENABLE_ROUNDING_HALF_TO_EVEN(DUT_ENABLE_ROUNDING_HALF_TO_EVEN)
) dut (
    .i_clk(r_clk),
    .i_sync_rst(r_sync_rst),

    .o_ready(dut_if_0.ready_to_us),
    .i_input_valid(dut_if_0.input_valid),
    .i_a(dut_if_0.a),
    .i_b(dut_if_0.b),

    .i_ds_ready(dut_if_0.ready_from_ds),
    .o_output_valid(dut_if_0.output_valid),
    .o_c(dut_if_0.c)
);
// --------------------

// ---------- blocks ----------
//! Drives the clock.
initial forever #(CLK_PERIOD_NS/2) r_clk = ~r_clk;

//! Drives the reset signal.
task automatic drive_rst(ref dut_vif_t vif);
    @(posedge r_clk);
    r_sync_rst <= 1'b1;
    vif.reset_bench_driven_sigs();
    repeat (RST_DURATION_CYCLE) begin
        @(posedge r_clk);
    end
    r_sync_rst <= 1'b0;
endtask

// Feeds data to DUT.
task automatic feed_data(ref dut_vif_t vif);
    localparam int NUM_TEST_CASES = 16;

    typedef struct packed {
        logic signed [DUT_BIT_WIDTH_IN_A-1:0] a;
        logic signed [DUT_BIT_WIDTH_IN_B-1:0] b;
        logic signed [DUT_BIT_WIDTH_OUT-1:0] c_expected;
    } test_case_t;

    test_case_t [NUM_TEST_CASES-1:0] testCases = {
        {DUT_BIT_WIDTH_IN_A'(588),     DUT_BIT_WIDTH_IN_B'(17_642),  DUT_BIT_WIDTH_OUT'(317)},
        {DUT_BIT_WIDTH_IN_A'(-12_752), DUT_BIT_WIDTH_IN_B'(-14_846), DUT_BIT_WIDTH_OUT'(1_681)},
        {DUT_BIT_WIDTH_IN_A'(-3_929),  DUT_BIT_WIDTH_IN_B'(8_848),   DUT_BIT_WIDTH_OUT'(-1_061)},
        {DUT_BIT_WIDTH_IN_A'(26_299),  DUT_BIT_WIDTH_IN_B'(3_232),   DUT_BIT_WIDTH_OUT'(-1_502)},
        {DUT_BIT_WIDTH_IN_A'(16_181),  DUT_BIT_WIDTH_IN_B'(-2_016),  DUT_BIT_WIDTH_OUT'(-996)},
        {DUT_BIT_WIDTH_IN_A'(-1_592),  DUT_BIT_WIDTH_IN_B'(-19_853), DUT_BIT_WIDTH_OUT'(965)},
        {DUT_BIT_WIDTH_IN_A'(17_979),  DUT_BIT_WIDTH_IN_B'(-13_185), DUT_BIT_WIDTH_OUT'(958)},
        {DUT_BIT_WIDTH_IN_A'(32_732),  DUT_BIT_WIDTH_IN_B'(8_110),   DUT_BIT_WIDTH_OUT'(-91)},
        {DUT_BIT_WIDTH_IN_A'(9_709),   DUT_BIT_WIDTH_IN_B'(25_513),  DUT_BIT_WIDTH_OUT'(-633)},
        {DUT_BIT_WIDTH_IN_A'(-9_118),  DUT_BIT_WIDTH_IN_B'(15_883),  DUT_BIT_WIDTH_OUT'(-324)},
        {DUT_BIT_WIDTH_IN_A'(6_277),   DUT_BIT_WIDTH_IN_B'(-19_474), DUT_BIT_WIDTH_OUT'(366)},
        {DUT_BIT_WIDTH_IN_A'(11_137),  DUT_BIT_WIDTH_IN_B'(26_767),  DUT_BIT_WIDTH_OUT'(905)},
        {DUT_BIT_WIDTH_IN_A'(-27_617), DUT_BIT_WIDTH_IN_B'(-31_356), DUT_BIT_WIDTH_OUT'(1_851)},
        {DUT_BIT_WIDTH_IN_A'(29_375),  DUT_BIT_WIDTH_IN_B'(13_770),  DUT_BIT_WIDTH_OUT'(56)},
        {DUT_BIT_WIDTH_IN_A'(32_200),  DUT_BIT_WIDTH_IN_B'(17_126),  DUT_BIT_WIDTH_OUT'(445)},
        {DUT_BIT_WIDTH_IN_A'(5_910),   DUT_BIT_WIDTH_IN_B'(-1_591),  DUT_BIT_WIDTH_OUT'(-287)}
    };

    bit is_error = 1'b0;
    int unsigned cnt_input = 0;
    int unsigned cnt_output = 0;

    while (cnt_output < NUM_TEST_CASES) begin
        if (cnt_input < NUM_TEST_CASES) begin
            vif.input_valid <= 1'b1;
            vif.a <= testCases[cnt_input].a;
            vif.b <= testCases[cnt_input].b;
            vif.ready_from_ds <= 1'b1;
            cnt_input += 1;
        end
        if (cnt_output < NUM_TEST_CASES && vif.output_valid) begin
            if (cnt_output == 0) begin
                assert(cnt_input == DUT_CYCLE_LAT + 2) else $fatal(2, "cnt_input = %0d, expected = %0d", cnt_input, DUT_CYCLE_LAT + 2);
            end
            if (vif.c != testCases[cnt_output].c_expected) begin
                $error("Test case %0d failed: c = %0d, expected = %0d", cnt_output, vif.c, testCases[cnt_output].c_expected);
                is_error = 1'b1;
            end
            cnt_output += 1;
        end
        @(posedge r_clk);
    end

    if (!is_error) begin
        $display("All test cases passed.");
    end
endtask

task automatic scenario();
    drive_rst(dut_vif);
    @(posedge r_clk);
    feed_data(dut_vif);
    @(posedge r_clk);
    $finish;
endtask

//! Launches scenario and manage time limit.
initial begin
    dut_vif = dut_if_0;
    fork
        scenario();
    join_none
    #SIM_TIME_LIMIT_NS;
    $fatal(2, "Simulation timeout.");
end
// --------------------
endmodule

`default_nettype wire
