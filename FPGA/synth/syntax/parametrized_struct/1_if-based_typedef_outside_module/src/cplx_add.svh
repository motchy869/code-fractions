`ifndef CPLX_ADD_SVH_INCLUDED
`define CPLX_ADD_SVH_INCLUDED

// Verible directive
// verilog_lint: waive-start parameter-name-style
// verilog_lint: waive-start line-length

`default_nettype none

//! Complex number adder/subtractor
extern module cplx_add #(
    parameter type in_cplx_t, //! input complex number type
    parameter type out_cplx_t //! output complex number type
)(
    input wire logic i_clk, //! clock signal
    input wire logic i_sync_rst, //! reset signal synchronous to clock

    output wire logic o_ready, //! ready signal to upstream side which indicates that the upstream side is allowed to update input data (to this module) right AFTER the next rising edge of the clock
    input wire logic i_input_valid, //! Valid signal from upstream side. This is also used as freezing signal like clock-enable deassertion. When this is low, the module internal state is frozen.
    input in_cplx_t i_a, //! first complex number a
    input in_cplx_t i_b, //! second complex number b
    input wire logic i_sub, //! Add/subtract dynamic control signal. 0/1: add/subtract. If this signal is compile-time constant, the synthesis tool will optimize-out the unused logics.

    input wire logic i_ds_ready, //! ready signal from downstream side which indicates that this module is allowed to update output data (to downstream side) right AFTER the next rising edge of the clock
    output wire logic o_output_valid, //! output valid signal
    output out_cplx_t o_c //! a+b or a-b
);

`default_nettype wire

`endif // CPLX_ADD_SVH_INCLUDED
