// Verible directive
// verilog_lint: waive-start parameter-name-style
// verilog_lint: waive-start line-length

`include "../sgl_clk_pipe_fifo.sv"

`default_nettype none

// timescale is defined in Makefile.

// verilator lint_off MULTITOP

//! interface to DUT
interface dut_if #(
    parameter type T_ELEM = logic [7:0],
    parameter int DEPTH = 16
)(
    input wire logic i_clk //! clock signal
);
    // signals between bench and DUT's upstream-side interface
    logic wr_en;
    T_ELEM in_elem;
    logic full;

    // signals between bench and DUT's downstream-side interface
    logic rd_en;
    T_ELEM out_elem;
    logic empty;

    task automatic reset_bench_driven_sigs();
        // verilator lint_off INITIALDLY
        wr_en <= 1'b0;
        in_elem <= '{default:'0};
        rd_en <= 1'b0;
        // verilator lint_on INITIALDLY
    endtask
endinterface

//! test bench
module test_bench;
// ---------- parameters ----------
localparam int unsigned CLK_PRD_NS = 8; //! clock period in ns
localparam int unsigned DELTA_T = 1; //! delta time in ns, mainly used for sampling DUT's outputs
localparam int unsigned RST_DUR_CYC = 1; //! reset duration in clock cycle
// localparam int unsigned FRZ_DUR_CYC_AFTER_RST = 1; //! freeze duration in clock cycle after reset

localparam int unsigned BW_ELEM = 8; //! bit width of FIFO element
localparam int unsigned FIFO_DEPTH = 16; //! FIFO depth
localparam int unsigned N_TEST_VECS = 32; //! number of elements (test vectors) to be written into the FIFO
localparam int unsigned SIM_TIME_LIMIT_NS = (RST_DUR_CYC + /*FRZ_DUR_CYC_AFTER_RST +*/ N_TEST_VECS /*+ CYCLE_LATENCY*/)*CLK_PRD_NS*100; //! simulation time limit in ns
// --------------------

// ---------- parameter validation ----------
// --------------------

// ---------- functions ----------
// --------------------

// ---------- signals and storage ----------
var bit r_clk; //! clock signal
var bit r_sync_rst; //! clock synchronous reset signal

typedef logic [BW_ELEM-1:0] elem_t; //! element data type

//! virtual interface to DUT
typedef virtual interface dut_if #(
    .T_ELEM(elem_t),
    .DEPTH(FIFO_DEPTH)
) dut_vif_t;

dut_vif_t dut_vif; //! virtual interface to DUT
// --------------------

// ---------- instances ----------
//! interface to DUT
dut_if #(
    .T_ELEM(elem_t),
    .DEPTH(FIFO_DEPTH)
) dut_if (.i_clk(r_clk));

//! DUT instance
sgl_clk_pipe_fifo #(
    .T_ELEM(elem_t),
    .DEPTH(FIFO_DEPTH)
) dut (
    .i_clk(r_clk),
    .i_sync_rst(r_sync_rst),
    .i_wr_en(dut_if.wr_en),
    .i_in_elem(dut_if.in_elem),
    .o_full(dut_if.full),
    .i_rd_en(dut_if.rd_en),
    .o_out_elem(dut_if.out_elem),
    .o_empty(dut_if.empty)
);
// --------------------

// ---------- blocks ----------
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
        elem_t actual_val;
        elem_t exp_val;
    } test_vec_t;
    bit is_error = 1'b0;
    int unsigned cnt_pushed_vecs = 0;
    int unsigned cnt_popped_vecs = 0;
    test_vec_t test_vecs[] = new[N_TEST_VECS];

    // Generates test vectors.
    for (int i=0; i<N_TEST_VECS; ++i) begin
        test_vecs[i].exp_val = elem_t'(i);
    end

    // Drives the DUT.
    while (cnt_popped_vecs < N_TEST_VECS) begin
        logic nxt_wr_en, nxt_rd_en;

        @(posedge r_clk) begin
            // pop
            if (cnt_popped_vecs < N_TEST_VECS && !vif.empty && vif.rd_en) begin
                test_vecs[cnt_popped_vecs].actual_val = vif.out_elem;
                cnt_popped_vecs++;
            end

            // push
            if (cnt_pushed_vecs < N_TEST_VECS && !vif.full && vif.wr_en) begin
                cnt_pushed_vecs++;
            end
        end

        #DELTA_T;

        nxt_wr_en = (cnt_pushed_vecs < N_TEST_VECS) ? 1'($urandom_range(0, 99) & 1) : 1'b0;
        nxt_rd_en = (cnt_popped_vecs < N_TEST_VECS) ? 1'($urandom_range(0, 99) & 1) : 1'b0;
        vif.wr_en = nxt_wr_en;
        vif.in_elem = nxt_wr_en ? test_vecs[cnt_pushed_vecs].exp_val : '{default:'0};
        vif.rd_en = nxt_rd_en;
    end

    // Verifies the popped elements.
    for (int i=0; i<N_TEST_VECS; ++i) begin
        if (test_vecs[i].actual_val != test_vecs[i].exp_val) begin
            $display("Error: expected value %0d, got %0d at index %0d.", test_vecs[i].exp_val, test_vecs[i].actual_val, i);
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
