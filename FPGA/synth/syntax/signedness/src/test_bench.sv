// Verible directive
// verilog_lint: waive-start parameter-name-style
// verilog_lint: waive-start line-length

`default_nettype none

timeunit 1ns;
timeprecision 1ps;

//! A test bench for my_avmm_agt_template.
module test_bench;
// ---------- parameters ----------
// --------------------

// ---------- parameter validation ----------
// --------------------

// ---------- functions ----------
// --------------------

// ---------- signals and storage ----------
// --------------------

// ---------- instances ----------
// --------------------

// ---------- blocks ----------
initial begin
    automatic logic unsigned [8-1:0] a = 8'h80;
    automatic logic signed [8-1:0] b = a;
    automatic logic signed [12-1:0] c = a;
    automatic logic signed [12-1:0] d = signed'(a);
    automatic logic signed [12-1:0] e = 12'(signed'(a));
    $display("a = %d\nb = %d\nc = %d\nd = %d\ne = %d\n", a, b, c, d, e);
end
// --------------------
endmodule

`default_nettype wire
