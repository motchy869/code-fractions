// Verible directive
// verilog_lint: waive-start parameter-name-style
// verilog_lint: waive-start line-length

`default_nettype none
//! test bench for round_hf2evn_v2_1_1
module test_bench_for_v2_1_1();
// ---------- parameters ----------
localparam int CLK_PERIOD_NS = 8; //! clock period in ns
localparam int SIM_TIME_LIMIT_NS = 300; //! simulation time limit in ns
localparam int unsigned RST_DURATION_CYCLE = 1; //! reset duration in cycles

localparam int unsigned N = 8; // bit width
localparam int unsigned N_F = 2; // bit width of fractional part
localparam bit EN_OUT_REG = 1; // enable output register
// --------------------

// ---------- types ----------
typedef virtual interface dut_if #(
    .N(N),
    .N_F(N_F)
) dut_vif_t;
// --------------------

// ---------- internal signal and storage ----------
interface dut_if #(
    parameter int unsigned N = 24,
    parameter int unsigned N_F = 8
)(
    input wire logic i_clk
);
    // signals between upstream-side and DUT
    logic ready_to_us;
    logic input_valid;
    logic signed [N-1:0] in_val;

    // signals between DUT and downstream-side
    logic ready_from_ds;
    logic output_valid;
    logic signed [N-N_F-1:0] out_val;

    task automatic reset_bench_driven_sigs();
        input_valid <= 1'b0;
        in_val <= '0;
        ready_from_ds <= 1'b0;
    endtask
endinterface

var bit r_clk; //! clock signal
var bit r_sync_rst; //! clock synchronous reset signal

//! virtual interface to the DUT
dut_vif_t dut_vif;
// --------------------

// ---------- instances ----------
//! interface to the DUT
dut_if #(
    .N(N),
    .N_F(N_F)
) dut_if_0 (
    .i_clk(r_clk)
);

//! DUT instance
round_hf2evn_v2_1_1 #(
    .N(N),
    .N_F(N_F),
    .EN_OUT_REG(EN_OUT_REG)
) dut (
    .i_clk(r_clk),
    .i_sync_rst(r_sync_rst),

    .o_ready(dut_if_0.ready_to_us),
    .i_input_valid(dut_if_0.input_valid),
    .i_val(dut_if_0.in_val),

    .i_ds_ready(dut_if_0.ready_from_ds),
    .o_output_valid(dut_if_0.output_valid),
    .o_val(dut_if_0.out_val)
);
// --------------------

// ---------- blocks ----------
// Drive the clock.
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

task automatic drive_dut(ref dut_vif_t vif);
    localparam int unsigned NUM_TEST_CASES = 21; // number of values to test

    typedef struct packed {
        bit [N-1:0] in_val;
        bit [N-N_F-1:0] expected_out_val;
    } test_case_t;

    test_case_t [NUM_TEST_CASES-1:0] testCases = {
        {8'sb1111_0110, 6'sb1111_10},
        {8'sb1111_0111, 6'sb1111_10},
        {8'sb1111_1000, 6'sb1111_10},
        {8'sb1111_1001, 6'sb1111_10},
        {8'sb1111_1010, 6'sb1111_10},
        {8'sb1111_1011, 6'sb1111_11},
        {8'sb1111_1100, 6'sb1111_11},
        {8'sb1111_1101, 6'sb1111_11},
        {8'sb1111_1110, 6'sb0000_00},
        {8'sb1111_1111, 6'sb0000_00},
        {8'sb0000_0000, 6'sb0000_00},
        {8'sb0000_0001, 6'sb0000_00},
        {8'sb0000_0010, 6'sb0000_00},
        {8'sb0000_0011, 6'sb0000_01},
        {8'sb0000_0100, 6'sb0000_01},
        {8'sb0000_0101, 6'sb0000_01},
        {8'sb0000_0110, 6'sb0000_10},
        {8'sb0000_0111, 6'sb0000_10},
        {8'sb0000_1000, 6'sb0000_10},
        {8'sb0000_1001, 6'sb0000_10},
        {8'sb0000_1010, 6'sb0000_10}
    };

    var logic is_error = 1'b0;
    int unsigned cnt_input = 0;
    int unsigned cnt_output = 0;

    while (cnt_output < NUM_TEST_CASES) begin
        if (cnt_input < NUM_TEST_CASES) begin
            vif.input_valid <= 1'b1;
            vif.in_val <= testCases[cnt_input].in_val;
            vif.ready_from_ds <= 1'b1;
            cnt_input += 1;
        end
        if (cnt_output < NUM_TEST_CASES && vif.output_valid) begin
            if (cnt_output == 0) begin
                assert(cnt_input == 1 + 2) else $fatal(2, "cnt_input = %0d, expected = %0d", cnt_input, 1 + 2);
            end
            if (vif.out_val != testCases[cnt_output].expected_out_val) begin
                $display("Test case %0d failed: expected = 6'%6b, actual = 6'%6b", cnt_output, testCases[cnt_output].expected_out_val, vif.out_val);
                is_error = 1'b1;
            end
            cnt_output += 1;
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
    drive_dut(dut_vif);
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
