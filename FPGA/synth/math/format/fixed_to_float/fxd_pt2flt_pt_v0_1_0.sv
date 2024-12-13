// Verible directive
// verilog_lint: waive-start parameter-name-style
// verilog_lint: waive-start line-length

`default_nettype none

//! Converts input fixed-point number to IEEE 754-2008 format floating-point number.
//! NEITHER feed-stop nor back-pressure flow control are supported.
module fxd_pt2flt_pt_v0_1_0 #(
    parameter int unsigned BW_IN_INT = 4, //! bit width of input integer part
    parameter int unsigned BW_IN_FRAC = 12, //! bit width of input fractional part
    parameter int unsigned BW_OUT_EXP = 8, //! bit width of output exponent
    parameter int unsigned BW_OUT_FRAC = 23, //! bit width of output fractional part
    parameter int unsigned INPUT_REG_CHAIN_LEN = 1, //! Input register chain length. When this is set to 0, the input registers are not instantiated. Modern fitting tools will utilize these registers for register re-timing to achieve better timing closure.
    parameter int unsigned OUTPUT_REG_CHAIN_LEN = 1 //! Output register chain length. When this is set to 0, the output registers are not instantiated. Like the input register chain, these registers may also have positive effect for better timing closure.
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
localparam int unsigned BW_IN = BW_IN_INT + BW_IN_FRAC; //! bit width of input
localparam int unsigned CLZ_OP_IO_REG_CHAIN_LEN = (BW_IN + 15)/16; //! count leading zeros (CLZ) operation input and output register chain length
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
wire signed [BW_IN-1:0] w_in_val; //! input fixed-point number
// --------------------

// ---------- instances ----------
reg_chain_v0_1_0 #(
    .CHAIN_LEN(INPUT_REG_CHAIN_LEN),
    .T(logic signed [BW_IN-1:0])
) in_reg_chain (
    .i_clk(i_clk),
    .i_sync_rst(i_sync_rst),
    .i_freeze(i_freeze),
    .i_us_data(i_in_val),
    .o_ds_data(w_in_val)
);
// --------------------

// --------------------

// ---------- Drives output signals. ----------
// --------------------

// ---------- blocks ----------
// --------------------
endmodule

`default_nettype wire
