`ifndef fxd_pt_mul_sum_altera_vp_dsp_18x19_v1_0_0_SVH_INCLUDED
`define fxd_pt_mul_sum_altera_vp_dsp_18x19_v1_0_0_SVH_INCLUDED

// Verible directive
// verilog_lint: waive-start parameter-name-style
// verilog_lint: waive-start line-length

`include "round_hf2evn_v1_0_0.svh"

`default_nettype none

extern module fxd_pt_mul_sum_altera_vp_dsp_18x19_v1_0_0 #(
    parameter int unsigned BW_IN_A_0 = 16,
    parameter int unsigned BW_IN_B_0 = 16,
    parameter int unsigned BW_IN_A_1 = 16,
    parameter int unsigned BW_IN_B_1 = 16,
    parameter int unsigned BW_OUT = 16,
    parameter int unsigned BIT_SLC_OFFSET_OUT = 0,
    parameter int unsigned DSP_BLK_INPUT_STG_REG_CHAIN_LEN = 1,
    parameter int unsigned DSP_BLK_OUTPUT_STG_REG_CHAIN_LEN = 1,
    parameter bit EN_RND_HF2EVN = 1'b1
)(
    input wire logic i_clk,
    input wire logic i_sync_rst,
    //! @virtualbus us_side_if @dir in upstream side interface
    output wire logic o_ready,
    input wire logic i_input_valid,
    input wire logic signed [BW_IN_A_0-1:0] i_a_0,
    input wire logic signed [BW_IN_B_0-1:0] i_b_0,
    input wire logic signed [BW_IN_A_1-1:0] i_a_1,
    input wire logic signed [BW_IN_B_1-1:0] i_b_1,
    input wire logic i_sub,
    //! @end
    //! @virtualbus ds_side_if @dir out downstream side interface
    input wire logic i_ds_ready,
    output wire logic o_output_valid,
    output wire logic signed [BW_OUT-1:0] o_c //! output c
    //! @end
);

`default_nettype none

`endif // fxd_pt_mul_sum_altera_vp_dsp_18x19_v1_0_0_SVH_INCLUDED
