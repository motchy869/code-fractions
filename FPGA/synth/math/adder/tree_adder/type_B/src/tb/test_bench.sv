// Verible directive
// verilog_lint: waive-start parameter-name-style
// verilog_lint: waive-start line-length

`include "../tree_adder_typ_b_v0_1_0.sv"

`default_nettype none

// timescale is defined in Makefile.

// verilator lint_off MULTITOP

//! interface to DUT
interface dut_if #(
    parameter int unsigned N_IN_ELEMS,
    parameter int unsigned BW_IN_ELEM,
    parameter logic [N_IN_ELEMS-1:0][BW_IN_ELEM-1:0] MIN_VALS = '{default: {BW_IN_ELEM{1'b1}}},
    parameter logic [N_IN_ELEMS-1:0][BW_IN_ELEM-1:0] MAX_VALS = '{default: {1'b0,{(BW_IN_ELEM-1){1'b1}}}}
)(
    input wire logic i_clk //! clock signal
);
    localparam int unsigned BW_OUT_PORT = (BW_IN_ELEM-1)+$clog2(N_IN_ELEMS+1)+1;

    // signals between bench and DUT's control interface
    logic freeze;

    // signals between bench and DUT's upstream-side interface
    logic [N_IN_ELEMS-1:0][BW_IN_ELEM-1:0] elems;

    // signals between bench and DUT's downstream-side interface
    logic out_vld;
    logic signed [BW_OUT_PORT-1:0] sum;

    task automatic reset_bench_driven_sigs();
        // verilator lint_off INITIALDLY
        freeze <= 1'b1;
        elems <= '{default:'0};
        // verilator lint_on INITIALDLY
    endtask
endinterface

//! test bench
module test_bench;
// ---------- parameters ----------
localparam int unsigned CLK_PRD_NS = 8; //! clock period in ns
localparam int unsigned DELTA_T = 1; //! delta time in ns, mainly used for sampling DUT's outputs
localparam int unsigned RST_DUR_CYC = 1; //! reset duration in clock cycle
localparam int unsigned FRZ_DUR_CYC_AFTER_RST = 1; //! freeze duration in clock cycle after reset

localparam int unsigned N_IN_ELEMS = 9;
localparam int unsigned BW_IN_ELEM = 8;
localparam int unsigned BW_OUT_PORT = (BW_IN_ELEM-1)+$clog2(N_IN_ELEMS+1)+1; //! bit width of output port
localparam logic [N_IN_ELEMS-1:0][BW_IN_ELEM-1:0] MIN_VALS = {BW_IN_ELEM'(-75), BW_IN_ELEM'(-65), BW_IN_ELEM'(-55), BW_IN_ELEM'(-45), BW_IN_ELEM'(-35), BW_IN_ELEM'(-30), BW_IN_ELEM'(-25), BW_IN_ELEM'(-20), BW_IN_ELEM'(-15)};
localparam logic [N_IN_ELEMS-1:0][BW_IN_ELEM-1:0] MAX_VALS = {BW_IN_ELEM'(75), BW_IN_ELEM'(65), BW_IN_ELEM'(55), BW_IN_ELEM'(45), BW_IN_ELEM'(35), BW_IN_ELEM'(30), BW_IN_ELEM'(25), BW_IN_ELEM'(20), BW_IN_ELEM'(15)};
tree_adder_typ_b_if #(
    .N_IN_ELEMS(N_IN_ELEMS),
    .BW_IN_ELEM(BW_IN_ELEM),
    .MIN_VALS(MIN_VALS),
    .MAX_VALS(MAX_VALS)
) ta_if_0 ();
localparam int unsigned BW_SUM = ta_if_0.BW_SUM; //! bit width of the sum
localparam int unsigned CYCLE_LATENCY = $clog2(N_IN_ELEMS); //! latency in cycles

localparam int unsigned N_TEST_VECS = 100; //! number of test vectors
localparam int unsigned SIM_TIME_LIMIT_NS = (RST_DUR_CYC + FRZ_DUR_CYC_AFTER_RST + N_TEST_VECS + CYCLE_LATENCY)*CLK_PRD_NS*11/10; //! simulation time limit in ns
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
    .N_IN_ELEMS(N_IN_ELEMS),
    .BW_IN_ELEM(BW_IN_ELEM),
    .MIN_VALS(MIN_VALS),
    .MAX_VALS(MAX_VALS)
) dut_vif_t;

dut_vif_t dut_vif; //! virtual interface to DUT

typedef logic signed [BW_IN_ELEM-1:0] elem_t; //! element data type
typedef logic signed [BW_SUM-1:0] sum_t; //! sum data type
// --------------------

// ---------- instances ----------
//! interface to DUT
dut_if #(
    .N_IN_ELEMS(N_IN_ELEMS),
    .BW_IN_ELEM(BW_IN_ELEM),
    .MIN_VALS(MIN_VALS),
    .MAX_VALS(MAX_VALS)
) dut_if (.i_clk(r_clk));

//! DUT instance
tree_adder_typ_b_v0_1_0 #(

) dut (
    .i_clk(r_clk),
    .i_sync_rst(r_sync_rst),
    .i_freeze(dut_if.freeze),
    .i_elems(dut_if.elems),
    .o_out_vld(dut_if.out_vld),
    .o_sum(dut_if.sum)
);
// --------------------

// ---------- blocks ----------
initial begin
    $display("BW_SUM = %0d", BW_SUM);
end

//! Drives the clock.
initial forever #(CLK_PRD_NS/2) r_clk = ~r_clk;

//! Drives the reset signal.
task automatic drive_rst(ref dut_vif_t vif);
    // verilator lint_off INITIALDLY
    @(posedge r_clk);
    r_sync_rst <= 1'b1;
    vif.reset_bench_driven_sigs();
    repeat (RST_DUR_CYC) begin
        @(posedge r_clk);
    end
    r_sync_rst <= 1'b0;
    // verilator lint_on INITIALDLY
endtask

// Feeds data to DUT.
task automatic feed_data(ref dut_vif_t vif);
    typedef struct packed {
        sum_t actual_sum;
        sum_t exp_sum;
        elem_t [N_IN_ELEMS-1:0] elems;
    } test_vector_t;
    bit is_error = 1'b0;
    int unsigned cnt_pushed_vecs = 0;
    int unsigned cnt_popped_vecs = 0;
    test_vector_t test_vectors[] = new[N_TEST_VECS];

    // Generates test vectors.
    for (int i=0; i<N_TEST_VECS; ++i) begin
        test_vectors[i].exp_sum = 0;
        for (int j=0; j<N_IN_ELEMS; ++j) begin
            elem_t min = MIN_VALS[j], max = MAX_VALS[j];
            elem_t elem = elem_t'($urandom_range(0, 2**BW_IN_ELEM-1) - 2**(BW_IN_ELEM-1));
            if (elem < min) begin
                elem = min;
            end else if (elem > max) begin
                elem = max;
            end
            test_vectors[i].elems[j] = elem;
            test_vectors[i].exp_sum += sum_t'(test_vectors[i].elems[j]);
        end
    end

    // Drives the DUT.
    while (1'b1) begin
        @(posedge r_clk) begin
            if (cnt_popped_vecs < N_TEST_VECS) begin
                if (vif.out_vld) begin
                    test_vectors[cnt_popped_vecs].actual_sum = vif.sum;
                    ++cnt_popped_vecs;
                end
            end else if (cnt_pushed_vecs == N_TEST_VECS) begin
                break;
            end
        end

        #DELTA_T;
        vif.freeze = 1'b0;

        if (cnt_pushed_vecs < N_TEST_VECS) begin
            vif.elems = test_vectors[cnt_pushed_vecs].elems;
            ++cnt_pushed_vecs;
        end else begin
            vif.elems = '{default: '0};
        end
    end

    // Verifies the popped elements.
    for (int i=0; i<N_TEST_VECS; ++i) begin
        if (test_vectors[i].actual_sum !== test_vectors[i].exp_sum) begin
            $display("Error: test vector %0d: expected %0d, got %0d", i, test_vectors[i].exp_sum, test_vectors[i].actual_sum);
            is_error = 1'b1;
        end
    end

    if (!is_error) begin
        $display("Test passed.");
    end
endtask

task automatic scenario();
    drive_rst(dut_vif);
    feed_data(dut_vif);
    $finish;
endtask

//! Launches scenario and manage time limit.
initial begin
    $timeformat(-9, 3, " ns", 12);
    dut_vif = dut_if;
    fork
        scenario();
    join_none
    #SIM_TIME_LIMIT_NS;
    $fatal(2, "Simulation timeout.");
end
// --------------------
endmodule

// verilator lint_on MULTITOP

`default_nettype wire
