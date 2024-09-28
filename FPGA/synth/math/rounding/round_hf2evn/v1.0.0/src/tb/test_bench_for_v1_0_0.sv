// Verible directive
// verilog_lint: waive-start parameter-name-style
// verilog_lint: waive-start line-length

`default_nettype none
//! test bench for round_hf2evn_v1_0_0
module test_bench_for_v1_0_0();
// ---------- parameters ----------
localparam int CLK_PERIOD_NS = 8; //! clock period in ns
localparam int SIM_TIME_LIMIT_NS = 200; //! simulation time limit in ns

localparam int unsigned N = 8; // bit width
localparam int unsigned N_F = 2; // bit width of fractional part
// --------------------

// ---------- types ----------
typedef virtual interface round_hf2evn_v1_0_0_if #(
    .N(N),
    .N_F(N_F)
) dut_vif_t;
// --------------------

// ---------- internal signal and storage ----------
interface round_hf2evn_v1_0_0_if #(
    parameter int unsigned N = 24,
    parameter int unsigned N_F = 8
)(
    input wire logic i_clk
);
    logic signed [N-1:0] in_val;
    logic signed [N-N_F-1:0] out_val;
endinterface

var bit r_clk; //! clock signal

//! virtual interface to the DUT
dut_vif_t dut_vif;
// --------------------

// ---------- instances ----------
//! interface to the DUT
round_hf2evn_v1_0_0_if #(
    .N(N),
    .N_F(N_F)
) dut_if (
    .i_clk(r_clk)
);

//! DUT instance
round_hf2evn_v1_0_0 #(
    .N(N),
    .N_F(N_F)
) dut (
    .i_val(dut_if.in_val),
    .o_val(dut_if.out_val)
);
// --------------------

// ---------- blocks ----------
// Drive the clock.
initial forever #(CLK_PERIOD_NS/2) r_clk = ~r_clk;

task automatic drive_dut(ref dut_vif_t vif);
    localparam int unsigned NUM_VALS_TO_TEST = 21; // number of values to test

    // verilog_lint: waive-start undersized-binary-literal
    const bit [NUM_VALS_TO_TEST-1:0][N-1:0] vals = {
        8'sb1111_0110, // expected result: 6'sb1111_10
        8'sb1111_0111, // expected result: 6'sb1111_10
        8'sb1111_1000, // expected result: 6'sb1111_10
        8'sb1111_1001, // expected result: 6'sb1111_10
        8'sb1111_1010, // expected result: 6'sb1111_10
        8'sb1111_1011, // expected result: 6'sb1111_11
        8'sb1111_1100, // expected result: 6'sb1111_11
        8'sb1111_1101, // expected result: 6'sb1111_11
        8'sb1111_1110, // expected result: 6'sb0000_00
        8'sb1111_1111, // expected result: 6'sb0000_00
        8'sb0000_0000, // expected result: 6'sb0000_00
        8'sb0000_0001, // expected result: 6'sb0000_00
        8'sb0000_0010, // expected result: 6'sb0000_00
        8'sb0000_0011, // expected result: 6'sb0000_01
        8'sb0000_0100, // expected result: 6'sb0000_01
        8'sb0000_0101, // expected result: 6'sb0000_01
        8'sb0000_0110, // expected result: 6'sb0000_10
        8'sb0000_0111, // expected result: 6'sb0000_10
        8'sb0000_1000, // expected result: 6'sb0000_10
        8'sb0000_1001, // expected result: 6'sb0000_10
        8'sb0000_1010 // expected result: 6'sb0000_10
    };
    const bit [NUM_VALS_TO_TEST-1:0][N-N_F-1:0] expected_results = {
        6'sb1111_10,
        6'sb1111_10,
        6'sb1111_10,
        6'sb1111_10,
        6'sb1111_10,
        6'sb1111_11,
        6'sb1111_11,
        6'sb1111_11,
        6'sb0000_00,
        6'sb0000_00,
        6'sb0000_00,
        6'sb0000_00,
        6'sb0000_00,
        6'sb0000_01,
        6'sb0000_01,
        6'sb0000_01,
        6'sb0000_10,
        6'sb0000_10,
        6'sb0000_10,
        6'sb0000_10,
        6'sb0000_10
    };
    // verilog_lint: waive-stop

    var logic is_error = 1'b0;

    for (int unsigned i=0; i<NUM_VALS_TO_TEST; ++i) begin
        bit signed [N-N_F-1:0] result;
        @(posedge vif.i_clk);
        vif.in_val <= signed'(vals[i]);
        @(posedge vif.i_clk);
        result = vif.out_val;
        $display("i=%0d, input=8'%8b, result=6'%6b, expected=6'%6b", i, vals[i], result, expected_results[i]);
        if (result != expected_results[i]) begin
            $display("Error: result doesn't match the expected result.");
            is_error = 1'b1;
        end
    end

    if (!is_error) begin
        $display("All test cases passed.");
    end
endtask

initial begin
    dut_vif = dut_if;
    drive_dut(dut_vif);
    $finish;
end
// --------------------
endmodule

`default_nettype wire
