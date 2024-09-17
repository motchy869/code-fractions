// Verible directive
// verilog_lint: waive-start parameter-name-style
// verilog_lint: waive-start line-length

`include "round_hf2evn_v1_0_0.svh"

`default_nettype none

//! A fixed-point number multiply-and-sum with optional rounding half to even.
//! For given **signed** inputs a_0, b_0, a_1, b_1, this module calculates an output c = a_0\*b_0 +/- a_1\*b_1. +/- is determined by the input control signal.
//!
//! This module is intended to be **inferred** as a Variable Precision **DSP Block** in following Altera devices:
//! 1. Cyclone V, 10 GX
//! 2. Arria V, 10
//! 3. Stratix 10
//! 4. Agilex 5, 7
//!
//! Total cycle latency is ```DSP_BLK_INPUT_STG_REG_CHAIN_LEN + DSP_BLK_OUTPUT_STG_REG_CHAIN_LEN + EN_RND_HF2EVN```.
//!
//! - When ```EN_RND_HF2EVN``` is set to ```1'b0```, the output is simply the bit slice of the product of the inputs.
//! - When ```EN_RND_HF2EVN``` is set to ```1'b1```, ```BIT_SLC_OFFSET_OUT``` must be greater than 0.
//! ## References
//! 1. [Cyclone V Device Handbook Volume 1: Device Interfaces and Integration](https://www.google.com/url?sa=t&source=web&rct=j&opi=89978449&url=https://cdrdv2-public.intel.com/666995/cv_5v2-683375-666995.pdf&ved=2ahUKEwiuqoyYo8qIAxU5k1YBHRX0HysQFnoECBMQAQ&usg=AOvVaw2qYeHcb4LpcBs5EUXl-iRo)
//! ## changelog
//! ### [Unreleased]
//! - Seemingly OK, but NOT tested AT ALL.
module fxd_pt_mul_sum_altera_vp_dsp_18x19_v0_1_0_wip #(
    parameter int unsigned BW_IN_A_0 = 16, //! bit width of the input a_0, must be <= 18
    parameter int unsigned BW_IN_B_0 = 16, //! bit width of the input b_0, must be <= **19**
    parameter int unsigned BW_IN_A_1 = 16, //! bit width of the input a_1, must be <= 18
    parameter int unsigned BW_IN_B_1 = 16, //! bit width of the input b_1, must be <= **19**
    parameter int unsigned BW_OUT = 16, //! bit width of the output, must be <= 38 - ```BIT_SLC_OFFSET_OUT``` (38 = 18 + 19 + 1)
    parameter int unsigned BIT_SLC_OFFSET_OUT = 0, //! Bit slice offset of the output. When ```BIT_SLICE_OFFSET_OUT``` > 0, (ab)[```BIT_SLICE_OFFSET_OUT```-1:0] is treated as decimal part. The decimal part is simply truncated or rounded (see: ```EN_RND_HF2EVN```).
    parameter int unsigned DSP_BLK_INPUT_STG_REG_CHAIN_LEN = 1, //! The length of the input stage (including pipeline) register chain for the DSP Block. When this is set to 0, the input registers are not used.
    parameter int unsigned DSP_BLK_OUTPUT_STG_REG_CHAIN_LEN = 1, //! The length of the output stage register chain for the DSP Block. When this is set to 0, the output registers are not used.
    parameter bit EN_RND_HF2EVN = 1'b1 //! enable rounding half to even
)(
    input wire logic i_clk, //! input clock
    input wire logic i_sync_rst, //! input reset synchronous to the input clock
    //! @virtualbus us_side_if @dir in configuration interface
    output wire logic o_ready, //! ready signal to upstream side which indicates that the upstream side is allowed to update input data (to this module) right AFTER the next rising edge of the clock
    input wire logic i_input_valid, //! Valid signal from upstream side. This is also used as freezing signal like clock-enable deassertion. When this is low, the module internal state is frozen.
    input wire logic signed [BW_IN_A-1:0] i_a_0, //! input a_0
    input wire logic signed [BW_IN_B-1:0] i_b_0, //! input b_0
    input wire logic signed [BW_IN_A-1:0] i_a_1, //! input a_1
    input wire logic signed [BW_IN_B-1:0] i_b_1, //! input b_1
    input wire logic i_sub, //! Add/subtract dynamic control signal. 0/1: add/subtract. If this signal is compile-time constant, the synthesis tool will optimize-out the unused logics.
    //! @end
    //! @virtualbus ds_side_if @dir out downstream side interface
    //! ready signal from downstream side which indicates that this module is allowed to update input data (to downstream side) right AFTER the next rising edge of the clock
    input wire logic i_ds_ready,
    output wire logic o_output_valid, //! output valid signal
    output wire logic signed [BW_OUT-1:0] o_c //! output c
    //! @end
);
// ---------- parameters ----------
localparam int unsigned BW_LHS_MULT = 18; //! bit width of the left-hand side input to the 18x19 multiplier
localparam int unsigned BW_RHS_MULT = 19; //! bit width of the right-hand side input to the 18x19 multiplier
localparam int unsigned CYCLE_LAT = DSP_BLK_INPUT_STG_REG_CHAIN_LEN + DSP_BLK_OUTPUT_STG_REG_CHAIN_LEN + EN_RND_HF2EVN; //! cycle latency
localparam int unsigned BW_INTERM_PROD = BW_LHS_MULT + BW_RHS_MULT; //! bit width of the intermediate product
localparam int unsigned BW_INTERM_SUM = BW_INTERM_PROD + 1; //! bit width of the intermediate sum
// --------------------

// ---------- parameter validation ----------
generate
    if (BW_IN_A_0 > BW_LHS_MULT) begin: gen_validate_bw_in_a_0
        nonexistent_module_to_throw_a_custom_error_message_for invalid_a_0_bit_width();
    end

    if (BW_IN_B_0 > BW_RHS_MULT) begin: gen_validate_bw_in_b_0
        nonexistent_module_to_throw_a_custom_error_message_for invalid_b_0_bit_width();
    end

    if (BW_IN_A_1 > BW_LHS_MULT) begin: gen_validate_bw_in_a_1
        nonexistent_module_to_throw_a_custom_error_message_for invalid_a_1_bit_width();
    end

    if (BW_IN_B_1 > BW_RHS_MULT) begin: gen_validate_bw_in_b_1
        nonexistent_module_to_throw_a_custom_error_message_for invalid_b_1_bit_width();
    end

    if (BIT_SLC_OFFSET_OUT + BW_OUT > BW_INTERM_SUM) begin: gen_validate_bit_slice_offset_and_output_bit_width
        nonexistent_module_to_throw_a_custom_error_message_for invalid_bit_slice_offset_and_output_bit_width();
    end

    if (EN_RND_HF2EVN && BIT_SLC_OFFSET_OUT == 0) begin: gen_validate_rounding_option
        nonexistent_module_to_throw_a_custom_error_message_for invalid_rounding_option();
    end
endgenerate
// --------------------

// ---------- functions ----------
// --------------------

// ---------- signals and storage ----------
var logic [CYCLE_LAT-1:0] r_vld_dly_line; //! delay line for the output valid signal
wire g_can_adv_pip_ln; //! signal indicating that the pipeline can advance
assign g_can_adv_pip_ln = !r_vld_dly_line[CYCLE_LAT-1] || i_ds_ready;
wire g_adv_pip_ln; //! signal indicating that the pipeline should advance
assign g_adv_pip_ln = i_input_valid & g_can_adv_pip_ln;
wire signed [BW_LHS_MULT-1:0] w_a_0_to_dsp_blk; //! input a_0 to the DSP block
wire signed [BW_RHS_MULT-1:0] w_b_0_to_dsp_blk; //! input b_0 to the DSP block
wire signed [BW_LHS_MULT-1:0] w_a_1_to_dsp_blk; //! input a_1 to the DSP block
wire signed [BW_RHS_MULT-1:0] w_b_1_to_dsp_blk; //! input b_1 to the DSP block
wire signed [BW_INTERM_PROD-1:0] w_a_0_by_b_0; //! a_0 * b_0
assign w_a_0_by_b_0 = BW_INTERM_PROD'(w_a_0_to_dsp_blk)*BW_INTERM_PROD'(w_b_0_to_dsp_blk);
wire signed [BW_INTERM_PROD-1:0] w_a_1_by_b_1; //! a_1 * b_1
assign w_a_1_by_b_1 = BW_INTERM_PROD'(w_a_1_to_dsp_blk)*BW_INTERM_PROD'(w_b_1_to_dsp_blk);
wire signed [BW_INTERM_SUM-1:0] g_c_from_dsp_blk; //! output c from the DSP block
assign g_c_from_dsp_blk = i_sub ? BW_INTERM_SUM'(w_a_0_by_b_0) - BW_INTERM_SUM'(w_a_1_by_b_1) : BW_INTERM_SUM'(w_a_0_by_b_0) + BW_INTERM_SUM'(w_a_1_by_b_1);
wire signed [BW_INTERM_SUM-1:0] w_c_pre_slc_rnd; //! c before slicing/rounding

generate
    if (DSP_BLK_INPUT_STG_REG_CHAIN_LEN > 0) begin: gen_input_stg_reg_chain
        var logic [DSP_BLK_INPUT_STG_REG_CHAIN_LEN-1:0][BW_LHS_MULT-1:0] r_a_0; //! input stage register chain for a_0
        var logic [DSP_BLK_INPUT_STG_REG_CHAIN_LEN-1:0][BW_RHS_MULT-1:0] r_b_0; //! input stage register chain for b_0
        var logic [DSP_BLK_INPUT_STG_REG_CHAIN_LEN-1:0][BW_LHS_MULT-1:0] r_a_1; //! input stage register chain for a_1
        var logic [DSP_BLK_INPUT_STG_REG_CHAIN_LEN-1:0][BW_RHS_MULT-1:0] r_b_1; //! input stage register chain for b_1
        assign w_a_0_to_dsp_blk = signed'(r_a_0[DSP_BLK_INPUT_STG_REG_CHAIN_LEN-1]);
        assign w_b_0_to_dsp_blk = signed'(r_b_0[DSP_BLK_INPUT_STG_REG_CHAIN_LEN-1]);
        assign w_a_1_to_dsp_blk = signed'(r_a_1[DSP_BLK_INPUT_STG_REG_CHAIN_LEN-1]);
        assign w_b_1_to_dsp_blk = signed'(r_b_1[DSP_BLK_INPUT_STG_REG_CHAIN_LEN-1]);
    end else begin: gen_no_input_stg_reg_chain
        assign w_a_0_to_dsp_blk = BW_LHS_MULT'(i_a_0);
        assign w_b_0_to_dsp_blk = BW_RHS_MULT'(i_b_0);
        assign w_a_1_to_dsp_blk = BW_LHS_MULT'(i_a_1);
        assign w_b_1_to_dsp_blk = BW_RHS_MULT'(i_b_1);
    end

    if (DSP_BLK_OUTPUT_STG_REG_CHAIN_LEN > 0) begin: gen_output_stg_reg_chain
        var logic [DSP_BLK_OUTPUT_STG_REG_CHAIN_LEN-1:0][BW_INTERM_SUM-1:0] r_c_pre_slc_rnd; //! output stage register chain for c before slicing/rounding
        assign w_c_pre_slc_rnd = signed'(r_c_pre_slc_rnd[DSP_BLK_OUTPUT_STG_REG_CHAIN_LEN-1]);
    end else begin: gen_no_output_stg_reg_chain
        assign w_c_pre_slc_rnd = g_c_from_dsp_blk;
    end

    if (EN_RND_HF2EVN) begin: gen_rnd_sigs
        wire signed [BW_INTERM_SUM - BIT_SLC_OFFSET_OUT - 1:0] g_rnd_res; //! result of rounding
        var logic signed [BW_OUT-1:0] r_c_post_slc_rnd; //! c after slicing/rounding
    end
endgenerate
// --------------------

// ---------- instances ----------
generate
    if (EN_RND_HF2EVN) begin: gen_rnd
        round_hf2evn_v1_0_0 #(
            .N(BW_INTERM_SUM),
            .N_F(BIT_SLC_OFFSET_OUT)
        ) round_hf2evn (
            .i_val(w_c_pre_slc_rnd),
            .o_val(gen_rnd_sigs.g_rnd_res)
        );
    end
endgenerate
// --------------------

// ---------- Drive output signals. ----------
assign o_ready = g_can_adv_pip_ln;
assign o_output_valid = i_input_valid & r_vld_dly_line[CYCLE_LAT-1];
generate
    if (EN_RND_HF2EVN) begin: gen_out_rnd
        assign o_c = gen_rnd_sigs.g_rnd_res;
    end else begin: gen_out_trunc
        assign o_c = signed'(w_c_pre_slc_rnd[BIT_SLC_OFFSET_OUT +: BW_OUT]);
    end
endgenerate
// --------------------

// ---------- blocks ----------
//! Updates valid delay line.
always_ff @(posedge i_clk) begin: blk_update_vld_dly_line
    if (i_sync_rst) begin
        r_vld_dly_line <= '0;
    end else if (i_input_valid) begin
        r_vld_dly_line <= {r_vld_dly_line[CYCLE_LAT-1:0], 1'b1};
    end
end

generate
    //! Updates input stage register chain for the DSP block.
    if (DSP_BLK_INPUT_STG_REG_CHAIN_LEN > 0) begin: gen_update_dsp_blk_input_stg_reg_chain
        always_ff @(posedge i_clk) begin: blk_update_dsp_blk_input_stg_reg_chain
            if (i_sync_rst) begin
                r_a_0 <= '0;
                r_b_0 <= '0;
                r_a_1 <= '0;
                r_b_1 <= '0;
            end else if (g_adv_pip_ln) begin
                // advance pipeline
                for (int unsigned d=DSP_BLK_INPUT_STG_REG_CHAIN_LEN-1; d>0; --d) begin
                    r_a_0[d] <= r_a_0[d-1];
                    r_b_0[d] <= r_b_0[d-1];
                    r_a_1[d] <= r_a_1[d-1];
                    r_b_1[d] <= r_b_1[d-1];
                end

                r_a_0[0] <= i_a_0;
                r_b_0[0] <= i_b_0;
                r_a_1[0] <= i_a_1;
                r_b_1[0] <= i_b_1;
            end else begin
            end
        end
    end

    //! Updates output stage register chain for the DSP block.
    if (DSP_BLK_OUTPUT_STG_REG_CHAIN_LEN > 0) begin: gen_update_dsp_blk_output_stg_reg_chain
        always_ff @(posedge i_clk) begin: blk_update_dsp_blk_output_stg_reg_chain
            if (i_sync_rst) begin
                r_c_pre_slc_rnd <= '0;
            end else if (g_adv_pip_ln) begin
                // advance pipeline
                for (int unsigned d=DSP_BLK_OUTPUT_STG_REG_CHAIN_LEN-1; d>0; --d) begin
                    r_c_pre_slc_rnd[d] <= r_c_pre_slc_rnd[d-1];
                end

                r_c_pre_slc_rnd[0] <= g_c_from_dsp_blk;
            end
        end
    end
endgenerate
// --------------------
endmodule

`default_nettype wire
