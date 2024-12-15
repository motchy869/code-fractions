// Verible directive
// verilog_lint: waive-start parameter-name-style
// verilog_lint: waive-start line-length

`include "cnt_leading_zeros_v0_1_1_pkg.svh"

`default_nettype none

//! Converts input fixed-point number to IEEE 754-2008 format floating-point number.
//! NEITHER feed-stop nor back-pressure flow control are supported.
//!
//! cycle latency: 6
module fxd_pt2flt_pt_v0_1_0 #(
    parameter int unsigned BW_IN_INT = 4, //! bit width of input integer part
    parameter int unsigned BW_IN_FRAC = 12, //! bit width of input fractional part
    parameter int unsigned BW_OUT_EXP = 8, //! bit width of output exponent
    parameter int unsigned BW_OUT_FRAC = 23 //! bit width of output fractional part
)(
    input wire logic i_clk, //! input clock
    input wire logic i_sync_rst, //! input reset signal synchronous to the input clock
    input wire logic i_freeze, //! freeze directive, which stops all state transitions except for the reset
    //! @virtualbus us_side_if @dir in upstream side interface
    input wire logic i_in_valid, //! Indicates that the input data is valid.
    input wire logic signed [BW_IN_INT+BW_IN_FRAC-1:0] i_in_val, //! input fixed-point number
    //! @end
    //! @virtualbus ds_side_if @dir out downstream side interface
    //! Indicates that the pipeline is filled with processed data, and the downstream side can start using the output data. This signal should be used just for initial garbage data skip, NOT for flow control.
    output wire logic o_pipeline_filled,
    output wire logic [1+BW_OUT_EXP+BW_OUT_FRAC-1:0] o_out_val //! output floating-point number
    //! @end
);
// ---------- parameters ----------
typedef int unsigned uint_t;

localparam logic [BW_OUT_EXP-1:0] EXP_OFFSET = {1'b0,{BW_OUT_EXP-1{1'b1}}}; //! exponent offset
localparam logic [BW_OUT_EXP-1:0] EXP_MAX = {{BW_OUT_EXP-1{1'b1}},1'b0}; //! maximum exponent
localparam uint_t BW_IN = BW_IN_INT + BW_IN_FRAC; //! bit width of input
localparam uint_t BW_OUT = 1+BW_OUT_EXP+BW_OUT_FRAC; //! bit width of output
localparam uint_t BW_N_LZ = $clog2(BW_IN+1); //! bit width of 'number of leading zeros'
localparam uint_t BW_FRAC_BS_L_IDX = $clog2(BW_IN+BW_OUT_FRAC); //! bit width of bit slice lower index to create fractional part
localparam uint_t CLZ_OP_OUT_REG_CHAIN_LEN = (BW_IN + 15)/16; //! count leading zeros (CLZ) operation output register chain length
localparam uint_t CYC_LAT_CLZ_OP = cnt_leading_zeros_v0_1_1_pkg::cycle_latency(0, CLZ_OP_OUT_REG_CHAIN_LEN); //! cycle latency of CLZ operation
localparam uint_t CYC_LAT = 4 + CYC_LAT_CLZ_OP; //! cycle latency of this module
// --------------------

// ---------- parameter validation ----------
generate
    if (BW_IN_INT == '0) begin: gen_validate_BW_IN_INT
        nonexistent_module_to_throw_a_custom_error_message_for too_small_BW_IN_INT();
    end
    if (BW_OUT_EXP == '0) begin: gen_validate_BW_OUT_EXP
        nonexistent_module_to_throw_a_custom_error_message_for too_small_BW_OUT_EXP();
    end
    if (BW_OUT_FRAC == '0) begin: gen_validate_BW_OUT_FRAC
        nonexistent_module_to_throw_a_custom_error_message_for too_small_BW_OUT_FRAC();
    end
endgenerate
// --------------------

// ---------- functions ----------
// --------------------

// ---------- signals and storage ----------
var logic [CYC_LAT-1:0] r_vld_delay_line; //! delay line for valid signal
var logic [BW_IN-1:0] r_abs_val; //! absolute value of input
var logic [CYC_LAT-1:0] r_sgn; //! sign of input
var logic [CYC_LAT_CLZ_OP+1:0][BW_IN+BW_OUT_FRAC-1:0] r_te_abs_val; //! absolute input value with tail extended zeros
wire [BW_N_LZ-1:0] w_n_lz; //! number of leading zeros
var logic [BW_N_LZ-1:0] r_n_lz; //! number of leading zeros (delayed)
var logic [BW_OUT_FRAC-1:0] r_frac; //! fractional part

//! classification of the size of the absolute value of input
typedef enum logic [1:0] {
    ABS_VAL_ZERO,
    ABS_VAL_LESS_THAN_ONE,
    ABS_VAL_NO_LESS_THAN_ONE
} abs_val_size_cls_t;

//! type for over-range check result
typedef enum logic [1:0] {
    RANGE_TOO_SMALL,
    RANGE_OK,
    RANGE_TOO_LARGE
} ov_rng_chk_res_t;

var abs_val_size_cls_t [1:0] r_cls_abs_val_size; //! size classification of the absolute value of input
var ov_rng_chk_res_t [1:0] r_ov_rng_chk_res; //! over-range check result
var logic [1:0][BW_OUT_EXP-1:0] r_exp; //! exponent
var logic [BW_FRAC_BS_L_IDX-1:0] r_frac_bs_l_idx; // bit slice lower index to create fractional part
// --------------------

// ---------- instances ----------
//! Counts the number of leading zeros of the absolute value of input.
cnt_leading_zeros_v0_1_1 #(
    .BW_IN(BW_IN),
    .INPUT_REG_CHAIN_LEN(0),
    .OUTPUT_REG_CHAIN_LEN(CLZ_OP_OUT_REG_CHAIN_LEN)
) cnt_lz (
    .i_clk(i_clk),
    .i_sync_rst(i_sync_rst),
    .i_freeze(i_freeze),
    .i_in_valid(i_in_valid),
    .i_in_val(r_abs_val),
    .o_pipeline_filled(),
    .o_out_val(w_n_lz)
);
// --------------------

// --------------------

// ---------- Drives output signals. ----------
assign o_pipeline_filled = r_vld_delay_line[$high(r_vld_delay_line)];
assign o_out_val = {r_sgn[3+CYC_LAT_CLZ_OP], r_exp[1], r_frac};
// --------------------

// ---------- blocks ----------
//! Updates valid signal delay line.
always_ff @(posedge i_clk) begin: blk_update_valid_sig_delay_line
    if (i_sync_rst) begin
        r_vld_delay_line <= '0;
    end else if (!i_freeze) begin
        r_vld_delay_line <= {r_vld_delay_line[$high(r_vld_delay_line)-1:0],i_in_valid};
    end
end

//! Calculates the absolute value of input.
always_ff @(posedge i_clk) begin: blk_calc_abs_val
    if (i_sync_rst) begin
        r_abs_val <= '0;
    end else if (!i_freeze) begin
        r_abs_val <= i_in_val[$high(i_in_val)] ? -i_in_val : i_in_val;
    end
end

//! Extracts the sign of input.
always_ff @(posedge i_clk) begin: blk_extract_sign
    if (i_sync_rst) begin
        r_sgn <= '0;
    end else if (!i_freeze) begin
        r_sgn <= {r_sgn[$high(r_sgn)-1:0],i_in_val[$high(i_in_val)]};
    end
end

//! Appends zeros to the absolute value of input.
always_ff @(posedge i_clk) begin: blk_app_zeros_to_abs_val
    if (i_sync_rst) begin
        r_te_abs_val <= '0;
    end else if (!i_freeze) begin
        r_te_abs_val <= {
            r_te_abs_val[$high(r_te_abs_val)-1:0],
            {r_abs_val,{BW_OUT_FRAC{1'b0}}}
        };
    end
end

//! Updates the delayed version of the number of leading zeros.
always_ff @(posedge i_clk) begin: blk_update_delayed_n_lz
    if (i_sync_rst) begin
        r_n_lz <= '0;
    end else if (!i_freeze) begin
        r_n_lz <= w_n_lz;
    end
end

//! Classify the size of the absolute value of input.
always_ff @(posedge i_clk) begin: blk_cls_abs_val_size
    if (i_sync_rst) begin
        r_cls_abs_val_size <= '{default: ABS_VAL_ZERO};
    end else if (!i_freeze) begin
        r_cls_abs_val_size <= {
            r_cls_abs_val_size[0],
            (uint_t'(w_n_lz) < BW_IN) ? ABS_VAL_LESS_THAN_ONE : (uint_t'(w_n_lz) < BW_IN_INT) ? ABS_VAL_NO_LESS_THAN_ONE : ABS_VAL_ZERO
        };
    end
end

//! Check over-range.
always_ff @(posedge i_clk) begin: blk_chk_ov_rng
    if (i_sync_rst) begin
        r_ov_rng_chk_res <= '{default: RANGE_OK};
    end else if (!i_freeze) begin
        r_ov_rng_chk_res[1] <= r_ov_rng_chk_res[0];
        r_ov_rng_chk_res[0] <= (uint_t'(EXP_OFFSET) + uint_t'(w_n_lz) < BW_IN_INT) ? RANGE_TOO_SMALL : //  ⇔ EXP_OFFSET + w_n_lz - BW_IN_INT + 1 < 1
        (uint_t'(EXP_OFFSET) + uint_t'(w_n_lz) + 1 > uint_t'(EXP_MAX) + BW_IN_INT) ? RANGE_TOO_LARGE : RANGE_OK; // ⇔ EXP_OFFSET + w_n_lz - BW_IN_INT + 1> EXP_MAX
    end
end


//! Calculate exponent.
always_ff @(posedge i_clk) begin: blk_calc_exp
    if (i_sync_rst) begin
        r_exp <= '0;
    end else if (!i_freeze) begin
        r_exp[1] <= r_exp[0];
        r_exp[0] <= (r_cls_abs_val_size[0] == ABS_VAL_ZERO || r_ov_rng_chk_res[0] == RANGE_TOO_SMALL) ? '0 :
        (r_ov_rng_chk_res[0] == RANGE_TOO_LARGE) ? EXP_MAX : EXP_OFFSET + BW_OUT_EXP'(BW_IN_INT) - BW_OUT_EXP'(r_n_lz) - BW_OUT_EXP'(1);
    end
end

//! Calculate fractional part bit slice lower index.
always_ff @(posedge i_clk) begin: blk_frac_bs_l_idx
    if (i_sync_rst) begin
        r_frac_bs_l_idx <= '0;
    end else if (!i_freeze) begin
        r_frac_bs_l_idx <= (r_ov_rng_chk_res[0] == RANGE_OK) ? BW_FRAC_BS_L_IDX'(BW_IN) - BW_FRAC_BS_L_IDX'(r_n_lz) - BW_FRAC_BS_L_IDX'(1) : '0;
    end
end

//! Calculates fractional part.
always_ff @(posedge i_clk) begin: blk_calc_frac_part
    if (i_sync_rst) begin
        r_frac <= '0;
    end else if (!i_freeze) begin
        r_frac <= (r_ov_rng_chk_res[1] == RANGE_OK) ? r_te_abs_val[CYC_LAT_CLZ_OP+1][r_frac_bs_l_idx+:BW_OUT_FRAC] : '0;
    end
end
// --------------------
endmodule

`default_nettype wire
