// Verible directive
// verilog_lint: waive-start parameter-name-style
// verilog_lint: waive-start line-length

`include "../cnt_leading_zeros_v0_1_0_pkg.svh"

`default_nettype none

// timescale is defined in Makefile.

module test_bench;
// ---------- parameters ----------
localparam int unsigned CLK_PERIOD_NS = 8; //! clock period in ns
localparam int unsigned SIM_TIME_LIMIT_NS = 400; //! simulation time limit in ns
localparam int unsigned RST_DURATION_CYCLE = 1; //! reset duration in cycles

localparam int unsigned BW_IN = 8;
localparam int unsigned INPUT_REG_CHAIN_LEN = 1;
localparam int unsigned OUTPUT_REG_CHAIN_LEN = 1;
localparam int unsigned BW_OUT = $clog2(BW_IN+1);
localparam int unsigned DUT_CYCLE_LAT = cnt_leading_zeros_v0_1_0_pkg::cycle_latency(INPUT_REG_CHAIN_LEN, OUTPUT_REG_CHAIN_LEN);
// --------------------

// ---------- parameter validation ----------
// --------------------

// ---------- functions ----------
// --------------------

// ---------- signals and storage ----------
interface dut_if #(
    parameter int unsigned BW_IN = 8,
    parameter int unsigned INPUT_REG_CHAIN_LEN = 1,
    parameter int unsigned OUTPUT_REG_CHAIN_LEN = 1
)(
    input wire logic i_clk //! clock signal
);
    // signals between flow controller and DUT
    logic sync_rst;
    logic freeze;

    // signals between upstream-side and DUT
    logic in_valid;
    logic [BW_IN-1:0] in_val;

    // signals between DUT and downstream-side
    logic pipeline_filled;
    logic [BW_OUT-1:0] out_val;

    task automatic reset_bench_driven_sigs();
        freeze <= '0;
        in_valid <= 1'b0;
        in_val <= '0;
    endtask
endinterface

typedef virtual interface dut_if #(
    .BW_IN(BW_IN),
    .INPUT_REG_CHAIN_LEN(INPUT_REG_CHAIN_LEN),
    .OUTPUT_REG_CHAIN_LEN(OUTPUT_REG_CHAIN_LEN)
) dut_vif_t;

var bit r_clk; //! clock signal

dut_vif_t dut_vif; //! virtual interface to DUT
// --------------------

// ---------- instances ----------
//! interface to DUT
dut_if #(
    .BW_IN(BW_IN),
    .INPUT_REG_CHAIN_LEN(INPUT_REG_CHAIN_LEN),
    .OUTPUT_REG_CHAIN_LEN(OUTPUT_REG_CHAIN_LEN)
) dut_if_0 (.i_clk(r_clk));

//! DUT instance
cnt_leading_zeros_v0_1_0 #(
    .BW_IN(BW_IN),
    .INPUT_REG_CHAIN_LEN(INPUT_REG_CHAIN_LEN),
    .OUTPUT_REG_CHAIN_LEN(OUTPUT_REG_CHAIN_LEN)
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
        logic signed [BW_OUT-1:0] out_expected_val;
    } test_case_t;

    test_case_t [NUM_TEST_CASES-1:0] testCases = {
        {BW_IN'(78),  BW_OUT'(1)},
        {BW_IN'(118), BW_OUT'(1)},
        {BW_IN'(252), BW_OUT'(0)},
        {BW_IN'(205), BW_OUT'(0)},
        {BW_IN'(32),  BW_OUT'(2)},
        {BW_IN'(34),  BW_OUT'(2)},
        {BW_IN'(145), BW_OUT'(0)},
        {BW_IN'(233), BW_OUT'(0)},
        {BW_IN'(65),  BW_OUT'(1)},
        {BW_IN'(95),  BW_OUT'(1)},
        {BW_IN'(1),   BW_OUT'(7)},
        {BW_IN'(122), BW_OUT'(1)},
        {BW_IN'(150), BW_OUT'(0)},
        {BW_IN'(135), BW_OUT'(0)},
        {BW_IN'(2),   BW_OUT'(6)},
        {BW_IN'(169), BW_OUT'(0)},
        {BW_IN'(103), BW_OUT'(1)},
        {BW_IN'(219), BW_OUT'(0)},
        {BW_IN'(205), BW_OUT'(0)},
        {BW_IN'(151), BW_OUT'(0)},
        {BW_IN'(6),   BW_OUT'(5)},
        {BW_IN'(186), BW_OUT'(0)},
        {BW_IN'(162), BW_OUT'(0)},
        {BW_IN'(6),   BW_OUT'(5)},
        {BW_IN'(130), BW_OUT'(0)},
        {BW_IN'(77),  BW_OUT'(1)},
        {BW_IN'(71),  BW_OUT'(1)},
        {BW_IN'(203), BW_OUT'(0)},
        {BW_IN'(215), BW_OUT'(0)},
        {BW_IN'(42),  BW_OUT'(2)},
        {BW_IN'(127), BW_OUT'(1)},
        {BW_IN'(0),   BW_OUT'(8)}
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
