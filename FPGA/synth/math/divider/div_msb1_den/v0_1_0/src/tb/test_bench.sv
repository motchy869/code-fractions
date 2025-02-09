// Verible directive
// verilog_lint: waive-start parameter-name-style
// verilog_lint: waive-start line-length

`include "../div_msb1_den_v0_1_0_pkg.svh"
`include "../div_msb1_den_v0_1_0.sv"

`default_nettype none

// timescale is defined in Makefile.

//! interface to DUT
interface dut_if #(
    parameter int unsigned BW_NUM = 8,
    parameter int unsigned BW_DEN = 4
)(
    input wire logic i_clk //! clock signal
);
    // signals between bench and DUT's control interface
    logic freeze;

    // signals between bench and DUT's upstream-side interface
    logic [BW_NUM-1:0] num;
    logic [BW_DEN-1:0] den;

    // signals between bench and DUT's downstream-side interface
    logic [BW_NUM-BW_DEN:0] quo;
    logic [BW_DEN-1:0] rem;

    task automatic reset_bench_driven_sigs();
        // verilator lint_off INITIALDLY
        freeze <= 1'b0;
        num <= '0;
        den <= '0;
        // verilator lint_on INITIALDLY
    endtask
endinterface

//! test bench
module test_bench;
// ---------- parameters ----------
localparam int unsigned CLK_PERIOD_NS = 8; //! clock period in ns
localparam int unsigned SIM_TIME_LIMIT_NS = 250; //! simulation time limit in ns
localparam int unsigned RST_DURATION_CYCLE = 1; //! reset duration in clock cycle

localparam int unsigned BW_NUM = 8; //! bit width of the numerator
localparam int unsigned BW_DEN = 4; //! bit width of the denominator
localparam int unsigned BW_QUO = BW_NUM - BW_DEN + 1; //! bit width of the quotient
localparam int unsigned LAT_CYC = div_msb1_den_v0_1_0_pkg::lat_cyc(BW_NUM, BW_DEN); //! latency in clock cycle
// --------------------

// ---------- parameter validation ----------
// --------------------

// ---------- functions ----------
// --------------------

// ---------- signals and storage ----------
var bit r_clk; //! clock signal
var bit r_sync_rst; //! clock synchronous reset signal

//! virtual interface to DUT
typedef virtual interface dut_if #(
    .BW_NUM(BW_NUM),
    .BW_DEN(BW_DEN)
) dut_vif_t;

dut_vif_t dut_vif; //! virtual interface to DUT
// --------------------

// ---------- instances ----------
//! interface to DUT
dut_if #(
    .BW_NUM(BW_NUM),
    .BW_DEN(BW_DEN)
) dut_if_0 (.i_clk(r_clk));

//! DUT instance
div_msb1_den_v0_1_0 #(
    .BW_NUM(BW_NUM),
    .BW_DEN(BW_DEN)
) dut (
    .i_clk(r_clk),
    .i_sync_rst(r_sync_rst),
    .i_freeze(dut_if_0.freeze),
    .i_num(dut_if_0.num),
    .i_den(dut_if_0.den),
    .o_quo(dut_if_0.quo),
    .o_rem(dut_if_0.rem)
);
// --------------------

// ---------- blocks ----------
//! Drives the clock.
initial forever #(CLK_PERIOD_NS/2) r_clk = ~r_clk;

//! Drives the reset signal.
task automatic drive_rst(ref dut_vif_t vif);
    // verilator lint_off INITIALDLY
    @(posedge r_clk);
    r_sync_rst <= 1'b1;
    vif.reset_bench_driven_sigs();
    repeat (RST_DURATION_CYCLE) begin
        @(posedge r_clk);
    end
    r_sync_rst <= 1'b0;
    // verilator lint_on INITIALDLY
endtask

// Feeds data to DUT.
task automatic feed_data(ref dut_vif_t vif);
    localparam int unsigned NUM_TEST_VEC = 19;

    typedef struct packed {
        logic [BW_NUM-1:0] num;
        logic [BW_DEN-1:0] den;
        logic [BW_QUO-1:0] quo;
        logic [BW_DEN-1:0] rem;
    } test_vec_t;

    test_vec_t [NUM_TEST_VEC-1:0] testVecs = {
        {BW_NUM'(84),  BW_DEN'(15), BW_QUO'(5),  BW_DEN'(9)},
        {BW_NUM'(83),  BW_DEN'(12), BW_QUO'(6),  BW_DEN'(11)},
        {BW_NUM'(132), BW_DEN'(11), BW_QUO'(12), BW_DEN'(0)},
        {BW_NUM'(189), BW_DEN'(10), BW_QUO'(18), BW_DEN'(9)},
        {BW_NUM'(54),  BW_DEN'(9),  BW_QUO'(6),  BW_DEN'(0)},
        {BW_NUM'(53),  BW_DEN'(15), BW_QUO'(3),  BW_DEN'(8)},
        {BW_NUM'(55),  BW_DEN'(10), BW_QUO'(5),  BW_DEN'(5)},
        {BW_NUM'(95),  BW_DEN'(12), BW_QUO'(7),  BW_DEN'(11)},
        {BW_NUM'(18),  BW_DEN'(11), BW_QUO'(1),  BW_DEN'(7)},
        {BW_NUM'(0),   BW_DEN'(9),  BW_QUO'(0),  BW_DEN'(0)},
        {BW_NUM'(172), BW_DEN'(11), BW_QUO'(15), BW_DEN'(7)},
        {BW_NUM'(83),  BW_DEN'(12), BW_QUO'(6),  BW_DEN'(11)},
        {BW_NUM'(176), BW_DEN'(12), BW_QUO'(14), BW_DEN'(8)},
        {BW_NUM'(244), BW_DEN'(14), BW_QUO'(17), BW_DEN'(6)},
        {BW_NUM'(177), BW_DEN'(8),  BW_QUO'(22), BW_DEN'(1)},
        {BW_NUM'(159), BW_DEN'(11), BW_QUO'(14), BW_DEN'(5)},
        {BW_NUM'(222), BW_DEN'(10), BW_QUO'(22), BW_DEN'(2)},
        {BW_NUM'(185), BW_DEN'(8),  BW_QUO'(23), BW_DEN'(1)},
        {BW_NUM'(190), BW_DEN'(9),  BW_QUO'(21), BW_DEN'(1)}
    };

    bit is_error = 1'b0;
    int unsigned cnt_input = 0;
    int unsigned cnt_output = 0;

    // verilator lint_off INITIALDLY
    while (cnt_output < NUM_TEST_VEC) begin
        if (cnt_input < NUM_TEST_VEC) begin
            vif.num <= testVecs[cnt_input].num;
            vif.den <= testVecs[cnt_input].den;
            cnt_input += 1;
        end
        @(posedge r_clk);
        if (cnt_input >= LAT_CYC+1 && cnt_output < NUM_TEST_VEC) begin
            if (vif.quo !== testVecs[cnt_output].quo || vif.rem !== testVecs[cnt_output].rem) begin
                $display("Test case %0d failed. quo=%0d, rem=%0d, expected: quo=%0d, rem=%0d",
                    cnt_output, vif.quo, vif.rem, testVecs[cnt_output].quo, testVecs[cnt_output].rem);
                is_error = 1'b1;
            end
            cnt_output += 1;
        end
    end
    // verilator lint_on INITIALDLY

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
    $timeformat(-9, 3, " ns", 12);
    dut_vif = dut_if_0;
    fork
        scenario();
    join_none
    #SIM_TIME_LIMIT_NS;
    $fatal(2, "Simulation timeout.");
end
// --------------------
endmodule
