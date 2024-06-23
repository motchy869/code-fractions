// Verible directive
// verilog_lint: waive-start parameter-name-style
// verilog_lint: waive-start line-length

`include "mty_sv_util_funcs_pkg.svh"

`default_nettype none

//! test bench for mty_sv_util_funcs_pkg
module test_bench();
// ---------- parameters ----------
// --------------------

// ---------- types ----------
// --------------------

// ---------- internal signal and storage ----------
// --------------------

// ---------- instances ----------
// --------------------

// ---------- blocks ----------
initial begin: blk_test_rounding
    localparam int N = 8; // bit width
    localparam int N_F = 2; // bit width of fractional part
    localparam int NUM_VALS_TO_TEST = 21; // number of values to test

    // verilog_lint: waive-start undersized-binary-literal
    static bit signed [NUM_VALS_TO_TEST-1:0][N-1:0] vals = {
        8'sb1111_0110, // expected result: 8'sb1111_1000
        8'sb1111_0111, // expected result: 8'sb1111_1000
        8'sb1111_1000, // expected result: 8'sb1111_1000
        8'sb1111_1001, // expected result: 8'sb1111_1000
        8'sb1111_1010, // expected result: 8'sb1111_1000
        8'sb1111_1011, // expected result: 8'sb1111_1100
        8'sb1111_1100, // expected result: 8'sb1111_1100
        8'sb1111_1101, // expected result: 8'sb1111_1100
        8'sb1111_1110, // expected result: 8'sb0000_0000
        8'sb1111_1111, // expected result: 8'sb0000_0000
        8'sb0000_0000, // expected result: 8'sb0000_0000
        8'sb0000_0001, // expected result: 8'sb0000_0000
        8'sb0000_0010, // expected result: 8'sb0000_0000
        8'sb0000_0011, // expected result: 8'sb0000_0100
        8'sb0000_0100, // expected result: 8'sb0000_0100
        8'sb0000_0101, // expected result: 8'sb0000_0100
        8'sb0000_0110, // expected result: 8'sb0000_1000
        8'sb0000_0111, // expected result: 8'sb0000_1000
        8'sb0000_1000, // expected result: 8'sb0000_1000
        8'sb0000_1001, // expected result: 8'sb0000_1000
        8'sb0000_1010 // expected result: 8'sb0000_1000
    };
    static bit signed [NUM_VALS_TO_TEST-1:0][N-1:0] expected_results = {
        8'sb1111_1000,
        8'sb1111_1000,
        8'sb1111_1000,
        8'sb1111_1000,
        8'sb1111_1000,
        8'sb1111_1100,
        8'sb1111_1100,
        8'sb1111_1100,
        8'sb0000_0000,
        8'sb0000_0000,
        8'sb0000_0000,
        8'sb0000_0000,
        8'sb0000_0000,
        8'sb0000_0100,
        8'sb0000_0100,
        8'sb0000_0100,
        8'sb0000_1000,
        8'sb0000_1000,
        8'sb0000_1000,
        8'sb0000_1000,
        8'sb0000_1000
    };
    // verilog_lint: waive-stop

    for (int i=0; i<NUM_VALS_TO_TEST; ++i) begin
        automatic bit signed [N-1:0] result= mty_sv_util_funcs_pkg::Math#(.T(bit signed [N-1:0]))::Rounding#(.N_F(N_F))::round_hf_even(vals[i]);
        $display("i=%0d, input=8'%8b, result=8'%8b, expected=8'%8b", i, vals[i], result, expected_results[i]);
        if (result != expected_results[i]) begin
            $display("Error: result doesn't match the expected result.");
        end
    end
end
// --------------------
endmodule

`default_nettype wire
