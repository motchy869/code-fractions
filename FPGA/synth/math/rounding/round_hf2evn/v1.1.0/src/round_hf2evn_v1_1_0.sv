// Verible directive
// verilog_lint: waive-start parameter-name-style
// verilog_lint: waive-start line-length

`default_nettype none

//! Rounds input value by [rounding half to even](https://en.wikipedia.org/wiki/Rounding#Rounding_half_to_even) method.
//! It is **highly recommended** to place register at the output of this module to achieve timing closure.
//! ## changelog
//! ### [1.1.0] - 2024-10-31
//!  - refactor for code readability and linter compliance
//! ### [1.0.0] - N/A
//! - N/A
//! ### [0.1.0] - 2024-08-01
//! - initial release
module round_hf2evn_v1_1_0 #(
    parameter int unsigned N = 24, //! bit width of input
    parameter int unsigned N_F = 8 //! bit width of fractional part, must be greater than 0 and less than N
)(
    input wire logic signed [N-1:0] i_val, //! input value
    output wire logic signed [N-N_F-1:0] o_val //! output value (integer part only)
);
// ---------- parameters ----------
localparam int unsigned N_I = N - N_F; //! bit width of integer part
localparam bit [N_F-1:0] FRAC_PART_ZP5 = {1'b1, {(N_F-1){1'b0}}}; //! 0.5 in fractional part
// --------------------

// ---------- parameter validation ----------
generate
    if (N_F < 1) begin: gen_validate_n_f_lower_bound
        nonexistent_module_to_throw_a_custom_error_message_for invalid_parameters();
    end

    if (N_F >= N) begin: gen_validate_n_f_upper_bound
        nonexistent_module_to_throw_a_custom_error_message_for invalid_parameters();
    end
endgenerate
// --------------------

// ---------- functions ----------
// --------------------

// ---------- signals and storage ----------
wire [N_I-1:0] w_int_part; //! integer part of input value
assign w_int_part = i_val[N-1:N_F];
wire g_int_part_is_max; //! flag indicating that the integer part is max value
assign g_int_part_is_max = (w_int_part == {1'b0, {(N_I-1){1'b1}}});
wire [N_F-1:0] w_frac_part; //! fractional part of input value
assign w_frac_part = i_val[N_F-1:0];
wire g_frac_part_is_0; //! flag indicating that the fractional part is 0
assign g_frac_part_is_0 = (w_frac_part == '0);
wire g_frac_part_is_0p5; //! flag indicating that the fractional part is 0.5
assign g_frac_part_is_0p5 = (w_frac_part == FRAC_PART_ZP5);
// --------------------

// ---------- instances ----------
// --------------------

// ---------- Drives output signals. ----------
assign o_val = g_frac_part_is_0 ? signed'(w_int_part)
    // Note that the sign doesn't matter (except for clipping).
    // For example, val = -2.3, the integer and fractional parts obtained from bit slice are -3 and 0.7 respectively.
    // The fractional part always fall into the range [0, 1).
    : g_frac_part_is_0p5 ? signed'({w_int_part + N_I'(!g_int_part_is_max && w_int_part[0])})
    // Note that at this point the fractional part is neither 0 nor 0.5.
    : signed'({w_int_part + N_I'(!g_int_part_is_max && w_frac_part[N_F-1])});
// --------------------

// ---------- blocks ----------
// --------------------
endmodule

`default_nettype wire
