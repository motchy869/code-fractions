`ifndef DS_SIDE_IF_OUT_REG_LAYER_SVH_INCLUDED
`define DS_SIDE_IF_OUT_REG_LAYER_SVH_INCLUDED

// Verible directives
// verilog_lint: waive-start parameter-name-style
// verilog_lint: waive-start line-length

`default_nettype none

//! interface to bundle signals between core and register layer
interface ds_side_reg_layer_core_side_if#(
    parameter type T = logic //! data type
);
    logic valid_core_to_reg_layer; //! valid signal from core to register layer
    T data_core_to_reg_layer; //! data from core to register layer
    logic ready_reg_layer_to_core; //! ready signal from register layer to core

    // The core is master, the register layer is slave.
    modport slv_port (
        input valid_core_to_reg_layer,
        input data_core_to_reg_layer,
        output ready_reg_layer_to_core
    );
endinterface

// No demand. Simply connect the partner side ports with appropriate ports of the wrapper module.
// //! interface to bundle signals between register layer and partner
// interface ds_side_reg_layer_partner_side_if#(
//     parameter type T = logic //! data type
// );
//     logic valid_reg_layer_to_partner; //! valid signal from register layer to partner
//     T data_reg_layer_to_partner; //! data from register layer to partner
//     logic ready_partner_to_reg_layer; //! ready signal from partner to register layer
// endinterface

//! Output register layer for downstream side interface.
//! This module can be used to attach registered outputs to the existing module ('core')'s downstream side interface.
extern module ds_side_reg_layer#(
    parameter type T = logic //! data type
)(
    input wire logic i_clk, //! clock signal
    input wire logic i_sync_rst, //! synchronous reset signal

    ds_side_reg_layer_core_side_if.slv_port if_s_core_side, //! slave interface to the core

    //! @virtualbus partner_side_if @dir in partner side interface
    output wire logic o_valid_to_partner, //! valid signal to partner
    output wire T o_data_to_partner, //! data to partner
    input wire logic i_ready_from_partner //! ready signal from partner
    //! @end
);

`default_nettype wire

`endif // DS_SIDE_IF_OUT_REG_LAYER_SVH_INCLUDED
