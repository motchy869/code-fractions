`ifndef FXD_PT_MUL_SUM_ALTERA_VP_DSP_18X19_V0_1_0_SVH_INCLUDED
`define FXD_PT_MUL_SUM_ALTERA_VP_DSP_18X19_V0_1_0_SVH_INCLUDED

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
extern module fxd_pt_mul_sum_altera_vp_dsp_18x19_v0_1_0 #(
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
    input wire logic signed [BW_IN_A_0-1:0] i_a_0, //! input a_0
    input wire logic signed [BW_IN_B_0-1:0] i_b_0, //! input b_0
    input wire logic signed [BW_IN_A_1-1:0] i_a_1, //! input a_1
    input wire logic signed [BW_IN_B_1-1:0] i_b_1, //! input b_1
    input wire logic i_sub, //! Add/subtract dynamic control signal. 0/1: add/subtract. If this signal is compile-time constant, the synthesis tool will optimize-out the unused logics.
    //! @end
    //! @virtualbus ds_side_if @dir out downstream side interface
    //! ready signal from downstream side which indicates that this module is allowed to update input data (to downstream side) right AFTER the next rising edge of the clock
    input wire logic i_ds_ready,
    output wire logic o_output_valid, //! output valid signal
    output wire logic signed [BW_OUT-1:0] o_c //! output c
    //! @end
);

`default_nettype none

`endif // FXD_PT_MUL_SUM_ALTERA_VP_DSP_18X19_V0_1_0_SVH_INCLUDED
