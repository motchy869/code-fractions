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
    parameter int unsigned INPUT_REG_CHAIN_LEN = 1, //! Input register chain length. When this is set to 0, the input registers are not instantiated. Modern fitting tools will utilize this registers for register re-timing to achieve better timing closure.
    parameter int unsigned OUTPUT_REG_CHAIN_LEN = 1 //! Output register chain length. When this is set to 0, the output registers are not instantiated. Like the input register chain, this registers may also have positive effect for better timing closure.
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
// --------------------

// ---------- parameter validation ----------
// --------------------

// ---------- functions ----------
// --------------------

// ---------- signals and storage ----------
// --------------------

// ---------- instances ----------
// --------------------

// --------------------

// ---------- Drives output signals. ----------
// --------------------

// ---------- blocks ----------
// --------------------
endmodule

`default_nettype wire
