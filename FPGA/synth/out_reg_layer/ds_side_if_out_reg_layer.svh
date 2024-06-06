`ifndef DS_SIDE_IF_OUT_REG_LAYER_SVH_INCLUDED
`define DS_SIDE_IF_OUT_REG_LAYER_SVH_INCLUDED

// Verible directives
// verilog_lint: waive-start parameter-name-style
// verilog_lint: waive-start line-length

`default_nettype none

//! Output register layer for downstream side interface.
//! This module can be used to attach registered outputs to the existing module ('core')'s downstream side interface.
extern module ds_side_if_out_reg_layer #(
    parameter type T = logic //! data type
)(
    input wire logic i_clk, //! clock signal
    input wire logic i_sync_rst, //! synchronous reset signal

    //! @virtualbus core_side_if @dir in core side interface
    input wire logic i_valid_from_core, //! valid signal from core
    input wire T i_data_from_core, //! data from core
    output wire logic o_ready_to_core, //! ready signal to core
    //! @end

    //! @virtualbus partner_side_if @dir in partner side interface
    input wire logic i_ready_from_partner, //! ready signal from partner
    output wire logic o_valid_to_partner, //! valid signal to partner
    output wire T o_data_to_partner //! data to partner
    //! @end
);

//! struct to bundle signals between core and register layer
typedef struct {
    logic valid_core_to_reg_layer; //! valid signal from core to register layer
    T data_core_to_reg_layer; //! data from core to register layer
    logic ready_reg_layer_to_core; //! ready signal from register layer to core
} ds_side_if_out_reg_layer_core_side_sigs_t;

//! struct to bundle signals between register layer and partner
typedef struct {
    logic ready_partner_to_reg_layer; //! ready signal from partner to register layer
    logic valid_reg_layer_to_partner; //! valid signal from register layer to partner
    T data_reg_layer_to_partner; //! data from register layer to partner
} ds_side_if_out_reg_layer_partner_side_sigs_t;

`default_nettype wire

`endif // DS_SIDE_IF_OUT_REG_LAYER_SVH_INCLUDED
