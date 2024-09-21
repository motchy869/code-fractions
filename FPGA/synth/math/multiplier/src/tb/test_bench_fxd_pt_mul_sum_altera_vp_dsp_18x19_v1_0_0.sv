// Verible directive
// verilog_lint: waive-start parameter-name-style
// verilog_lint: waive-start line-length

`include "../fxd_pt_mul_sum_altera_vp_dsp_18x19_v1_0_0.svh"

`default_nettype none

// timescale is defined in Makefile.

module test_bench_fxd_pt_mul_sum_altera_vp_dsp_18x19_v1_0_0;
// ---------- parameters ----------
localparam int unsigned CLK_PERIOD_NS = 8; //! clock period in ns
localparam int unsigned SIM_TIME_LIMIT_NS = 200; //! simulation time limit in ns
localparam int unsigned RST_DURATION_CYCLE = 1; //! reset duration in cycles

localparam int unsigned DUT_BW_IN_A_0 = 18; //! Details are in the DUT documentation.
localparam int unsigned DUT_BW_IN_B_0 = 19; //! ditto
localparam int unsigned DUT_BW_IN_A_1 = 18; //! ditto
localparam int unsigned DUT_BW_IN_B_1 = 19; //! ditto
localparam int unsigned DUT_BW_OUT = 16; //! ditto
localparam int unsigned DUT_BIT_SLC_OFFSET_OUT = 4; //! ditto
localparam int unsigned DUT_DSP_BLK_INPUT_STG_REG_CHAIN_LEN = 1; //! ditto
localparam int unsigned DUT_DSP_BLK_OUTPUT_STG_REG_CHAIN_LEN = 1; //! ditto
localparam bit DUT_EN_RND_HF2EVN = 1'b1; //! ditto
localparam int unsigned DUT_CYCLE_LAT = DUT_DSP_BLK_INPUT_STG_REG_CHAIN_LEN + DUT_DSP_BLK_OUTPUT_STG_REG_CHAIN_LEN + DUT_EN_RND_HF2EVN; //! DUT cycle latency
// --------------------

// ---------- parameter validation ----------
// --------------------

// ---------- functions ----------
// --------------------

// ---------- signals and storage ----------
interface dut_if #(
    parameter int unsigned BW_IN_A_0 = 16,
    parameter int unsigned BW_IN_B_0 = 16,
    parameter int unsigned BW_IN_A_1 = 16,
    parameter int unsigned BW_IN_B_1 = 16,
    parameter int unsigned BW_OUT = 16,
    parameter int unsigned BIT_SLC_OFFSET_OUT = 0
)(
    input wire logic i_clk //! clock signal
);
    // interface between upstream-side and DUT
    logic ready_to_us;
    logic input_valid;
    logic signed [BW_IN_A_0-1:0] a_0;
    logic signed [BW_IN_B_0-1:0] b_0;
    logic signed [BW_IN_A_1-1:0] a_1;
    logic signed [BW_IN_B_1-1:0] b_1;
    logic sub;

    // interface between DUT and downstream-side and DUT
    logic ready_from_ds;
    logic output_valid;
    logic signed [BW_OUT-1:0] c;

    task automatic reset_bench_driven_sigs();
        input_valid <= 1'b0;
        a_0 <= '0;
        b_0 <= '0;
        a_1 <= '0;
        b_1 <= '0;
        sub <= 1'b0;
        ready_from_ds <= 1'b0;
    endtask
endinterface

typedef virtual interface dut_if #(
    .BW_IN_A_0(DUT_BW_IN_A_0),
    .BW_IN_B_0(DUT_BW_IN_B_0),
    .BW_IN_A_1(DUT_BW_IN_A_1),
    .BW_IN_B_1(DUT_BW_IN_B_1),
    .BW_OUT(DUT_BW_OUT),
    .BIT_SLC_OFFSET_OUT(DUT_BIT_SLC_OFFSET_OUT)
) dut_vif_t;

var bit r_clk; //! clock signal
var bit r_sync_rst; //! clock synchronous reset signal

dut_vif_t dut_vif; //! virtual interface to DUT
// --------------------

// ---------- instances ----------
//! interface to DUT
dut_if #(
    .BW_IN_A_0(DUT_BW_IN_A_0),
    .BW_IN_B_0(DUT_BW_IN_B_0),
    .BW_IN_A_1(DUT_BW_IN_A_1),
    .BW_IN_B_1(DUT_BW_IN_B_1),
    .BW_OUT(DUT_BW_OUT),
    .BIT_SLC_OFFSET_OUT(DUT_BIT_SLC_OFFSET_OUT)
) dut_if_0 (.i_clk(r_clk));

//! DUT instance
fxd_pt_mul_sum_altera_vp_dsp_18x19_v1_0_0 #(
    .BW_IN_A_0(DUT_BW_IN_A_0),
    .BW_IN_B_0(DUT_BW_IN_B_0),
    .BW_IN_A_1(DUT_BW_IN_A_1),
    .BW_IN_B_1(DUT_BW_IN_B_1),
    .BW_OUT(DUT_BW_OUT),
    .BIT_SLC_OFFSET_OUT(DUT_BIT_SLC_OFFSET_OUT),
    .DSP_BLK_INPUT_STG_REG_CHAIN_LEN(DUT_DSP_BLK_INPUT_STG_REG_CHAIN_LEN),
    .DSP_BLK_OUTPUT_STG_REG_CHAIN_LEN(DUT_DSP_BLK_OUTPUT_STG_REG_CHAIN_LEN),
    .EN_RND_HF2EVN(DUT_EN_RND_HF2EVN)
) dut (
    .i_clk(r_clk),
    .i_sync_rst(r_sync_rst),

    .o_ready(dut_if_0.ready_to_us),
    .i_input_valid(dut_if_0.input_valid),
    .i_a_0(dut_if_0.a_0),
    .i_b_0(dut_if_0.b_0),
    .i_a_1(dut_if_0.a_1),
    .i_b_1(dut_if_0.b_1),
    .i_sub(dut_if_0.sub),

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
        logic signed [DUT_BW_IN_A_0-1:0] a_0;
        logic signed [DUT_BW_IN_B_0-1:0] b_0;
        logic signed [DUT_BW_IN_A_1-1:0] a_1;
        logic signed [DUT_BW_IN_B_1-1:0] b_1;
        logic sub;
        logic signed [DUT_BW_OUT-1:0] c_expected;
    } test_case_t;

    test_case_t [NUM_TEST_CASES-1:0] testCases = {
        {DUT_BW_IN_A_0'(-11_091),  DUT_BW_IN_B_0'(-162_575), DUT_BW_IN_A_1'(-101_848), DUT_BW_IN_B_1'(-155_845), 1'b0, DUT_BW_OUT'(-14_047)},
        {DUT_BW_IN_A_0'(-2_225),   DUT_BW_IN_B_0'(-232_473), DUT_BW_IN_A_1'(120_462),  DUT_BW_IN_B_1'(-92_275),  1'b0, DUT_BW_OUT'(-26_312)},
        {DUT_BW_IN_A_0'(41_716),   DUT_BW_IN_B_0'(-19_937),  DUT_BW_IN_A_1'(95_565),   DUT_BW_IN_B_1'(167_240),  1'b0, DUT_BW_OUT'(-17_245)},
        {DUT_BW_IN_A_0'(25_821),   DUT_BW_IN_B_0'(248_060),  DUT_BW_IN_A_1'(-679),     DUT_BW_IN_B_1'(97_914),   1'b0, DUT_BW_OUT'(1_983)},
        {DUT_BW_IN_A_0'(94_175),   DUT_BW_IN_B_0'(9_863),    DUT_BW_IN_A_1'(45_353),   DUT_BW_IN_B_1'(33_580),   1'b0, DUT_BW_OUT'(14_442)},
        {DUT_BW_IN_A_0'(67_102),   DUT_BW_IN_B_0'(-18_595),  DUT_BW_IN_A_1'(102_809),  DUT_BW_IN_B_1'(44_813),   1'b1, DUT_BW_OUT'(19_186)},
        {DUT_BW_IN_A_0'(-19_611),  DUT_BW_IN_B_0'(-244_298), DUT_BW_IN_A_1'(82_165),   DUT_BW_IN_B_1'(-34_428),  1'b1, DUT_BW_OUT'(-18_568)},
        {DUT_BW_IN_A_0'(9_678),    DUT_BW_IN_B_0'(13_815),   DUT_BW_IN_A_1'(18_102),   DUT_BW_IN_B_1'(-182_979), 1'b0, DUT_BW_OUT'(-21_902)},
        {DUT_BW_IN_A_0'(49_972),   DUT_BW_IN_B_0'(-190_779), DUT_BW_IN_A_1'(64_731),   DUT_BW_IN_B_1'(-128_147), 1'b0, DUT_BW_OUT'(15_380)},
        {DUT_BW_IN_A_0'(84_523),   DUT_BW_IN_B_0'(-168_039), DUT_BW_IN_A_1'(122_818),  DUT_BW_IN_B_1'(-202_889), 1'b0, DUT_BW_OUT'(-16_226)},
        {DUT_BW_IN_A_0'(-103_773), DUT_BW_IN_B_0'(12_691),   DUT_BW_IN_A_1'(-39_509),  DUT_BW_IN_B_1'(-115_333), 1'b0, DUT_BW_OUT'(-24_468)},
        {DUT_BW_IN_A_0'(-72_284),  DUT_BW_IN_B_0'(-261_782), DUT_BW_IN_A_1'(129_660),  DUT_BW_IN_B_1'(150_541),  1'b0, DUT_BW_OUT'(-3_037)},
        {DUT_BW_IN_A_0'(54_938),   DUT_BW_IN_B_0'(-40_849),  DUT_BW_IN_A_1'(-86_956),  DUT_BW_IN_B_1'(261_622),  1'b0, DUT_BW_OUT'(5_784)},
        {DUT_BW_IN_A_0'(-62_914),  DUT_BW_IN_B_0'(207_344),  DUT_BW_IN_A_1'(97_977),   DUT_BW_IN_B_1'(-110_722), 1'b0, DUT_BW_OUT'(-12_317)},
        {DUT_BW_IN_A_0'(100_428),  DUT_BW_IN_B_0'(192_947),  DUT_BW_IN_A_1'(93_946),   DUT_BW_IN_B_1'(-185_078), 1'b0, DUT_BW_OUT'(-15_858)},
        {DUT_BW_IN_A_0'(33_905),   DUT_BW_IN_B_0'(-122_300), DUT_BW_IN_A_1'(28_174),   DUT_BW_IN_B_1'(123_990),  1'b1, DUT_BW_OUT'(3_061)}
    };

    bit is_error = 1'b0;
    int unsigned cnt_input = 0;
    int unsigned cnt_output = 0;

    while (cnt_output < NUM_TEST_CASES) begin
        if (cnt_input < NUM_TEST_CASES) begin
            vif.input_valid <= 1'b1;
            vif.a_0 <= testCases[cnt_input].a_0;
            vif.b_0 <= testCases[cnt_input].b_0;
            vif.a_1 <= testCases[cnt_input].a_1;
            vif.b_1 <= testCases[cnt_input].b_1;
            vif.sub <= testCases[cnt_input].sub;
            vif.ready_from_ds <= 1'b1;
            cnt_input += 1;
        end
        if (cnt_output < NUM_TEST_CASES && vif.output_valid) begin
            if (cnt_output == 0) begin
                assert(cnt_input == DUT_CYCLE_LAT + 2) else $fatal(2, "cnt_input = %0d, expected = %0d", cnt_input, DUT_CYCLE_LAT + 1);
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
