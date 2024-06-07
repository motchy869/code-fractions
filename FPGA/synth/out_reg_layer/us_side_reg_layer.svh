`ifndef US_SIDE_IF_OUT_REG_LAYER_SVH_INCLUDED
`define US_SIDE_IF_OUT_REG_LAYER_SVH_INCLUDED

// Verible directives
// verilog_lint: waive-start parameter-name-style
// verilog_lint: waive-start line-length

`default_nettype none

//! interface to bundle signals between core and register layer
interface us_side_reg_layer_core_side_if #(
    parameter type T = logic //! data type
);
    logic valid_reg_layer_to_core; //! valid signal from register layer to core
    T data_reg_layer_to_core; //! data from register layer to core
    logic ready_core_to_reg_layer; //! ready signal from core to register layer

    // The core is slave, the register layer is master.
    modport mst_port (
        output valid_reg_layer_to_core,
        output data_reg_layer_to_core,
        input ready_core_to_reg_layer
    );
endinterface

// No demand. Simply connect the partner side ports with appropriate ports of the wrapper module.
// //! interface to bundle signals between register layer and partner
// interface us_side_reg_layer_partner_side_if #(
//     parameter type T = logic //! data type
// );
//     logic valid_partner_to_reg_layer; //! valid signal from partner to register layer
//     T data_partner_to_reg_layer; //! data from partner to register layer
//     logic ready_reg_layer_to_partner; //! ready signal from register layer to partner
// endinterface

//! Output register layer for upstream side interface.
//! This module can be used to attach registered outputs to the existing module's upstream side interface.
//! The essence of this module is equal to skid buffer.
extern module us_side_reg_layer #(
    parameter type T = logic //! data type
)(
    input wire logic i_clk, //! clock signal
    input wire logic i_sync_rst, //! synchronous reset signal

    us_side_reg_layer_core_side_if.mst_port if_m_core_side, //! master interface to the core

    //! @virtualbus partner_side_if @dir in partner side interface
    input wire logic i_valid_from_partner, //! valid signal from partner
    input wire T i_data_from_partner, //! data from partner
    output wire logic o_ready_to_partner //! ready signal to partner
    //! @end
);

`default_nettype wire

`endif // US_SIDE_IF_OUT_REG_LAYER_SVH_INCLUDED
