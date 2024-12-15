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

localparam int unsigned DUT_BW_IN_A = 18; //! Details are in the DUT documentation.
localparam int unsigned DUT_BW_IN_B = 19; //! ditto
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
    parameter int unsigned BW_IN_A = 16,
    parameter int unsigned BW_IN_B = 16,
    parameter int unsigned BW_OUT = 16,
    parameter int unsigned BIT_SLC_OFFSET_OUT = 0
)(
    input wire logic i_clk //! clock signal
);
    // signals between upstream-side and DUT
    logic ready_to_us;
    logic input_valid;
    logic signed [BW_IN_A-1:0] re_a;
    logic signed [BW_IN_A-1:0] im_a;
    logic signed [BW_IN_B-1:0] re_b;
    logic signed [BW_IN_B-1:0] im_b;

    // signals between DUT and downstream-side
    logic ready_from_ds;
    logic output_valid;
    logic signed [BW_OUT-1:0] re_c;
    logic signed [BW_OUT-1:0] im_c;

    task automatic reset_bench_driven_sigs();
        input_valid <= 1'b0;
        re_a <= '0;
        re_b <= '0;
        im_a <= '0;
        im_b <= '0;
        ready_from_ds <= 1'b0;
    endtask
endinterface

typedef virtual interface dut_if #(
    .BW_IN_A(DUT_BW_IN_A),
    .BW_IN_B(DUT_BW_IN_B),
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
    .BW_IN_A(DUT_BW_IN_A),
    .BW_IN_B(DUT_BW_IN_B),
    .BW_OUT(DUT_BW_OUT),
    .BIT_SLC_OFFSET_OUT(DUT_BIT_SLC_OFFSET_OUT)
) dut_if_0 (.i_clk(r_clk));

//! DUT instance
cplx_mul_altera_vp_dsp_18x19_v1_0_0 #(
    .BW_IN_A(DUT_BW_IN_A),
    .BW_IN_B(DUT_BW_IN_B),
    .BW_OUT(DUT_BW_OUT),
    .BIT_SLC_OFFSET_OUT(DUT_BIT_SLC_OFFSET_OUT),
    .EN_RND_HF2EVN(DUT_EN_RND_HF2EVN)
) dut (
    .i_clk(r_clk),
    .i_sync_rst(r_sync_rst),

    .o_ready(dut_if_0.ready_to_us),
    .i_input_valid(dut_if_0.input_valid),
    .i_re_a(dut_if_0.re_a),
    .i_im_a(dut_if_0.im_a),
    .i_re_b(dut_if_0.re_b),
    .i_im_b(dut_if_0.im_b),

    .i_ds_ready(dut_if_0.ready_from_ds),
    .o_output_valid(dut_if_0.output_valid),
    .o_re_c(dut_if_0.re_c),
    .o_im_c(dut_if_0.im_c)
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
        logic signed [DUT_BW_IN_A-1:0] re_a;
        logic signed [DUT_BW_IN_A-1:0] im_a;
        logic signed [DUT_BW_IN_B-1:0] re_b;
        logic signed [DUT_BW_IN_B-1:0] im_b;
        logic signed [DUT_BW_OUT-1:0] re_c_exp;
        logic signed [DUT_BW_OUT-1:0] im_c_exp;
    } test_case_t;

    test_case_t [NUM_TEST_CASES-1:0] testCases = {
        {DUT_BW_IN_A'(50_998),   DUT_BW_IN_A'(-102_247), DUT_BW_IN_B'(148_058),  DUT_BW_IN_B'(111_038),  DUT_BW_OUT'(14_759),  DUT_BW_OUT'(13_182)},
        {DUT_BW_IN_A'(-102_591), DUT_BW_IN_A'(88_015),   DUT_BW_IN_B'(150_782),  DUT_BW_IN_B'(-174_093), DUT_BW_OUT'(-20_544), DUT_BW_OUT'(17_489)},
        {DUT_BW_IN_A'(64_139),   DUT_BW_IN_A'(-81_752),  DUT_BW_IN_B'(-124_157), DUT_BW_IN_B'(-14_465),  DUT_BW_OUT'(-10_539), DUT_BW_OUT'(5_407)},
        {DUT_BW_IN_A'(60_667),   DUT_BW_IN_A'(-101_056), DUT_BW_IN_B'(33_091),   DUT_BW_IN_B'(62_490),   DUT_BW_OUT'(-1_661),  DUT_BW_OUT'(21_460)},
        {DUT_BW_IN_A'(34_555),   DUT_BW_IN_A'(54_757),   DUT_BW_IN_B'(-137_129), DUT_BW_IN_B'(26_326),   DUT_BW_OUT'(17_598),  DUT_BW_OUT'(-24_310)},
        {DUT_BW_IN_A'(-118_328), DUT_BW_IN_A'(80_912),   DUT_BW_IN_B'(-159_965), DUT_BW_IN_B'(-161_301), DUT_BW_OUT'(3_386),   DUT_BW_OUT'(-16_884)},
        {DUT_BW_IN_A'(-87_654),  DUT_BW_IN_A'(-5_283),   DUT_BW_IN_B'(117_726),  DUT_BW_IN_B'(-203_134), DUT_BW_OUT'(29_157),  DUT_BW_OUT'(-31_394)},
        {DUT_BW_IN_A'(72_389),   DUT_BW_IN_A'(81_523),   DUT_BW_IN_B'(-47_378),  DUT_BW_IN_B'(-51_687),  DUT_BW_OUT'(-18_849), DUT_BW_OUT'(19_138)},
        {DUT_BW_IN_A'(30_335),   DUT_BW_IN_A'(-34_418),  DUT_BW_IN_B'(199_780),  DUT_BW_IN_B'(-27_879),  DUT_BW_OUT'(32_076),  DUT_BW_OUT'(-1_490)},
        {DUT_BW_IN_A'(-125_839), DUT_BW_IN_A'(66_612),   DUT_BW_IN_B'(-225_429), DUT_BW_IN_B'(16_826),   DUT_BW_OUT'(-18_809), DUT_BW_OUT'(5_517)},
        {DUT_BW_IN_A'(108_696),  DUT_BW_IN_A'(-31_760),  DUT_BW_IN_B'(222_482),  DUT_BW_IN_B'(-205_476), DUT_BW_OUT'(903),     DUT_BW_OUT'(-29_608)},
        {DUT_BW_IN_A'(107_635),  DUT_BW_IN_A'(-54_437),  DUT_BW_IN_B'(-231_955), DUT_BW_IN_B'(-24_275),  DUT_BW_OUT'(-8_392),  DUT_BW_OUT'(12_119)},
        {DUT_BW_IN_A'(-119_900), DUT_BW_IN_A'(-18_819),  DUT_BW_IN_B'(-16_301),  DUT_BW_IN_B'(107_207),  DUT_BW_OUT'(784),     DUT_BW_OUT'(-5_648)},
        {DUT_BW_IN_A'(-7_117),   DUT_BW_IN_A'(80_541),   DUT_BW_IN_B'(175_606),  DUT_BW_IN_B'(147_324),  DUT_BW_OUT'(11_151),  DUT_BW_OUT'(22_553)},
        {DUT_BW_IN_A'(106_182),  DUT_BW_IN_A'(-117_151), DUT_BW_IN_B'(138_179),  DUT_BW_IN_B'(242_635),  DUT_BW_OUT'(-29_170), DUT_BW_OUT'(4_094)},
        {DUT_BW_IN_A'(-28_538),  DUT_BW_IN_A'(-127_202), DUT_BW_IN_B'(-184_004), DUT_BW_IN_B'(13_277),   DUT_BW_OUT'(30_696),  DUT_BW_OUT'(3_051)}
    };

    bit is_error = 1'b0;
    int unsigned cnt_input = 0;
    int unsigned cnt_output = 0;

    while (cnt_output < NUM_TEST_CASES) begin
        if (cnt_input < NUM_TEST_CASES) begin
            vif.input_valid <= 1'b1;
            vif.re_a <= testCases[cnt_input].re_a;
            vif.im_a <= testCases[cnt_input].im_a;
            vif.re_b <= testCases[cnt_input].re_b;
            vif.im_b <= testCases[cnt_input].im_b;
            vif.ready_from_ds <= 1'b1;
            cnt_input++;
        end
        if (cnt_output < NUM_TEST_CASES && vif.output_valid) begin
            if (vif.re_c != testCases[cnt_output].re_c_exp || vif.im_c != testCases[cnt_output].im_c_exp) begin
                $error($sformatf("Test case %0d failed: re_c = %0d, im_c = %0d, expected re_c = %0d, expected im_c = %0d", cnt_output, vif.re_c, vif.im_c, testCases[cnt_output].re_c_exp, testCases[cnt_output].im_c_exp));
                is_error = 1'b1;
            end
            cnt_output++;
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
