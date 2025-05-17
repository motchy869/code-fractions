// Verible directive
// verilog_lint: waive-start parameter-name-style
// verilog_lint: waive-start line-length

`include "../sft_reg_slc_v0_2_0.sv"

`default_nettype none

// timescale is defined in Makefile.

// verilator lint_off MULTITOP

//! interface to DUT
interface dut_if #(
    parameter type T_ELEM = logic [7:0],
    parameter int unsigned W_I = 8,
    parameter int unsigned W_O = 4
)(
    input wire logic i_clk //! clock signal
);
    // signals between bench and DUT's control interface
    logic freeze;

    // signals between bench and DUT's upstream-side interface
    T_ELEM [W_I-1:0] in_vct;
    logic [$clog2(W_I-W_O+1)-1:0] slc_idx;

    // signals between bench and DUT's downstream-side interface
    logic out_vld;
    T_ELEM [W_O-1:0] out_vct;

    task automatic reset_bench_driven_sigs();
        // verilator lint_off INITIALDLY
        freeze <= 1'b0;
        in_vct <= '{default:'0};
        slc_idx <= '0;
        // verilator lint_on INITIALDLY
    endtask
endinterface

//! test bench
module test_bench;
// ---------- parameters ----------
localparam int unsigned CLK_PERIOD_NS = 8; //! clock period in ns
localparam int unsigned DELTA_T = 1; //! delta time in ns, mainly used for sampling DUT's outputs
localparam int unsigned RST_DURATION_CYCLE = 1; //! reset duration in clock cycle

typedef logic [7:0] T_ELEM;
localparam int unsigned W_I = 11;
localparam int unsigned W_O = 5;
localparam int unsigned CYCLE_LATENCY = W_I - W_O + 1; //! latency in cycles

localparam int unsigned N_TEST_VECS = 100; //! number of test vectors
localparam int unsigned SIM_TIME_LIMIT_NS = (RST_DURATION_CYCLE + N_TEST_VECS + CYCLE_LATENCY)*CLK_PERIOD_NS*11/10; //! simulation time limit in ns
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
    .T_ELEM(T_ELEM),
    .W_I(W_I),
    .W_O(W_O)
) dut_vif_t;

dut_vif_t dut_vif; //! virtual interface to DUT
// --------------------

// ---------- instances ----------
//! interface to DUT
dut_if #(
    .T_ELEM(T_ELEM),
    .W_I(W_I),
    .W_O(W_O)
) dut_if (.i_clk(r_clk));

sft_reg_slc_v0_2_0 #(
    .T_ELEM(T_ELEM),
    .W_I(W_I),
    .W_O(W_O)
) dut (
    .i_clk(r_clk),
    .i_sync_rst(r_sync_rst),
    .i_freeze(dut_if.freeze),
    .i_in_vct(dut_if.in_vct),
    .i_slc_idx(dut_if.slc_idx),
    .o_out_vld(dut_if.out_vld),
    .o_out_vct(dut_if.out_vct)
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
    localparam int unsigned N_SFT_REGS = W_I - W_O + 1;
    typedef struct packed {
        T_ELEM [W_O-1:0] actual_out_vct;
        T_ELEM [W_O-1:0] exp_out_vct;
        logic [$clog2(N_SFT_REGS)-1:0] slc_idx;
        T_ELEM [W_I-1:0] in_vct;
    } test_vector_t;
    bit is_error = 1'b0;
    int unsigned cnt_pushed_vecs = 0;
    int unsigned cnt_popped_vecs = 0;

    test_vector_t test_vectors[] = new[N_TEST_VECS];

    // Generates test vectors.
    for (int i=0; i<N_TEST_VECS; ++i) begin
        logic [$clog2(N_SFT_REGS)-1:0] slc_idx = $clog2(N_SFT_REGS)'($urandom_range(W_I-W_O, 0));
        for (int j=0; j<W_I; ++j) begin
            test_vectors[i].in_vct[j] = T_ELEM'($urandom_range(2**BW_ELEM-1, 0));
        end
        test_vectors[i].slc_idx = slc_idx;
        test_vectors[i].exp_out_vct = test_vectors[i].in_vct[slc_idx+:W_O];
    end

    // Drives the DUT.
    while (1'b1) begin
        #DELTA_T;

        if (cnt_pushed_vecs < N_TEST_VECS) begin
            vif.in_vct = test_vectors[cnt_pushed_vecs].in_vct;
            vif.slc_idx = test_vectors[cnt_pushed_vecs].slc_idx;
            ++cnt_pushed_vecs;
        end else begin
            vif.in_vct = '{default:'0};
            vif.slc_idx = '0;
        end

        @(posedge r_clk) begin
            if (cnt_popped_vecs < N_TEST_VECS) begin
                if (vif.out_vld) begin
                    test_vectors[cnt_popped_vecs].actual_out_vct = vif.out_vct;
                    ++cnt_popped_vecs;
                end
            end else if (cnt_pushed_vecs == N_TEST_VECS) begin
                break;
            end
        end
    end

    // Verifies the popped elements.
    for (int i=0; i<N_TEST_VECS; ++i) begin
        if (test_vectors[i].actual_out_vct != test_vectors[i].exp_out_vct) begin
            is_error = 1'b1;
            $display("Error: test vector %02d: expected %010h, actual %010h", i, test_vectors[i].exp_out_vct, test_vectors[i].actual_out_vct);
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
