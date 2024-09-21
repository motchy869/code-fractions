// Verible directive
// verilog_lint: waive-start parameter-name-style
// verilog_lint: waive-start line-length
// verilog_lint: waive-start interface-name-style

`include "../cplx_num_if.svh"
`include "../cplx_add.svh"

`default_nettype none

module test_bench;
// ---------- parameters ----------
localparam int unsigned CLK_PERIOD_NS = 8; //! clock period in ns
localparam int unsigned SIM_TIME_LIMIT_NS = 200; //! simulation time limit in ns
localparam int unsigned RST_DURATION_CYCLE = 1; //! reset duration in cycles

localparam int unsigned BIT_WIDTH_IN = 8; //! bit width of the real and imaginary parts of the input complex numbers
localparam int unsigned BIT_WIDTH_OUT = BIT_WIDTH_IN + 1; //! bit width of the real and imaginary parts of the output complex number
// --------------------

// ---------- parameter validation ----------
// --------------------

// ---------- functions ----------
// --------------------

// ---------- data types ----------
cplx_num_if #(BIT_WIDTH_IN) temp_if_for_in_cplx_t();
cplx_num_if #(BIT_WIDTH_OUT) temp_if_for_out_cplx_t();

typedef type(temp_if_for_in_cplx_t.num) in_cplx_t;
typedef type(temp_if_for_out_cplx_t.num) out_cplx_t;
// --------------------

// ---------- signals and storage ----------
interface dut_if (
    input wire logic i_clk //! clock signal
);
    // interface between upstream-side and DUT
    logic ready_to_us;
    logic input_valid;
    in_cplx_t a;
    in_cplx_t b;
    logic sub;

    // interface between DUT and downstream-side and DUT
    logic ready_from_ds;
    logic output_valid;
    out_cplx_t c;

    task automatic reset_bench_driven_sigs();
        input_valid <= 1'b0;
        a <= '0;
        b <= '0;
        sub <= 1'b0;
        a <= '0;
        b <= '0;
        ready_from_ds <= 1'b0;
    endtask
endinterface

typedef virtual interface dut_if dut_vif_t;

var bit r_clk; //! clock signal
var bit r_sync_rst; //! clock synchronous reset signal

dut_vif_t dut_vif; //! virtual interface to DUT
// --------------------

// ---------- instances ----------
//! interface to DUT
dut_if dut_if_0 (.i_clk(r_clk));

//! DUT instance
cplx_add #(
    .in_cplx_t(in_cplx_t),
    .out_cplx_t(out_cplx_t)
) dut (
    .i_clk(r_clk),
    .i_sync_rst(r_sync_rst),

    .o_ready(dut_if_0.ready_to_us),
    .i_input_valid(dut_if_0.input_valid),
    .i_a(dut_if_0.a),
    .i_b(dut_if_0.b),
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
        in_cplx_t a;
        in_cplx_t b;
        logic sub;
        out_cplx_t c_exp;
    } test_case_t;

    test_case_t testCases[NUM_TEST_CASES];
    bit is_error = 1'b0;
    int unsigned cnt_input = 0;
    int unsigned cnt_output = 0;

    for (int unsigned i=0; i<NUM_TEST_CASES; ++i) begin
        const int urandom_range_max = (1<<(BIT_WIDTH_IN-1))-1;
        const int urandom_range_min = -(1<<(BIT_WIDTH_IN-1));
        testCases[i].a.re = BIT_WIDTH_IN'($urandom_range(urandom_range_min, urandom_range_max));
        testCases[i].a.im = BIT_WIDTH_IN'($urandom_range(urandom_range_min, urandom_range_max));
        testCases[i].b.re = BIT_WIDTH_IN'($urandom_range(urandom_range_min, urandom_range_max));
        testCases[i].b.im = BIT_WIDTH_IN'($urandom_range(urandom_range_min, urandom_range_max));
        testCases[i].sub = bit'($urandom_range(0, 1));
        testCases[i].c_exp.re = testCases[i].sub ? BIT_WIDTH_OUT'(testCases[i].a.re) - BIT_WIDTH_OUT'(testCases[i].b.re) : BIT_WIDTH_OUT'(testCases[i].a.re) + BIT_WIDTH_OUT'(testCases[i].b.re);
        testCases[i].c_exp.im = testCases[i].sub ? BIT_WIDTH_OUT'(testCases[i].a.im) - BIT_WIDTH_OUT'(testCases[i].b.im) : BIT_WIDTH_OUT'(testCases[i].a.im) + BIT_WIDTH_OUT'(testCases[i].b.im);
    end

    while (cnt_output < NUM_TEST_CASES) begin
        if (cnt_input < NUM_TEST_CASES) begin
            vif.input_valid <= 1'b1;
            vif.a <= testCases[cnt_input].a;
            vif.b <= testCases[cnt_input].b;
            vif.sub <= testCases[cnt_input].sub;
            vif.ready_from_ds <= 1'b1;
            cnt_input++;
        end
        if (cnt_output < NUM_TEST_CASES && vif.output_valid) begin
            if (vif.c.re != testCases[cnt_output].c_exp.re || vif.c.im != testCases[cnt_output].c_exp.im) begin
                $error($sformatf("Test case %0d failed: c.re = %0d, c.im = %0d, c_exp.re = %0d, c_exp.im = %0d", cnt_output, vif.c.re, vif.c.im, testCases[cnt_output].c_exp.re, testCases[cnt_output].c_exp.im));
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
