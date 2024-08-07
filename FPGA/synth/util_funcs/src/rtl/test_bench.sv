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
task automatic test_circ_right_shift();
    localparam type T = bit;
    localparam int unsigned L = 8;
    const T [L-1:0] vec_orig = 'b0000_1111;
    const T [L-1:0][L-1:0] expected_results = {
        8'b0001_1110, // i=7
        8'b0011_1100, // i=6
        8'b0111_1000, // i=5
        8'b1111_0000, // i=4
        8'b1110_0001, // i=3
        8'b1100_0011, // i=2
        8'b1000_0111, // i=1
        8'b0000_1111 // i=0
    };

    $display("%s", "test_circ_right_shift");
    $display("vec_orig=8'b%b", vec_orig);

    for (int unsigned i=0; i<L; ++i) begin
        const T [L-1:0] result = mty_sv_util_funcs_pkg::DataStructOps#(.T(T))::Shift#(.L(L))::circ_right_shift(vec_orig, i);
        $display("i=%0d, result=8'b%b, expected=8'b%b", i, result, expected_results[i]);
        if (result != expected_results[i]) begin
            $display("Error: result doesn't match the expected result.");
        end
    end
endtask

task automatic test_round_hf_even();
    localparam int unsigned N = 8; // bit width
    localparam int unsigned N_F = 2; // bit width of fractional part
    localparam int unsigned NUM_VALS_TO_TEST = 21; // number of values to test

    // verilog_lint: waive-start undersized-binary-literal
    const bit signed [NUM_VALS_TO_TEST-1:0][N-1:0] vals = {
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
    const bit signed [NUM_VALS_TO_TEST-1:0][N-1:0] expected_results = {
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

    $display("%s", "test_round_hf_even");

    for (int unsigned i=0; i<NUM_VALS_TO_TEST; ++i) begin
        automatic bit signed [N-1:0] result = mty_sv_util_funcs_pkg::Math#(.T(bit signed [N-1:0]))::Rounding#(.N_F(N_F))::round_hf_even(vals[i]);
        $display("i=%0d, input=8'%8b, result=8'%8b, expected=8'%8b", i, vals[i], result, expected_results[i]);
        if (result != expected_results[i]) begin
            $display("Error: result doesn't match the expected result.");
        end
    end
endtask

initial begin
    test_circ_right_shift();
    test_round_hf_even();
    $finish;
end
// --------------------
endmodule

`default_nettype wire
