// Verible directive
// verilog_lint: waive-start parameter-name-style
// verilog_lint: waive-start line-length

`default_nettype none

//! Rounds input value by [rounding half to even](https://en.wikipedia.org/wiki/Rounding#Rounding_half_to_even) method.
//! Optional output register is available.
//! - When the output register is enabled, the cycle latency of this module is 1.
//! - When the output register is disabled, this module is just a **combinational** logic and timing signals such as clock, reset, valid, ready are not used.
//!
//! ![brief schematic diagram](../doc/module_schematic_diagram.png "brief schematic diagram")
//!
//! ## Changelog
//! ### [2.0.0] - 2024-09-29
//! - added output register
//! ### [1.0.0] - 2024-08-01
//! - initial release
module round_hf2evn_v2_0_0 #(
    parameter int unsigned N = 24, //! bit width of input
    parameter int unsigned N_F = 8, //! bit width of fractional part, must be greater than 0 and less than N
    parameter bit EN_OUT_REG = 0 //! Enable output register. 0/1: disable/enable
)(
    input wire logic i_clk, //! input clock, used only when ```EN_OUT_REG``` is 1.
    input wire logic i_sync_rst, //! input reset signal synchronous to the input clock, used only when ```EN_OUT_REG``` is 1.
    //! @virtualbus us_side_if @dir in upstream side interface
    output wire logic o_ready, //! Ready signal to upstream side which indicates that the upstream side is allowed to update input data (to this module) right AFTER the next rising edge of the clock. When ```EN_OUT_REG``` is 1, this is set to constant 1.
    input wire logic i_input_valid, //! valid signal from upstream side, used only when ```EN_OUT_REG``` is 1.
    input wire logic signed [N-1:0] i_val, //! input value
    //! @end
    //! @virtualbus ds_side_if @dir out downstream side interface
    //! Ready signal from downstream side which indicates that this module is allowed to update output data (to downstream side) right AFTER the next rising edge of the clock. This is used only when ```EN_OUT_REG``` is 1.
    input wire logic i_ds_ready,
    output wire logic o_output_valid, //! Output valid signal. When ```EN_OUT_REG``` is 1, this is set to constant 1.
    output wire logic signed [N-N_F-1:0] o_val //! output value (integer part only)
    //! @end
);
// ---------- parameters ----------
localparam int unsigned N_I = N - N_F; //! bit width of integer part
localparam bit [N_F-1:0] FRAC_PART_ZP5 = {1'b1, {(N_F-1){1'b0}}}; //! 0.5 in fractional part
// --------------------

// ---------- parameter validation ----------
generate
    if (N_F < 1) begin: gen_validate_n_f_lower_bound
        nonexistent_module_to_throw_a_custom_error_message_for too_small_n_f();
    end

    if (N_F >= N) begin: gen_validate_n_f_upper_bound
        nonexistent_module_to_throw_a_custom_error_message_for too_large_n_f();
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
wire signed [N-N_F-1:0] g_post_round_val; //! post-rounding value
assign g_post_round_val = g_frac_part_is_0 ? i_val[N-1:N_F]
    // Note that the sign doesn't matter (except for clipping).
    // For example, val = -2.3, the integer and fractional parts obtained from bit slice are -3 and 0.7 respectively.
    // The fractional part always fall into the range [0, 1).
    : g_frac_part_is_0p5 ? signed'({w_int_part + (!g_int_part_is_max && w_int_part[0])})
    // Note that at this point the fractional part is neither 0 nor 0.5.
    : signed'({w_int_part + (!g_int_part_is_max && w_frac_part[N_F-1])});

generate
    if (EN_OUT_REG) begin: gen_out_reg_sigs
        var logic r_vld_dly_line; //! delay line for the output valid signal
        wire g_can_adv_pip_ln; //! signal indicating that the pipeline can advance
        assign g_can_adv_pip_ln = !r_vld_dly_line || i_ds_ready;
        wire g_adv_pip_ln; //! signal indicating that the pipeline should advance
        assign g_adv_pip_ln = i_input_valid & g_can_adv_pip_ln;

        var logic signed [N-N_F-1:0] r_post_round_val; //! register for post-rounding value
    end
endgenerate
// --------------------

// ---------- instances ----------
// --------------------

// ---------- Drive output signals. ----------
generate
    if (EN_OUT_REG) begin: gen_drv_out_sigs_with_out_reg
        assign o_ready = gen_out_reg_sigs.g_can_adv_pip_ln;
        assign o_output_valid = i_input_valid & gen_out_reg_sigs.r_vld_dly_line;
        assign o_val = gen_out_reg_sigs.r_post_round_val;
    end else begin: gen_drv_out_sigs_without_out_reg
        assign o_ready = 1'b1;
        assign o_output_valid = 1'b1;
        assign o_val = g_post_round_val;
    end
endgenerate
// --------------------

// ---------- blocks ----------
generate
    if (EN_OUT_REG) begin: gen_out_reg_blks
        //! Updates valid delay line.
        always_ff @(posedge i_clk) begin: blk_update_vld_dly_line
            if (i_sync_rst) begin
                gen_out_reg_sigs.r_vld_dly_line <= 1'b0;
            end else if (gen_out_reg_sigs.g_adv_pip_ln) begin
                gen_out_reg_sigs.r_vld_dly_line <= 1'b1;
            end
        end

        //! Updates output register.
        always_ff @(posedge i_clk) begin: blk_update_out_reg
            if (i_sync_rst) begin
                gen_out_reg_sigs.r_post_round_val <= '0;
            end else if (gen_out_reg_sigs.g_adv_pip_ln) begin
                gen_out_reg_sigs.r_post_round_val <= g_post_round_val;
            end
        end
    end
endgenerate
// --------------------
endmodule

`default_nettype wire
