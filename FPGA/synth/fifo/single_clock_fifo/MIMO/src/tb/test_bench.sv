// Verible directive
// verilog_lint: waive-start parameter-name-style
// verilog_lint: waive-start line-length

`include "../mimo_fifo_v0_1_0.sv"

`default_nettype none

// timescale is defined in Makefile.

//! interface to DUT
interface dut_if #(
    parameter int unsigned MAX_N_I = 8,
    parameter int unsigned MAX_N_O = 8,
    parameter type T_E = logic
)(
    input wire logic i_clk //! clock signal
);
    // signals between bench and DUT's control interface
    logic freeze;

    // signals between bench and DUT's upstream-side interface
    logic full;
    logic [$clog2(MAX_N_I+1)-1:0] n_i;
    T_E [MAX_N_I-1:0] in_elems;

    // signals between bench and DUT's downstream-side interface
    logic empty;
    logic [$clog2(MAX_N_O+1)-1:0] n_o;
    T_E [MAX_N_O-1:0] out_elems;

    task automatic reset_bench_driven_sigs();
        // verilator lint_off INITIALDLY
        freeze <= 1'b0;
        n_i <= '0;
        in_elems <= '0;
        n_o <= '0;
        // verilator lint_on INITIALDLY
    endtask
endinterface

//! test bench
module test_bench;
// ---------- parameters ----------
localparam int unsigned CLK_PERIOD_NS = 8; //! clock period in ns
localparam int unsigned RST_DURATION_CYCLE = 1; //! reset duration in clock cycle

localparam int unsigned MAX_N_I = 7; //! maximal instantaneous number of input elements
localparam int unsigned MAX_N_O = 5; //! maximal instantaneous number of output elements
localparam int unsigned MIN_N_I = 1; //! minimal instantaneous number of input elements
localparam int unsigned MIN_N_O = 1; //! minimal instantaneous number of output elements
localparam int unsigned N_TEST_ELEMS = 50; //! number of test elements

localparam int unsigned SIM_TIME_LIMIT_NS = (RST_DURATION_CYCLE + (N_TEST_ELEMS + MIN_N_I - 1)/MIN_N_I)*CLK_PERIOD_NS*11/10; //! simulation time limit in ns
typedef logic [7:0] T_E; //! element data type
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
    .MAX_N_I(MAX_N_I),
    .MAX_N_O(MAX_N_O),
    .T_E(T_E)
) dut_vif_t;

dut_vif_t dut_vif; //! virtual interface to DUT
// --------------------

// ---------- instances ----------
//! interface to DUT
dut_if #(
    .MAX_N_I(MAX_N_I),
    .MAX_N_O(MAX_N_O),
    .T_E(T_E)
) dut_if_0 (.i_clk(r_clk));

mimo_fifo_v0_1_0 #(
    .MAX_N_I(MAX_N_I),
    .MAX_N_O(MAX_N_O),
    .T_E(T_E)
) dut (
    .i_clk(r_clk),
    .i_sync_rst(r_sync_rst),
    .i_freeze(dut_if_0.freeze),
    .o_full(dut_if_0.full),
    .i_n_i(dut_if_0.n_i),
    .i_elems(dut_if_0.in_elems),
    .o_empty(dut_if_0.empty),
    .i_n_o(dut_if_0.n_o),
    .o_elems(dut_if_0.out_elems)
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
    localparam int unsigned BW_ELEM = $bits(T_E);
    bit is_error = 1'b0;
    int cnt_pushed_elems = 0;
    int cnt_popped_elems = 0;
    T_E test_elems[] = new[N_TEST_ELEMS];
    T_E test_popped_elems[] = new[N_TEST_ELEMS];

    for (int i=0; i<N_TEST_ELEMS; ++i) begin
        test_elems[i] = BW_ELEM'($urandom_range(2**BW_ELEM-1, 0));
    end

    while (1'b1) begin
        @(posedge r_clk);
        if (vif.n_i > '0 && !vif.full) begin // Previous shown elements are accepted.
            cnt_pushed_elems += int'(vif.n_i);
        end

        if (vif.n_o > '0 && !vif.empty) begin // Previous requested elements are shown.
            int num_popping_elems = int'(vif.n_o);
            for (int i=0; i<num_popping_elems; ++i) begin
                test_popped_elems[cnt_popped_elems+i] = vif.out_elems[i];
            end
            cnt_popped_elems += num_popping_elems;
        end

        // verilator lint_off INITIALDLY
        if (cnt_pushed_elems < N_TEST_ELEMS) begin // Shows next push request.
            // Determines the number of elements to push.
            int num_pushing_elems = $urandom_range(MAX_N_I, MIN_N_I);
            if (N_TEST_ELEMS - cnt_pushed_elems < num_pushing_elems) begin // last chunk
                num_pushing_elems = N_TEST_ELEMS - cnt_pushed_elems;
            end

            vif.n_i <= $clog2(MAX_N_I+1)'(num_pushing_elems);
            for (int i=0; i<num_pushing_elems; ++i) begin
                vif.in_elems[i] <= test_elems[cnt_pushed_elems+i];
            end
        end else begin
            vif.n_i <= '0;
            vif.in_elems <= '{default:'0};
        end

        if (cnt_popped_elems < N_TEST_ELEMS - MAX_N_O) begin // Shows next pop request.
            // Determines the number of elements to pop.
            int num_popping_elems = $urandom_range(MAX_N_O, MIN_N_O);
            if (N_TEST_ELEMS - cnt_popped_elems < num_popping_elems) begin // last chunk
                num_popping_elems = N_TEST_ELEMS - cnt_popped_elems;
            end

            vif.n_o <= $clog2(MAX_N_O+1)'(num_popping_elems);
        end else begin
            vif.n_o <= '0;
            break;
        end
        // verilator lint_on INITIALDLY
    end

    // Verifies the popped elements.
    for (int i=0; i<N_TEST_ELEMS; ++i) begin
        if (test_elems[i] != test_popped_elems[i]) begin
            is_error = 1'b1;
            $error("Mismatched element at index %0d: expected %02h, but got %02h.", i, test_elems[i], test_popped_elems[i]);
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
