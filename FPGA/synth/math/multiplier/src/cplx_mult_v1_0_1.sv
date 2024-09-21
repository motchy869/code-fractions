// Verible directive
// verilog_lint: waive-start parameter-name-style
// verilog_lint: waive-start line-length

`include "round_hf2evn_v1_0_0.svh"

`default_nettype none

//! A fully-parametrized fixed-point number complex multiplier with optional rounding half to even.
//! This module uses 3 (not 4) real multipliers.
//! This technique is described in the chapter 2 of "Complex Multiplier v6.0 LogiCORE IP Product Guide"
//!
//! Total cycle latency is ```2 + MULT_PIPELINE_DEPTH + ENABLE_ROUNDING_HALF_TO_EVEN```.
//!
//! When ```ENABLE_ROUNDING_HALF_TO_EVEN``` is set to ```1'b0```, the output is simply the bit slice of the product of the inputs.
//! When ```ENABLE_ROUNDING_HALF_TO_EVEN``` is set to ```1'b1```, ```BIT_SLICE_OFFSET_OUT``` must be greater than 0.

//! It depends on the synthesis tool whether DSP blocks are used or not.
//! ## changelog
//! ### [1.0.1] - 2024-08-01
//! #### Fixed:
//! - missing bit width expansion at the RHS of non-blocking assignments to ```alpha_{0,1,2}```.
//! ### [1.0.0] - 2024-08-01
//! - initial release
module cplx_mult_v1_0_1 #(
    parameter int unsigned BIT_WIDTH_IN_A = 16, //! bit width of the input a
    parameter int unsigned BIT_WIDTH_IN_B = 16, //! bit width of the input b
    parameter int unsigned BIT_WIDTH_OUT = 16, //! bit width of the output
    parameter int unsigned BIT_SLICE_OFFSET_OUT = 0, //! Bit slice offset of the output. When ```BIT_SLICE_OFFSET_OUT``` > 0, (ab)[```BIT_SLICE_OFFSET_OUT```-1:0] is treated as fractional part. The fractional part is simply truncated or rounded (see: ```ENABLE_ROUNDING_HALF_TO_EVEN```).
    parameter int unsigned MULT_PIPELINE_DEPTH = 2, //! pipeline depth of the multiplier, must be greater than 0
    parameter bit ENABLE_ROUNDING_HALF_TO_EVEN = 1'b1 //! enable rounding half to even
)(
    input wire logic i_clk, //! input clock
    input wire logic i_sync_rst, //! input reset synchronous to the input clock
    //! @virtualbus us_side_if @dir in upstream side interface
    output wire logic o_ready, //! ready signal to upstream side which indicates that the upstream side is allowed to update input data (to this module) right AFTER the next rising edge of the clock
    input wire logic i_input_valid, //! valid signal from upstream side
    input wire logic [1:0][BIT_WIDTH_IN_A-1:0] i_a, //! Input a. The elements [0] and [1] are the real and imaginary parts, respectively.
    input wire logic [1:0][BIT_WIDTH_IN_B-1:0] i_b, //! Input b.
    //! @end
    //! @virtualbus ds_side_if @dir out downstream side interface
    //! ready signal from downstream side which indicates that this module is allowed to update input data (to downstream side) right AFTER the next rising edge of the clock
    input wire logic i_ds_ready,
    output wire logic o_output_valid, //! output valid signal
    output wire logic [1:0][BIT_WIDTH_OUT-1:0] o_c //! output c = ab
    //! @end
);
// ---------- parameters ----------
localparam int unsigned CYCLE_LATENCY = 2 + MULT_PIPELINE_DEPTH + ENABLE_ROUNDING_HALF_TO_EVEN; //! cycle latency
// Note that |Re(c)| <= |Re(a)Re(b)| + |Im(a)*Im(b)| <= 2^(BIT_WIDTH_IN_A + BIT_WIDTH_IN_B - 1).
localparam int unsigned BIT_WIDTH_INTERM_PROD = BIT_WIDTH_IN_A + BIT_WIDTH_IN_B; //! bit width of the intermediate product
// --------------------

// ---------- parameter validation ----------
generate
    if (BIT_SLICE_OFFSET_OUT + BIT_WIDTH_OUT - 1 > BIT_WIDTH_INTERM_PROD - 1) begin: gen_bit_slice_range_validation
        nonexistent_module_to_throw_a_custom_error_message_for invalid_parameters();
    end

    if (MULT_PIPELINE_DEPTH < 1) begin: gen_mult_pipeline_depth_validation
        nonexistent_module_to_throw_a_custom_error_message_for invalid_parameters();
    end

    if (ENABLE_ROUNDING_HALF_TO_EVEN && BIT_SLICE_OFFSET_OUT == 0) begin: gen_rounding_param_validation
        nonexistent_module_to_throw_a_custom_error_message_for invalid_parameters();
    end
endgenerate
// --------------------

// ---------- functions ----------
// --------------------

// ---------- signals and storage ----------
var logic [CYCLE_LATENCY-1:0] r_vld_dly_line; //! delay line for the output valid signal
wire g_can_adv_pip_ln; //! signal indicating that the pipeline can advance
assign g_can_adv_pip_ln = !r_vld_dly_line[$left(r_vld_dly_line)] || i_ds_ready;
wire g_adv_pip_ln; //! signal indicating that the pipeline should advance
assign g_adv_pip_ln = i_input_valid & g_can_adv_pip_ln;

var logic signed [BIT_WIDTH_IN_A-1:0] r_prev_a_re; //! previous Re(a)
var logic signed [BIT_WIDTH_IN_B-1:0] r_prev_b_re; //! previous Re(b)
var logic signed [BIT_WIDTH_IN_B-1:0] r_prev_b_im; //! previous Im(b)

var logic signed [BIT_WIDTH_IN_B:0] r_alpha_0; //! Re(b) + Im(b)
var logic signed [BIT_WIDTH_IN_A:0] r_alpha_1; //! Re(a) + Im(a)
var logic signed [BIT_WIDTH_IN_A:0] r_alpha_2; //! Im(a) - Re(a)
var logic signed [MULT_PIPELINE_DEPTH-1:0][BIT_WIDTH_INTERM_PROD-1:0] r_beta_0; //! Re(a) * (Re(b) + Im(b))
var logic signed [MULT_PIPELINE_DEPTH-1:0][BIT_WIDTH_INTERM_PROD-1:0] r_beta_1; //! (Re(a) + Im(a)) * Im(b)
var logic signed [MULT_PIPELINE_DEPTH-1:0][BIT_WIDTH_INTERM_PROD-1:0] r_beta_2; //! (Im(a) - Re(a)) * Re(b)
var logic signed [BIT_WIDTH_INTERM_PROD-1:0] r_gamma_0; //! Re(c) before slicing & rounding
var logic signed [BIT_WIDTH_INTERM_PROD-1:0] r_gamma_1; //! Im(c) before slicing & rounding
generate
    if (ENABLE_ROUNDING_HALF_TO_EVEN) begin: gen_rnd_sigs
        wire signed [BIT_WIDTH_INTERM_PROD-BIT_SLICE_OFFSET_OUT-1:0] g_round_res_re; //! result of rounding Re(c)
        wire signed [BIT_WIDTH_INTERM_PROD-BIT_SLICE_OFFSET_OUT-1:0] g_round_res_im; //! result of rounding Im(c)
        var logic signed [BIT_WIDTH_OUT-1:0] r_theta_0; //! Re(c) after slicing & rounding
        var logic signed [BIT_WIDTH_OUT-1:0] r_theta_1; //! Im(c) after slicing & rounding
    end
endgenerate
// --------------------

// ---------- instances ----------
generate
    if (ENABLE_ROUNDING_HALF_TO_EVEN) begin: gen_round
        round_hf2evn_v1_0_0 #(
            .N(BIT_WIDTH_INTERM_PROD),
            .N_F(BIT_SLICE_OFFSET_OUT)
        ) round_hf2evn_re (
            .i_val(r_gamma_0),
            .o_val(gen_rnd_sigs.g_round_res_re)
        );

        round_hf2evn_v1_0_0 #(
            .N(BIT_WIDTH_INTERM_PROD),
            .N_F(BIT_SLICE_OFFSET_OUT)
        ) round_hf2evn_im (
            .i_val(r_gamma_1),
            .o_val(gen_rnd_sigs.g_round_res_im)
        );
    end
endgenerate
// --------------------

// ---------- Drive output signals. ----------
assign o_ready = g_can_adv_pip_ln;
assign o_output_valid = i_input_valid & r_vld_dly_line[$left(r_vld_dly_line)];
generate
    if (ENABLE_ROUNDING_HALF_TO_EVEN) begin: gen_out_rnd
        assign o_c[0] = gen_rnd_sigs.r_theta_0;
        assign o_c[1] = gen_rnd_sigs.r_theta_1;
    end else begin: gen_out_trunc
        assign o_c[0] = signed'(r_gamma_0[BIT_SLICE_OFFSET_OUT +: BIT_WIDTH_OUT]);
        assign o_c[1] = signed'(r_gamma_1[BIT_SLICE_OFFSET_OUT +: BIT_WIDTH_OUT]);
    end
endgenerate
// --------------------

// ---------- blocks ----------
//! Updates valid delay line.
always_ff @(posedge i_clk) begin: blk_update_vld_dly_line
    if (i_sync_rst) begin
        r_vld_dly_line <= '0;
    end else if (i_input_valid) begin
        r_vld_dly_line <= {r_vld_dly_line[$left(r_vld_dly_line)-1:0], 1'b1};
    end
end

//! Updates previous inputs.
always_ff @(posedge i_clk) begin: blk_update_prev_inputs
    if (i_sync_rst) begin
        r_prev_a_re <= '0;
        r_prev_b_re <= '0;
        r_prev_b_im <= '0;
    end if (g_adv_pip_ln) begin
        r_prev_a_re <= signed'(i_a[0]);
        r_prev_b_re <= signed'(i_b[0]);
        r_prev_b_im <= signed'(i_b[1]);
    end
end

//! Updates alphas.
always_ff @(posedge i_clk) begin: blk_update_alphas
    if (i_sync_rst) begin
        r_alpha_0 <= '0;
        r_alpha_1 <= '0;
        r_alpha_2 <= '0;
    end else if (g_adv_pip_ln) begin
        r_alpha_0 <= (BIT_WIDTH_IN_B+1)'(signed'(i_b[0])) + (BIT_WIDTH_IN_B+1)'(signed'(i_b[1]));
        r_alpha_1 <= (BIT_WIDTH_IN_A+1)'(signed'(i_a[0])) + (BIT_WIDTH_IN_A+1)'(signed'(i_a[1]));
        r_alpha_2 <= (BIT_WIDTH_IN_A+1)'(signed'(i_a[1])) - (BIT_WIDTH_IN_A+1)'(signed'(i_a[0]));
    end
end

//! Updates betas.
always_ff @(posedge i_clk) begin: blk_update_betas
    if (i_sync_rst) begin
        r_beta_0 <= '0;
        r_beta_1 <= '0;
        r_beta_2 <= '0;
    end if (g_adv_pip_ln) begin
        // advance pipeline
        for (int unsigned d=MULT_PIPELINE_DEPTH-1; d>0; --d) begin
            r_beta_0[d] <= r_beta_0[d-1];
            r_beta_1[d] <= r_beta_1[d-1];
            r_beta_2[d] <= r_beta_2[d-1];
        end

        // put new values
        r_beta_0[0] <= BIT_WIDTH_INTERM_PROD'(signed'(r_prev_a_re)) * BIT_WIDTH_INTERM_PROD'(r_alpha_0);
        r_beta_1[0] <= BIT_WIDTH_INTERM_PROD'(r_alpha_1) * BIT_WIDTH_INTERM_PROD'(signed'(r_prev_b_im));
        r_beta_2[0] <= BIT_WIDTH_INTERM_PROD'(r_alpha_2) * BIT_WIDTH_INTERM_PROD'(signed'(r_prev_b_re));
    end
end

//! Updates gammas.
always_ff @(posedge i_clk) begin: blk_update_gammas
    if (i_sync_rst) begin
        r_gamma_0 <= '0;
        r_gamma_1 <= '0;
    end if (g_adv_pip_ln) begin
        r_gamma_0 <= r_beta_0[MULT_PIPELINE_DEPTH-1] - r_beta_1[MULT_PIPELINE_DEPTH-1];
        r_gamma_1 <= r_beta_0[MULT_PIPELINE_DEPTH-1] + r_beta_2[MULT_PIPELINE_DEPTH-1];
    end
end

//! Updates thetas.
generate
    if (ENABLE_ROUNDING_HALF_TO_EVEN) begin: gen_update_rnd_regs
        always_ff @(posedge i_clk) begin: blk_update_thetas
            if (i_sync_rst) begin
                gen_rnd_sigs.r_theta_0 <= '0;
                gen_rnd_sigs.r_theta_1 <= '0;
            end if (g_adv_pip_ln) begin
                gen_rnd_sigs.r_theta_0 <= signed'(gen_rnd_sigs.g_round_res_re[BIT_WIDTH_OUT-1:0]);
                gen_rnd_sigs.r_theta_1 <= signed'(gen_rnd_sigs.g_round_res_im[BIT_WIDTH_OUT-1:0]);
            end
        end
    end
endgenerate
// --------------------
endmodule

`default_nettype wire
