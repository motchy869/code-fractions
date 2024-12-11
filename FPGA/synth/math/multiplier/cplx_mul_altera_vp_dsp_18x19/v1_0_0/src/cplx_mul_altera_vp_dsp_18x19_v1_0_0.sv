// Verible directive
// verilog_lint: waive-start parameter-name-style
// verilog_lint: waive-start line-length

`default_nettype none

`include "fxd_pt_mul_sum_altera_vp_dsp_18x19_v1_0_0.svh"

//! A fixed-point complex multiplier with optional rounding half to even.
//! For given complex inputs a, b, this module calculates an output c = a\*b.
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
//! ## Definitions
//! - "bit width" of a complex number means the bit width of its real and imaginary parts.
//! ## Assumptions
//! - bit width of the real and imaginary parts of any complex number are equal.
//! ## References
//! 1. [Cyclone V Device Handbook Volume 1: Device Interfaces and Integration](https://www.google.com/url?sa=t&source=web&rct=j&opi=89978449&url=https://cdrdv2-public.intel.com/666995/cv_5v2-683375-666995.pdf&ved=2ahUKEwiuqoyYo8qIAxU5k1YBHRX0HysQFnoECBMQAQ&usg=AOvVaw2qYeHcb4LpcBs5EUXl-iRo)
//! ## changelog
//! ### [Unreleased]
//! - initial release
module cplx_mul_altera_vp_dsp_18x19_v1_0_0 #(
    parameter int unsigned BW_IN_A = 16, //! bit width of the input a, must be <= 18
    parameter int unsigned BW_IN_B = 16, //! bit width of the input b, must be <= **19**
    parameter int unsigned BW_OUT = 16, //! bit width of the output, must be <= 38 - ```BIT_SLC_OFFSET_OUT``` (38 = 18 + 19 + 1)
    parameter int unsigned BIT_SLC_OFFSET_OUT = 0, //! Bit slice offset of the output. When ```BIT_SLICE_OFFSET_OUT``` > 0, (ab)[```BIT_SLICE_OFFSET_OUT```-1:0] is treated as decimal part. The decimal part is simply truncated or rounded (see: ```EN_RND_HF2EVN```).
    parameter int unsigned DSP_BLK_INPUT_STG_REG_CHAIN_LEN = 1, //! The length of the input stage (including pipeline) register chain for the DSP Block. When this is set to 0, the input registers are not used.
    parameter int unsigned DSP_BLK_OUTPUT_STG_REG_CHAIN_LEN = 1, //! The length of the output stage register chain for the DSP Block. When this is set to 0, the output registers are not used.
    parameter bit EN_RND_HF2EVN = 1'b1 //! enable rounding half to even
)(
    input wire logic i_clk, //! input clock
    input wire logic i_sync_rst, //! input reset signal synchronous to the input clock
    //! @virtualbus us_side_if @dir in upstream side interface
    output wire logic o_ready, //! ready signal to upstream side which indicates that the upstream side is allowed to update input data (to this module) right AFTER the next rising edge of the clock
    input wire logic i_input_valid, //! Valid signal from upstream side. This is also used as freezing signal like clock-enable deassertion. When this is low, the module internal state is frozen.
    input wire logic signed [BW_IN_A-1:0] i_re_a, //! real part of input a
    input wire logic signed [BW_IN_A-1:0] i_im_a, //! imaginary part of input a
    input wire logic signed [BW_IN_B-1:0] i_re_b, //! real part of input b
    input wire logic signed [BW_IN_B-1:0] i_im_b, //! imaginary part of input b
    //! @end
    //! @virtualbus ds_side_if @dir out downstream side interface
    //! ready signal from downstream side which indicates that this module is allowed to update output data (to downstream side) right AFTER the next rising edge of the clock
    input wire logic i_ds_ready,
    output wire logic o_output_valid, //! output valid signal
    output wire logic signed [BW_OUT-1:0] o_re_c, //! real part of output c
    output wire logic signed [BW_OUT-1:0] o_im_c //! imaginary part of output c
    //! @end
);
// ---------- parameters ----------
localparam int unsigned BW_LHS_MULT = 18; //! bit width of the left-hand side input to the 18x19 multiplier
localparam int unsigned BW_RHS_MULT = 19; //! bit width of the right-hand side input to the 18x19 multiplier
localparam int unsigned BW_INTERM_PROD = BW_LHS_MULT + BW_RHS_MULT; //! bit width of the intermediate product, {re_a, im_a} x {re_b, im_b}
localparam int unsigned BW_INTERM_SUM = BW_INTERM_PROD + 1; //! bit width of the intermediate sum, real and imaginary parts of the output before slicing/rounding
// --------------------

// ---------- parameter validation ----------
generate
    if (BW_IN_A > BW_LHS_MULT) begin: gen_validate_bw_in_a
        nonexistent_module_to_throw_a_custom_error_message_for invalid_a_bit_width();
    end

    if (BW_IN_B > BW_RHS_MULT) begin: gen_validate_bw_in_b
        nonexistent_module_to_throw_a_custom_error_message_for invalid_b_bit_width();
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
// --------------------

// ---------- clocking blocks ----------
clocking cb @(posedge i_clk); endclocking
// --------------------

// ---------- instances ----------
//! multiplier for real part
fxd_pt_mul_sum_altera_vp_dsp_18x19_v1_0_0 #(
    .BW_IN_A_0(BW_IN_A),
    .BW_IN_B_0(BW_IN_B),
    .BW_IN_A_1(BW_IN_A),
    .BW_IN_B_1(BW_IN_B),
    .BW_OUT(BW_OUT),
    .BIT_SLC_OFFSET_OUT(BIT_SLC_OFFSET_OUT),
    .DSP_BLK_INPUT_STG_REG_CHAIN_LEN(DSP_BLK_INPUT_STG_REG_CHAIN_LEN),
    .DSP_BLK_OUTPUT_STG_REG_CHAIN_LEN(DSP_BLK_OUTPUT_STG_REG_CHAIN_LEN),
    .EN_RND_HF2EVN(EN_RND_HF2EVN)
) mul_re (
    .i_clk(i_clk),
    .i_sync_rst(i_sync_rst),

    .o_ready(o_ready),
    .i_input_valid(i_input_valid),
    .i_a_0(i_re_a),
    .i_b_0(i_re_b),
    .i_a_1(i_im_a),
    .i_b_1(i_im_b),
    .i_sub(1'b1),

    .i_ds_ready(i_ds_ready),
    .o_output_valid(o_output_valid),
    .o_c(o_re_c)
);

//! multiplier for imaginary part
fxd_pt_mul_sum_altera_vp_dsp_18x19_v1_0_0 #(
    .BW_IN_A_0(BW_IN_A),
    .BW_IN_B_0(BW_IN_B),
    .BW_IN_A_1(BW_IN_A),
    .BW_IN_B_1(BW_IN_B),
    .BW_OUT(BW_OUT),
    .BIT_SLC_OFFSET_OUT(BIT_SLC_OFFSET_OUT),
    .DSP_BLK_INPUT_STG_REG_CHAIN_LEN(DSP_BLK_INPUT_STG_REG_CHAIN_LEN),
    .DSP_BLK_OUTPUT_STG_REG_CHAIN_LEN(DSP_BLK_OUTPUT_STG_REG_CHAIN_LEN),
    .EN_RND_HF2EVN(EN_RND_HF2EVN)
) mul_im (
    .i_clk(i_clk),
    .i_sync_rst(i_sync_rst),

    .o_ready(),
    .i_input_valid(i_input_valid),
    .i_a_0(i_re_a),
    .i_b_0(i_im_b),
    .i_a_1(i_im_a),
    .i_b_1(i_re_b),
    .i_sub(1'b0),

    .i_ds_ready(i_ds_ready),
    .o_output_valid(),
    .o_c(o_im_c)
);
// --------------------

// ---------- Drive output signals. ----------
// --------------------

// ---------- blocks ----------
// --------------------

// ---------- assertions ----------
//! assertions
always @cb begin: blk_ast
    if (i_sync_rst == 1'b0) begin
        assert(mul_im.o_ready == mul_re.o_ready) else begin
            $display("assertion violation: mul_im.o_ready: %b, mul_re.o_ready: %b", mul_im.o_ready, mul_re.o_ready);
        end
        assert(mul_im.o_output_valid == mul_re.o_output_valid) else begin
            $display("assertion violation: mul_im.o_output_valid: %b, mul_re.o_output_valid: %b", mul_im.o_output_valid, mul_re.o_output_valid);
        end
    end
end
// --------------------
endmodule
`default_nettype wire
