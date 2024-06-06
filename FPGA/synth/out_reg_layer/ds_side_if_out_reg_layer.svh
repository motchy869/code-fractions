`ifndef DS_SIDE_IF_OUT_REG_LAYER_SVH_INCLUDED
`define DS_SIDE_IF_OUT_REG_LAYER_SVH_INCLUDED

// Verible directives
// verilog_lint: waive-start parameter-name-style
// verilog_lint: waive-start line-length

`default_nettype none

//! Output register layer for downstream side interface.
//! This module can be used to attach registered outputs to the existing module's downstream side interface.
extern module ds_side_if_out_reg_layer #(
    parameter type T = logic //! data type
)(
    input wire logic i_clk, //! clock signal
    input wire logic i_sync_rst, //! synchronous reset signal

    //! @virtualbus core_side_if @dir in core side interface
    input wire logic i_core_valid, //! valid signal from core
    input wire T i_core_data, //! data from core
    output wire logic o_core_ready, //! ready signal to core
    //! @end

    //! @virtualbus partner_side_if @dir in partner side interface
    input wire logic i_partner_ready, //! ready signal from partner
    output wire logic o_partner_valid, //! valid signal to partner
    output wire T o_partner_data //! data to partner
    //! @end
);


interface ds_side_if_out_reg_layer_if #(
    parameter type T = logic //! data type
)(
    input wire logic i_clk //! clock signal
);
    logic core_valid; //! valid signal from core
    T core_data; //! data from core
    logic core_ready; //! ready signal to core

    logic partner_ready; //! ready signal from partner
    logic partner_valid; //! valid signal to partner
    T partner_data; //! data to partner
endinterface

`default_nettype wire

`endif // DS_SIDE_IF_OUT_REG_LAYER_SVH_INCLUDED
