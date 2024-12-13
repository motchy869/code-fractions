// Verible directive
// verilog_lint: waive-start parameter-name-style
// verilog_lint: waive-start line-length
// verilog_lint: waive-start interface-name-style

`include "../cplx_add.svh"

`default_nettype none

module test_bench;
// ---------- parameters ----------
localparam int unsigned CLK_PERIOD_NS = 8; //! clock period in ns
localparam int unsigned SIM_TIME_LIMIT_NS = 100; //! simulation time limit in ns
localparam int unsigned RST_DURATION_CYCLE = 1; //! reset duration in cycles

localparam int unsigned BIT_WIDTH_IN = 8; //! bit width of the real and imaginary parts of the input complex numbers
localparam int unsigned BIT_WIDTH_OUT = BIT_WIDTH_IN + 1; //! bit width of the real and imaginary parts of the output complex number
// --------------------

// ---------- parameter validation ----------
// --------------------

// ---------- functions ----------
// --------------------

// ---------- signals and storage ----------
interface dut_if (
    input wire logic i_clk, //! clock signal
    cplx_num_if if_cplx_a, //! first complex number a
    cplx_num_if if_cplx_b, //! second complex number b
    cplx_num_if if_cplx_c //! a+b or a-b
);
    // signals between upstream-side and DUT
    logic ready_to_us;
    logic input_valid;
    logic sub;

    // signals between DUT and downstream-side
    logic ready_from_ds;
    logic output_valid;

    task automatic reset_bench_driven_sigs();
        input_valid <= 1'b0;
        sub <= 1'b0;
        if_cplx_a.num <= '0;
        if_cplx_b.num <= '0;
        ready_from_ds <= 1'b0;
    endtask
endinterface

typedef virtual interface dut_if dut_vif_t;

var bit r_clk; //! clock signal
var bit r_sync_rst; //! clock synchronous reset signal

dut_vif_t dut_vif; //! virtual interface to DUT
// --------------------

// ---------- instances ----------
//! sub interface to DUT
cplx_num_if #(
    .BIT_WIDTH(BIT_WIDTH_IN)
) if_cplx_a();

//! sub interface to DUT
cplx_num_if #(
    .BIT_WIDTH(BIT_WIDTH_IN)
) if_cplx_b();

//! sub interface to DUT
cplx_num_if #(
    .BIT_WIDTH(BIT_WIDTH_OUT)
) if_cplx_c();

//! top interface to DUT
dut_if dut_if_0 (
    .i_clk(r_clk),
    .if_cplx_a(if_cplx_a),
    .if_cplx_b(if_cplx_b),
    .if_cplx_c(if_cplx_c)
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
        logic signed [BIT_WIDTH_IN-1:0] re_a;
        logic signed [BIT_WIDTH_IN-1:0] im_a;
        logic signed [BIT_WIDTH_IN-1:0] re_b;
        logic signed [BIT_WIDTH_IN-1:0] im_b;
        logic sub;
        logic signed [BIT_WIDTH_OUT-1:0] re_c_exp;
        logic signed [BIT_WIDTH_OUT-1:0] im_c_exp;
    } test_case_t;

    test_case_t testCases[NUM_TEST_CASES];
    bit is_error = 1'b0;
    int unsigned cnt_input = 0;
    int unsigned cnt_output = 0;

    for (int unsigned i=0; i<NUM_TEST_CASES; ++i) begin
        const int urandom_range_max = (1<<(BIT_WIDTH_IN-1))-1;
        const int urandom_range_min = -(1<<(BIT_WIDTH_IN-1));
        testCases[i].re_a = BIT_WIDTH_IN'($urandom_range(urandom_range_min, urandom_range_max));
        testCases[i].im_a = BIT_WIDTH_IN'($urandom_range(urandom_range_min, urandom_range_max));
        testCases[i].re_b = BIT_WIDTH_IN'($urandom_range(urandom_range_min, urandom_range_max));
        testCases[i].im_b = BIT_WIDTH_IN'($urandom_range(urandom_range_min, urandom_range_max));
        testCases[i].sub = bit'($urandom_range(0, 1));
        testCases[i].re_c_exp = testCases[i].sub ? testCases[i].re_a - testCases[i].re_b : testCases[i].re_a + testCases[i].re_b;
        testCases[i].im_c_exp = testCases[i].sub ? testCases[i].im_a - testCases[i].im_b : testCases[i].im_a + testCases[i].im_b;
    end

    while (cnt_output < NUM_TEST_CASES) begin
        if (cnt_input < NUM_TEST_CASES) begin
            vif.input_valid <= 1'b1;
            vif.sub <= testCases[cnt_input].sub;
            vif.ready_from_ds <= 1'b1;
            cnt_input++;
        end
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
