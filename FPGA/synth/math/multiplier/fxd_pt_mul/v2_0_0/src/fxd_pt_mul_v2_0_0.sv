// Verible directive
// verilog_lint: waive-start parameter-name-style
// verilog_lint: waive-start line-length

`include "round_hf2evn_v1_0_0.svh"

`default_nettype none

//! A fully-parametrized fixed-point number multiplier with optional rounding half to even.
//! Total cycle latency is ```MULT_INPUT_STG_PIPELINE_DEPTH + MULT_OUTPUT_STG_PIPELINE_DEPTH + ENABLE_ROUNDING_HALF_TO_EVEN```.
//!
//! When ```ENABLE_ROUNDING_HALF_TO_EVEN``` is set to ```1'b0```, the output is simply the bit slice of the product of the inputs.
//! When ```ENABLE_ROUNDING_HALF_TO_EVEN``` is set to ```1'b1```, ```BIT_SLICE_OFFSET_OUT``` must be greater than 0.
//!
//! It depends on the synthesis tool whether DSP blocks are used or not.
//! ## changelog
//! ### [2.0.0] - 2024-09-24
//! - change:
//!   1. Renamed module to ```fxd_pt_mul_v2_0_0```.
//!   2. Default value of output stage pipeline depth of the multiplier is now 1.
//! - add: input stage pipeline
//! ### [1.0.1] - 2024-09-20
//! - fix: slipping valid signal delay line
//! ### [1.0.0] - 2024-08-01
//! - initial release
module fxd_pt_mul_v2_0_0 #(
    parameter int unsigned BIT_WIDTH_IN_A = 16, //! bit width of the input a
    parameter int unsigned BIT_WIDTH_IN_B = 16, //! bit width of the input b
    parameter int unsigned BIT_WIDTH_OUT = 16, //! bit width of the output
    parameter int unsigned BIT_SLICE_OFFSET_OUT = 0, //! Bit slice offset of the output. When ```BIT_SLICE_OFFSET_OUT``` > 0, (ab)[```BIT_SLICE_OFFSET_OUT```-1:0] is treated as fractional part. The fractional part is simply truncated or rounded (see: ```ENABLE_ROUNDING_HALF_TO_EVEN```).
    parameter int unsigned MULT_INPUT_STG_PIPELINE_DEPTH = 1, //! input stage pipeline depth of the multiplier, must be greater than 0
    parameter int unsigned MULT_OUTPUT_STG_PIPELINE_DEPTH = 1, //! output stage pipeline depth of the multiplier, must be greater than 0
    parameter bit ENABLE_ROUNDING_HALF_TO_EVEN = 1'b1 //! enable rounding half to even
)(
    input wire logic i_clk, //! input clock
    input wire logic i_sync_rst, //! input reset signal synchronous to the input clock
    //! @virtualbus us_side_if @dir in upstream side interface
    output wire logic o_ready, //! ready signal to upstream side which indicates that the upstream side is allowed to update input data (to this module) right AFTER the next rising edge of the clock
    input wire logic i_input_valid, //! valid signal from upstream side
    input wire logic signed [BIT_WIDTH_IN_A-1:0] i_a, //! Input a.
    input wire logic signed [BIT_WIDTH_IN_B-1:0] i_b, //! Input b.
    //! @end
    //! @virtualbus ds_side_if @dir out downstream side interface
    //! ready signal from downstream side which indicates that this module is allowed to update output data (to downstream side) right AFTER the next rising edge of the clock
    input wire logic i_ds_ready,
    output wire logic o_output_valid, //! output valid signal
    output wire logic signed [BIT_WIDTH_OUT-1:0] o_c //! output c = ab
    //! @end
);
// ---------- parameters ----------
localparam int unsigned CYCLE_LATENCY = MULT_INPUT_STG_PIPELINE_DEPTH + MULT_OUTPUT_STG_PIPELINE_DEPTH + ENABLE_ROUNDING_HALF_TO_EVEN; //! cycle latency
localparam int unsigned BIT_WIDTH_INTERM_PROD = BIT_WIDTH_IN_A + BIT_WIDTH_IN_B; //! bit width of the intermediate product
// --------------------

// ---------- parameter validation ----------
generate
    if (BIT_SLICE_OFFSET_OUT + BIT_WIDTH_OUT - 1 > BIT_WIDTH_INTERM_PROD - 1) begin: gen_bit_slice_range_validation
        nonexistent_module_to_throw_a_custom_error_message_for invalid_bit_slice_range();
    end

    if (MULT_INPUT_STG_PIPELINE_DEPTH < 1) begin: gen_mult_input_stg_pipeline_depth_validation
        nonexistent_module_to_throw_a_custom_error_message_for invalid_mult_input_stg_pipeline_depth();
    end

    if (MULT_OUTPUT_STG_PIPELINE_DEPTH < 1) begin: gen_mult_output_stg_pipeline_depth_validation
        nonexistent_module_to_throw_a_custom_error_message_for invalid_mult_output_stg_pipeline_depth();
    end

    if (ENABLE_ROUNDING_HALF_TO_EVEN && BIT_SLICE_OFFSET_OUT == 0) begin: gen_rounding_param_validation
        nonexistent_module_to_throw_a_custom_error_message_for invalid_rounding_params();
    end
endgenerate
// --------------------

// ---------- functions ----------
// --------------------

// ---------- signals and storage ----------
var logic [CYCLE_LATENCY-1:0] r_vld_dly_line; //! delay line for the output valid signal
wire g_can_adv_pip_ln; //! signal indicating that the pipeline can advance
assign g_can_adv_pip_ln = !r_vld_dly_line[CYCLE_LATENCY-1] || i_ds_ready;
wire g_adv_pip_ln; //! signal indicating that the pipeline should advance
assign g_adv_pip_ln = i_input_valid & g_can_adv_pip_ln;

var logic [MULT_INPUT_STG_PIPELINE_DEPTH-1:0][BIT_WIDTH_IN_A-1:0] r_a; //! multiplier input stage pipeline register for a
var logic [MULT_INPUT_STG_PIPELINE_DEPTH-1:0][BIT_WIDTH_IN_B-1:0] r_b; //! multiplier input stage pipeline register for b
var logic [MULT_OUTPUT_STG_PIPELINE_DEPTH-1:0][BIT_WIDTH_INTERM_PROD-1:0] r_c_pre_slc_rnd; //! multiplier output stage pipeline register for c before slicing/rounding
generate
    if (ENABLE_ROUNDING_HALF_TO_EVEN) begin: gen_rnd_sigs
        wire signed [BIT_WIDTH_INTERM_PROD-BIT_SLICE_OFFSET_OUT-1:0] g_round_res; //! result of rounding
        var logic signed [BIT_WIDTH_OUT-1:0] r_c_post_rnd_slc; //! c after rounding&slicing
    end
endgenerate
// --------------------

// ---------- instances ----------
generate
    if (ENABLE_ROUNDING_HALF_TO_EVEN) begin: gen_round
        round_hf2evn_v1_0_0 #(
            .N(BIT_WIDTH_INTERM_PROD),
            .N_F(BIT_SLICE_OFFSET_OUT)
        ) round_hf2evn (
            .i_val(r_c_pre_slc_rnd[MULT_OUTPUT_STG_PIPELINE_DEPTH-1]),
            .o_val(gen_rnd_sigs.g_round_res)
        );
    end
endgenerate
// --------------------

// ---------- Drive output signals. ----------
assign o_ready = g_can_adv_pip_ln;
assign o_output_valid = i_input_valid & r_vld_dly_line[CYCLE_LATENCY-1];
generate
    if (ENABLE_ROUNDING_HALF_TO_EVEN) begin: gen_out_rnd
        assign o_c = gen_rnd_sigs.r_c_post_rnd_slc;
    end else begin: gen_out_trunc
        assign o_c = signed'(r_c_pre_slc_rnd[MULT_OUTPUT_STG_PIPELINE_DEPTH-1][BIT_SLICE_OFFSET_OUT +: BIT_WIDTH_OUT]);
    end
endgenerate
// --------------------

// ---------- blocks ----------
//! Updates valid delay line.
always_ff @(posedge i_clk) begin: blk_update_vld_dly_line
    if (i_sync_rst) begin
        r_vld_dly_line <= '0;
    end else if (g_adv_pip_ln) begin
        r_vld_dly_line <= {r_vld_dly_line[CYCLE_LATENCY-2:0], 1'b1};
    end
end

//! Updates multiplier input stage pipeline registers.
always_ff @(posedge i_clk) begin: blk_update_mult_input_stg_ppln_regs
    if (i_sync_rst) begin
        r_a <= '0;
        r_b <= '0;
    end else if (g_adv_pip_ln) begin
        // Advances pipeline.
        for (int unsigned d=MULT_INPUT_STG_PIPELINE_DEPTH-1; d>0; --d) begin
            r_a[d] <= r_a[d-1];
            r_b[d] <= r_b[d-1];
        end

        r_a[0] <= i_a;
        r_b[0] <= i_b;
    end
end

//! Updates multiplier output stage pipeline registers.
always_ff @(posedge i_clk) begin: blk_update_mult_output_stg_ppln_regs
    if (i_sync_rst) begin
        r_c_pre_slc_rnd <= '0;
    end else if (g_adv_pip_ln) begin
        // Advances pipeline.
        for (int unsigned d=MULT_OUTPUT_STG_PIPELINE_DEPTH-1; d>0; --d) begin
            r_c_pre_slc_rnd[d] <= r_c_pre_slc_rnd[d-1];
        end

        r_c_pre_slc_rnd[0] <= BIT_WIDTH_INTERM_PROD'(signed'(r_a[MULT_INPUT_STG_PIPELINE_DEPTH-1])) * BIT_WIDTH_INTERM_PROD'(signed'(r_b[MULT_INPUT_STG_PIPELINE_DEPTH-1]));
    end
end

//! Updates post-rounding registers.
generate
    if (ENABLE_ROUNDING_HALF_TO_EVEN) begin: gen_update_post_rnd_regs
        always_ff @(posedge i_clk) begin: blk_update_post_rnd_regs
            if (i_sync_rst) begin
                gen_rnd_sigs.r_c_post_rnd_slc <= '0;
            end if (g_adv_pip_ln) begin
                gen_rnd_sigs.r_c_post_rnd_slc <= gen_rnd_sigs.g_round_res[BIT_WIDTH_OUT-1:0];
            end
        end
    end
endgenerate
// --------------------
endmodule

`default_nettype wire
