`ifndef US_SIDE_IF_OUT_REG_LAYER_SVH_INCLUDED
`define US_SIDE_IF_OUT_REG_LAYER_SVH_INCLUDED

// Verible directives
// verilog_lint: waive-start parameter-name-style
// verilog_lint: waive-start line-length

`default_nettype none

//! Output register layer for upstream side interface.
//! This module can be used to attach registered outputs to the existing module's upstream side interface.
//! The essence of this module is equal to skid buffer.
extern module ds_side_if_out_reg_layer #(
    parameter type T = logic //! data type
)(
    input wire logic i_clk, //! clock signal
    input wire logic i_sync_rst, //! synchronous reset signal

    //! @virtualbus core_side_if @dir in core side interface
    input wire logic i_ready_from_core, //! ready signal from core
    output wire logic o_valid_to_core, //! valid signal to core
    output wire T o_data_to_core, //! data to core
    //! @end

    //! @virtualbus partner_side_if @dir in partner side interface
    input wire logic i_valid_from_partner, //! valid signal from partner
    input wire T i_data_from_partner, //! data from partner
    output wire logic o_ready_to_partner //! ready signal to partner
    //! @end
);

//! struct to bundle signals between core and register layer
// TODO: Implement me.

//! struct to bundle signals between register layer and partner
// TODO: Implement me.

`default_nettype wire

`endif // US_SIDE_IF_OUT_REG_LAYER_SVH_INCLUDED
