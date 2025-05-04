// Verible directive
// verilog_lint: waive-start parameter-name-style
// verilog_lint: waive-start line-length

`include "../pow2_bst_out_ring_buf_v0_1_0.sv"

`default_nettype none

// timescale is defined in Makefile.

// verilator lint_off MULTITOP

//! interface to DUT
interface dut_if #(
    parameter int unsigned EXP_BUF = 7,
    parameter int unsigned EXP_OUT = 6,
    parameter type T_ELEM = logic [7:0]
)(
    input wire logic i_clk //! clock signal
);
    // signals between bench and DUT's control interface
    logic freeze;
    logic [EXP_BUF:0] n_init_zero_elems;

    // signals between bench and DUT's upstream-side interface
    logic [EXP_BUF:0] free_cnt;
    logic [EXP_OUT:0] n_in;
    T_ELEM [2**EXP_OUT-1:0] in_elems;

    // signals between bench and DUT's downstream-side interface
    logic [EXP_BUF:0] cnt;
    T_ELEM [2**EXP_BUF-1:0] mrr_buf;
    logic ds_ready;

    task automatic reset_bench_driven_sigs(
        input logic [EXP_BUF:0] _n_init_zero_elems = '0
    );
        // verilator lint_off INITIALDLY
        freeze <= 1'b0;
        n_init_zero_elems <= _n_init_zero_elems;
        n_in <= '0;
        in_elems <= '{default:'0};
        ds_ready <= 1'b0;
        // verilator lint_on INITIALDLY
    endtask
endinterface

//! test bench
module test_bench;
// ---------- parameters ----------
localparam int unsigned CLK_PERIOD_NS = 8; //! clock period in ns
localparam int unsigned DELTA_T = 1; //! delta time in ns, mainly used for sampling DUT's outputs
localparam int unsigned RST_DURATION_CYCLE = 1; //! reset duration in clock cycle

localparam int unsigned EXP_BUF = 4; //! buffer size exponent
localparam int unsigned EXP_OUT = 3; //! output burst size exponent
localparam int unsigned OUT_BST_SIZE = 2**EXP_OUT; //! output burst size
localparam int unsigned MAX_N_IN = 2**EXP_OUT; //! maximal instantaneous number of input elements
localparam int unsigned MIN_N_IN = 1; //! minimal instantaneous number of input elements
localparam int unsigned N_TEST_ELEMS = 10*OUT_BST_SIZE; //! number of test elements
localparam int unsigned SIM_TIME_LIMIT_NS = (RST_DURATION_CYCLE + (N_TEST_ELEMS + MIN_N_IN - 1)/MIN_N_IN)*CLK_PERIOD_NS*11/10; //! simulation time limit in ns

typedef logic [7:0] T_ELEM; //! element data type
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
    .EXP_BUF(EXP_BUF),
    .EXP_OUT(EXP_OUT),
    .T_ELEM(T_ELEM)
) dut_vif_t;

dut_vif_t dut_vif; //! virtual interface to DUT
// --------------------

// ---------- instances ----------
//! interface to DUT
dut_if #(
    .EXP_BUF(EXP_BUF),
    .EXP_OUT(EXP_OUT),
    .T_ELEM(T_ELEM)
) dut_if (.i_clk(r_clk));

pow2_bst_out_ring_buf_v0_1_0 #(
    .EXP_BUF(EXP_BUF),
    .EXP_OUT(EXP_OUT),
    .T_ELEM(T_ELEM)
) dut (
    .i_clk(r_clk),
    .i_sync_rst(r_sync_rst),
    .i_freeze(dut_if.freeze),
    .i_n_init_zero_elems(dut_if.n_init_zero_elems),
    .o_free_cnt(dut_if.free_cnt),
    .i_n_in(dut_if.n_in),
    .i_in_elems(dut_if.in_elems),
    .o_cnt(dut_if.cnt),
    .o_mrr_buf(dut_if.mrr_buf),
    .i_ds_ready(dut_if.ds_ready)
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
    localparam int unsigned BW_ELEM = $bits(T_ELEM);
    bit is_error = 1'b0;
    int cnt_stored_elems = 0;
    int cnt_consumed_elems = 0;
    T_ELEM test_elems[] = new[N_TEST_ELEMS];
    T_ELEM test_consumed_elems[] = new[N_TEST_ELEMS];

    for (int i=0; i<N_TEST_ELEMS; ++i) begin
        test_elems[i] = BW_ELEM'($urandom_range(2**BW_ELEM-1, 0));
    end

    while (1'b1) begin
        @(posedge r_clk) begin
            if (vif.n_in > '0 && (EXP_BUF+1)'(vif.n_in) <= vif.free_cnt) begin
                cnt_stored_elems += int'(vif.n_in);
            end

            // Collects the consumed elements.
            if (cnt_consumed_elems < N_TEST_ELEMS) begin
                int num_consuming_elems = (vif.cnt >= (EXP_BUF+1)'(OUT_BST_SIZE) && vif.ds_ready) ? OUT_BST_SIZE : '0;
                // $write("Collecting: ");
                for (int unsigned i=0; i<num_consuming_elems; ++i) begin
                    test_consumed_elems[cnt_consumed_elems+i] = vif.mrr_buf[i];
                    // $write("%02h, ", vif.mrr_buf[i]);
                end
                // $write("\n");
                cnt_consumed_elems += num_consuming_elems;
                assert (cnt_consumed_elems <= N_TEST_ELEMS) else $fatal(2, "Too many elements are consumed.");
            end
        end

        #DELTA_T;

        // Shows the next storing request.
        if (cnt_stored_elems < N_TEST_ELEMS) begin
            vif.n_in = (vif.free_cnt <= (EXP_BUF+1)'(MAX_N_IN)) ? (EXP_OUT+1)'(vif.free_cnt) : (EXP_OUT+1)'(MAX_N_IN);
            for (int unsigned i=0; i<vif.n_in; ++i) begin
                vif.in_elems[i] = test_elems[cnt_stored_elems+i];
            end
        end else begin
            vif.n_in = '0;
            vif.in_elems = '{default:'0};
        end

        // Shows the next consuming request.
        if (cnt_consumed_elems < N_TEST_ELEMS) begin
            vif.ds_ready = 1'b1;
        end else begin
            vif.ds_ready = 1'b0;
            break;
        end
    end

    // Verifies the consumed elements.
    for (int i=0; i<N_TEST_ELEMS; ++i) begin
        if (test_elems[i] != test_consumed_elems[i]) begin
            is_error = 1'b1;
            $error("Mismatched element at index %0d: expected %02h, but got %02h.", i, test_elems[i], test_consumed_elems[i]);
        end
    end

    if (!is_error) begin
        $display("Test passed.");
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
