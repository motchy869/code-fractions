// Verible directive
// verilog_lint: waive-start parameter-name-style
// verilog_lint: waive-start line-length

// The header file for round_hf2evn. Details are described in .sv file.

`default_nettype none

extern module round_hf2evn #(
    localparam int unsigned N = 24,
    localparam int unsigned N_F = 8
)(
    input logic signed [N-1:0] i_val,
    output logic signed [N-N_F-1:0] o_val
);

`default_nettype wire
