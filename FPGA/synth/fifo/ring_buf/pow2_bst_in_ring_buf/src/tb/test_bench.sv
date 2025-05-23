// Verible directive
// verilog_lint: waive-start parameter-name-style
// verilog_lint: waive-start line-length

`include "../pow2_bst_in_ring_buf_v0_1_2.sv"

`default_nettype none

// timescale is defined in Makefile.

//! interface to DUT
interface dut_if #(
    parameter bit BE_UNSAFE = 1'b0,
    parameter int unsigned EXP_BUF = 7,
    parameter int unsigned EXP_IN = 6,
    parameter type T_ELEM = logic [7:0]
)(
    input wire logic i_clk //! clock signal
);
    // signals between bench and DUT's control interface
    logic freeze;
    logic [EXP_BUF:0] n_init_zero_elems;

    // signals between bench and DUT's upstream-side interface
    logic [EXP_BUF:0] free_cnt;
    logic in_ready;
    logic in_valid;
    T_ELEM [2**EXP_IN-1:0] in_elems;

    // signals between bench and DUT's downstream-side interface
    logic [EXP_BUF:0] cnt;
    T_ELEM [2**EXP_BUF-1:0] mrr_buf;
    logic [EXP_IN:0] n_out;

    task automatic reset_bench_driven_sigs(
        input logic [EXP_BUF:0] _n_init_zero_elems = '0
    );
        // verilator lint_off INITIALDLY
        freeze <= 1'b0;
        n_init_zero_elems <= _n_init_zero_elems;
        in_valid <= 1'b0;
        in_elems <= '{default:'0};
        n_out <= '0;
        // verilator lint_on INITIALDLY
    endtask
endinterface

//! test bench
module test_bench;
// ---------- parameters ----------
localparam int unsigned CLK_PERIOD_NS = 8; //! clock period in ns
localparam int unsigned DELTA_T = 1; //! delta time in ns, mainly used for sampling DUT's outputs
localparam int unsigned RST_DURATION_CYCLE = 1; //! reset duration in clock cycle

//localparam bit BE_UNSAFE = 1'b1; //! Enable unsafe configuration.
localparam bit BE_UNSAFE = 1'b0; //! Disable unsafe configuration.
localparam int unsigned EXP_BUF = 4; //! buffer size exponent
localparam int unsigned EXP_IN = 3; //! input burst size exponent
localparam int unsigned IN_BST_SIZE = 2**EXP_IN; //! input burst size
localparam int unsigned MAX_N_OUT = 2**EXP_IN; //! maximal instantaneous number of output elements
localparam int unsigned MIN_N_OUT = 1; //! minimal instantaneous number of output elements
localparam int unsigned N_TEST_ELEMS = 10*IN_BST_SIZE; //! number of test elements
localparam int unsigned SIM_TIME_LIMIT_NS = (RST_DURATION_CYCLE + (N_TEST_ELEMS + MIN_N_OUT - 1)/MIN_N_OUT)*CLK_PERIOD_NS*11/10; //! simulation time limit in ns

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
    .BE_UNSAFE(BE_UNSAFE),
    .EXP_BUF(EXP_BUF),
    .EXP_IN(EXP_IN),
    .T_ELEM(T_ELEM)
) dut_vif_t;

dut_vif_t dut_vif; //! virtual interface to DUT
// --------------------

// ---------- instances ----------
//! interface to DUT
dut_if #(
    .BE_UNSAFE(BE_UNSAFE),
    .EXP_BUF(EXP_BUF),
    .EXP_IN(EXP_IN),
    .T_ELEM(T_ELEM)
) dut_if (.i_clk(r_clk));

pow2_bst_in_ring_buf_v0_1_2 #(
    .BE_UNSAFE(BE_UNSAFE),
    .EXP_BUF(EXP_BUF),
    .EXP_IN(EXP_IN),
    .T_ELEM(T_ELEM)
) dut (
    .i_clk(r_clk),
    .i_sync_rst(r_sync_rst),
    .i_freeze(dut_if.freeze),
    .i_n_init_zero_elems(dut_if.n_init_zero_elems),
    .o_free_cnt(dut_if.free_cnt),
    .o_in_ready(dut_if.in_ready),
    .i_in_valid(dut_if.in_valid),
    .i_in_elems(dut_if.in_elems),
    .o_cnt(dut_if.cnt),
    .o_mrr_buf(dut_if.mrr_buf),
    .i_n_out(dut_if.n_out)
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
    vif.reset_bench_driven_sigs('0);
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
    int cnt_charged_elems = 0;
    int cnt_discharged_elems = 0;
    T_ELEM test_elems[] = new[N_TEST_ELEMS];
    T_ELEM test_discharged_elems[] = new[N_TEST_ELEMS];

    for (int i=0; i<N_TEST_ELEMS; ++i) begin
        test_elems[i] = BW_ELEM'($urandom_range(2**BW_ELEM-1, 0));
    end

    while (1'b1) begin
        @(posedge r_clk) begin
            if (vif.in_ready && vif.in_valid) begin
                cnt_charged_elems += IN_BST_SIZE;
            end

            // Collects the discharging elements.
            if (cnt_discharged_elems < N_TEST_ELEMS) begin
                int num_discharging_elems = int'(vif.n_out);
                // $write("Collecting: ");
                for (int unsigned i=0; i<num_discharging_elems; ++i) begin
                    test_discharged_elems[cnt_discharged_elems+i] = vif.mrr_buf[i];
                    // $write("%02h, ", vif.mrr_buf[i]);
                end
                cnt_discharged_elems += num_discharging_elems;
                // $display("  Collected %0d elements. cnt_discharged_elems: %0d", num_discharging_elems, cnt_discharged_elems);
                assert (cnt_discharged_elems <= N_TEST_ELEMS) else $fatal(2, "Too many elements are popped.");
            end
        end

        #DELTA_T;

        // Shows the next charging request.
        if (cnt_charged_elems < N_TEST_ELEMS) begin
            vif.in_valid = 1'b1;
            for (int unsigned i=0; i<IN_BST_SIZE; ++i) begin
                vif.in_elems[i] = test_elems[cnt_charged_elems+i];
            end
            // $display("  Charging elements. cnt_charged_elems: %0d", cnt_charged_elems);
        end else begin
            vif.in_valid = 1'b0;
            vif.in_elems = '0;
        end

        // Shows the next discharging request.
        if (cnt_discharged_elems < N_TEST_ELEMS) begin
            // Determines the number of elements to discharge.
            int num_discharging_elems = $urandom_range(MAX_N_OUT, MIN_N_OUT);
            if (N_TEST_ELEMS - cnt_discharged_elems < num_discharging_elems) begin // last chunk
                num_discharging_elems = N_TEST_ELEMS - cnt_discharged_elems;
            end
            if (vif.cnt < (EXP_BUF+1)'(num_discharging_elems)) begin
                num_discharging_elems = int'(vif.cnt);
            end

            vif.n_out = $clog2(MAX_N_OUT+1)'(num_discharging_elems);
        end else begin
            vif.n_out = '0;
            break;
        end
    end

    // Verifies the popped elements.
    for (int i=0; i<N_TEST_ELEMS; ++i) begin
        if (test_elems[i] != test_discharged_elems[i]) begin
            is_error = 1'b1;
            $error("Mismatched element at index %0d: expected %02h, but got %02h.", i, test_elems[i], test_discharged_elems[i]);
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

`default_nettype wire
