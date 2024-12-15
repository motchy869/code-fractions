// Verible directive
// verilog_lint: waive-start parameter-name-style
// verilog_lint: waive-start line-length

`include "../fxd_pt2flt_pt_v0_1_0_pkg.svh"

`default_nettype none

// timescale is defined in Makefile.

module test_bench;
// ---------- parameters ----------
typedef int unsigned uint_t;

localparam uint_t CLK_PERIOD_NS = 8; //! clock period in ns
localparam uint_t SIM_TIME_LIMIT_NS = 400; //! simulation time limit in ns
localparam uint_t RST_DURATION_CYCLE = 1; //! reset duration in cycles

localparam uint_t BW_IN_INT = 4;
localparam uint_t BW_IN_FRAC = 12;
localparam uint_t BW_OUT_EXP = 8;
localparam uint_t BW_OUT_FRAC = 23;
localparam uint_t BW_IN = BW_IN_INT + BW_IN_FRAC;
localparam uint_t BW_OUT = 1+BW_OUT_EXP+BW_OUT_FRAC;
localparam uint_t DUT_CYCLE_LAT = fxd_pt2flt_pt_v0_1_0_pkg::CYC_LAT;
// --------------------

// ---------- parameter validation ----------
// --------------------

// ---------- functions ----------
// --------------------

// ---------- signals and storage ----------
var bit r_clk; //! clock signal

interface dut_if #(
    parameter int unsigned BW_IN_INT = 4,
    parameter int unsigned BW_IN_FRAC = 12,
    parameter int unsigned BW_OUT_EXP = 8,
    parameter int unsigned BW_OUT_FRAC = 23
)(
    input wire logic i_clk //! clock signal
);
    // signals between flow controller and DUT
    logic sync_rst;
    logic freeze;

    // signals between upstream-side and DUT
    logic in_valid;
    logic signed [BW_IN_INT+BW_IN_FRAC-1:0] in_val;

    // signals between DUT and downstream-side
    logic pipeline_filled;
    logic [1+BW_OUT_EXP+BW_OUT_FRAC-1:0] out_val;

    task automatic reset_bench_driven_sigs();
        freeze <= '0;
        in_valid <= 1'b0;
        in_val <= '0;
    endtask
endinterface

typedef virtual interface dut_if #(
    .BW_IN_INT(BW_IN_INT),
    .BW_IN_FRAC(BW_IN_FRAC),
    .BW_OUT_EXP(BW_OUT_EXP),
    .BW_OUT_FRAC(BW_OUT_FRAC)
) dut_vif_t;

dut_vif_t dut_vif; //! virtual interface to DUT
// --------------------

// ---------- instances ----------
//! interface to DUT
dut_if #(
    .BW_IN_INT(BW_IN_INT),
    .BW_IN_FRAC(BW_IN_FRAC),
    .BW_OUT_EXP(BW_OUT_EXP),
    .BW_OUT_FRAC(BW_OUT_FRAC)
) dut_if_0 (.i_clk(r_clk));

//! DUT instance
fxd_pt2flt_pt_v0_1_0 #(
    .BW_IN_INT(BW_IN_INT),
    .BW_IN_FRAC(BW_IN_FRAC),
    .BW_OUT_EXP(BW_OUT_EXP),
    .BW_OUT_FRAC(BW_OUT_FRAC)
) dut (
    .i_clk(r_clk),
    .i_sync_rst(dut_if_0.sync_rst),
    .i_freeze(dut_if_0.freeze),

    .i_in_valid(dut_if_0.in_valid),
    .i_in_val(dut_if_0.in_val),

    .o_pipeline_filled(dut_if_0.pipeline_filled),
    .o_out_val(dut_if_0.out_val)
);
// --------------------

// ---------- blocks ----------
//! Drives the clock.
initial forever #(CLK_PERIOD_NS/2) r_clk = ~r_clk;

//! Drives the reset signal.
task automatic drive_rst(ref dut_vif_t vif);
    @(posedge r_clk);
    vif.sync_rst <= 1'b1;
    vif.reset_bench_driven_sigs();
    repeat (RST_DURATION_CYCLE) begin
        @(posedge r_clk);
    end
    vif.sync_rst <= 1'b0;
endtask

// Feeds data to DUT.
task automatic feed_data(ref dut_vif_t vif);
    localparam int NUM_TEST_CASES = 32;

    typedef struct packed {
        logic signed [BW_IN-1:0] in_val;
        logic [BW_OUT-1:0] out_expected_val;
    } test_case_t;

    test_case_t [NUM_TEST_CASES-1:0] testCases = {
        {BW_IN'(-9265),  32'd3222324224},
        {BW_IN'(5743),   32'd1068726272},
        {BW_IN'(17749),  32'd1082829312},
        {BW_IN'(14400),  32'd1080098816},
        {BW_IN'(16379),  32'd1082125312},
        {BW_IN'(-26414), 32'd3234749440},
        {BW_IN'(5587),   32'd1068406784},
        {BW_IN'(7923),   32'd1073190912},
        {BW_IN'(17763),  32'd1082836480},
        {BW_IN'(-20349), 32'd3231644160},
        {BW_IN'(2628),   32'd1059340288},
        {BW_IN'(12935),  32'd1078598656},
        {BW_IN'(27164),  32'd1087649792},
        {BW_IN'(-9020),  32'd3222073344},
        {BW_IN'(-29653), 32'd3236407808},
        {BW_IN'(-6735),  32'd3218241536},
        {BW_IN'(-328),   32'd3181641728},
        {BW_IN'(7335),   32'd1071986688},
        {BW_IN'(18874),  32'd1083405312},
        {BW_IN'(-29547), 32'd3236353536},
        {BW_IN'(6309),   32'd1069885440},
        {BW_IN'(-12031), 32'd3225156608},
        {BW_IN'(-1398),  32'd3199123456},
        {BW_IN'(-2257),  32'd3205304320},
        {BW_IN'(-17996), 32'd3230439424},
        {BW_IN'(-1773),  32'd3202195456},
        {BW_IN'(-20054), 32'd3231493120},
        {BW_IN'(-22759), 32'd3232878080},
        {BW_IN'(11286),  32'd1076910080},
        {BW_IN'(20826),  32'd1084404736},
        {BW_IN'(-12348), 32'd3225481216},
        {BW_IN'(8872),   32'd1074438144}
    };

    bit is_error = 1'b0;
    int unsigned cnt_input = 0;
    int unsigned cnt_output = 0;

    while (cnt_output < NUM_TEST_CASES) begin
        if (cnt_input < NUM_TEST_CASES) begin
            vif.freeze <= 1'b0;
            vif.in_valid <= 1'b1;
            vif.in_val <= testCases[cnt_input].in_val;
            cnt_input += 1;
        end
        if (cnt_output < NUM_TEST_CASES && vif.pipeline_filled) begin
            if (cnt_output == 0) begin
                assert(cnt_input == DUT_CYCLE_LAT + 2) else $fatal(2, "cnt_input = %0d, expected = %0d", cnt_input, DUT_CYCLE_LAT + 2);
            end
            if (vif.out_val !== testCases[cnt_output].out_expected_val) begin
                $error("Test case %0d failed: out_val = %0d, expected = %0d", cnt_output, vif.out_val, testCases[cnt_output].out_expected_val);
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
