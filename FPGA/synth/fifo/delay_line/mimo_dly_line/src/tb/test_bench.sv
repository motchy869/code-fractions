// Verible directive
// verilog_lint: waive-start parameter-name-style
// verilog_lint: waive-start line-length

`include "../mimo_dly_line_v0_1_1.sv"

`default_nettype none

// timescale is defined in Makefile.

//! interface to DUT
interface dut_if #(
    parameter bit BE_UNSAFE = 1'b0,
    parameter int unsigned L = 16,
    parameter int unsigned MAX_N_C = 4,
    parameter int unsigned MAX_N_DC = 4,
    parameter type T_E = logic [7:0]
)(
    input wire logic i_clk //! clock signal
);
    // signals between bench and DUT's control interface
    logic freeze;
    logic [$clog2(L+1)-1:0] n_init_0_elems;
    logic [$clog2(L+1)-1:0] cnt;
    logic [$clog2(L+1)-1:0] cnt_free;
    logic [$clog2(MAX_N_C+1)-1:0] n_c;
    logic [$clog2(MAX_N_DC+1)-1:0] n_dc;

    // signals between bench and DUT's data input interface
    T_E [MAX_N_C-1:0] c_elems;

    // signals between bench and DUT's data output interface
    T_E [L-1:0] line;

    task automatic reset_bench_driven_sigs(
        input logic [$clog2(L+1)-1:0] _n_init_0_elems = '0
    );
        // verilator lint_off INITIALDLY
        freeze <= 1'b0;
        n_init_0_elems <= _n_init_0_elems;
        n_c <= '0;
        n_dc <= '0;
        c_elems <= '0;
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
localparam int unsigned L = 11; //! delay line length
localparam int unsigned MAX_N_C = 7; //! maximal instantaneous number of charging elements
localparam int unsigned MIN_N_C = 1; //! minimal instantaneous number of charging elements
localparam int unsigned MAX_N_DC = 5; //! maximal instantaneous number of discharging elements
localparam int unsigned MIN_N_DC = 1; //! minimal instantaneous number of discharging elements
localparam int unsigned N_TEST_ELEMS = 50; //! number of test elements

localparam int unsigned N_TEMP1 = MIN_N_C < MIN_N_DC ? MIN_N_C : MIN_N_DC; //! temporary variable
localparam int unsigned SIM_TIME_LIMIT_NS = (RST_DURATION_CYCLE + (N_TEST_ELEMS + N_TEMP1 - 1)/N_TEMP1)*CLK_PERIOD_NS*11/10; //! simulation time limit in ns

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
    .BE_UNSAFE(BE_UNSAFE),
    .L(L),
    .MAX_N_C(MAX_N_C),
    .MAX_N_DC(MAX_N_DC),
    .T_E(T_E)
) dut_vif_t;

dut_vif_t dut_vif; //! virtual interface to DUT
// --------------------

// ---------- instances ----------
//! interface to DUT
dut_if #(
    .BE_UNSAFE(BE_UNSAFE),
    .L(L),
    .MAX_N_C(MAX_N_C),
    .MAX_N_DC(MAX_N_DC),
    .T_E(T_E)
) dut_if (.i_clk(r_clk));

mimo_dly_line_v0_1_1 #(
    .BE_UNSAFE(BE_UNSAFE),
    .L(L),
    .MAX_N_C(MAX_N_C),
    .MAX_N_DC(MAX_N_DC),
    .T_E(T_E)
) dut (
    .i_clk(r_clk),
    .i_sync_rst(r_sync_rst),
    .i_freeze(dut_if.freeze),
    .i_n_init_0_elems(dut_if.n_init_0_elems),
    .o_cnt(dut_if.cnt),
    .o_cnt_free(dut_if.cnt_free),
    .i_n_c(dut_if.n_c),
    .i_n_dc(dut_if.n_dc),
    .i_c_elems(dut_if.c_elems),
    .o_line(dut_if.line)
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
    int cnt_charged_elems = 0;
    int cnt_discharged_elems = 0;
    T_E test_elems[] = new[N_TEST_ELEMS];
    T_E test_discharged_elems[] = new[N_TEST_ELEMS];

    for (int i=0; i<N_TEST_ELEMS; ++i) begin
        test_elems[i] = BW_ELEM'($urandom_range(2**BW_ELEM-1, 0));
    end

    while (1'b1) begin
        @(posedge r_clk) begin
            // Assumes that the previous request is processed.
            cnt_charged_elems += int'(vif.n_c);

            // Collects the discharging elements.
            if (cnt_discharged_elems < N_TEST_ELEMS) begin
                int num_discharging_elems = int'(vif.n_dc);
                // $write("Collecting: ");
                for (int unsigned i=0; i<num_discharging_elems; ++i) begin
                    test_discharged_elems[cnt_discharged_elems+i] = vif.line[i];
                    // $write("%02h, ", vif.line[i]);
                end
                cnt_discharged_elems += num_discharging_elems;
                // $display("  Collected %0d elements. cnt_discharged_elems: %0d", num_discharging_elems, cnt_discharged_elems);
                assert (cnt_discharged_elems <= N_TEST_ELEMS) else $fatal(2, "Too many elements are popped.");
            end
        end

        #DELTA_T;

        // Shows the next charging request.
        if (cnt_charged_elems < N_TEST_ELEMS) begin
            // Determines the number of elements to charge.
            int num_charging_elems = $urandom_range(MAX_N_C, MIN_N_C);
            if (N_TEST_ELEMS - cnt_charged_elems < num_charging_elems) begin // last chunk
                num_charging_elems = N_TEST_ELEMS - cnt_charged_elems;
            end
            if (vif.cnt_free < $clog2(L+1)'(num_charging_elems)) begin
                num_charging_elems = int'(vif.cnt_free);
            end

            // $write("Charging: ");
            vif.n_c = $clog2(MAX_N_C+1)'(num_charging_elems);
            for (int unsigned i=0; i<MAX_N_C; ++i) begin
                vif.c_elems[i] = (i<num_charging_elems) ? test_elems[cnt_charged_elems+i] : '0;
                // if (i<num_charging_elems) begin $write("%02h, ", vif.c_elems[i]); end
            end
            // $display("  Charging %0d elements. cnt_charged_elems: %0d", num_charging_elems, cnt_charged_elems);
        end else begin
            vif.n_c = '0;
            vif.c_elems = '0;
        end

        // Shows the next discharging request.
        if (cnt_discharged_elems < N_TEST_ELEMS) begin
            // Determines the number of elements to discharge.
            int num_discharging_elems = $urandom_range(MAX_N_DC, MIN_N_DC);
            if (N_TEST_ELEMS - cnt_discharged_elems < num_discharging_elems) begin // last chunk
                num_discharging_elems = N_TEST_ELEMS - cnt_discharged_elems;
            end
            if (vif.cnt < $clog2(L+1)'(num_discharging_elems)) begin
                num_discharging_elems = int'(vif.cnt);
            end

            vif.n_dc = $clog2(MAX_N_DC+1)'(num_discharging_elems);
        end else begin
            vif.n_dc = '0;
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
