`ifndef SKID_BUF_SVH_INCLUDED
`define SKID_BUF_SVH_INCLUDED

// Verible directives
// verilog_lint: waive-start parameter-name-style
// verilog_lint: waive-start line-length

`default_nettype none

//! simple skid buffer which can be used to cut timing arc
extern module skid_buf#(
    parameter type T = logic //! data type
)(
    input wire logic i_clk, //! clock signal
    input wire logic i_sync_rst, //! synchronous reset signal

    //! @virtualbus us_side_if @dir in upstream side interface
    input wire logic i_us_valid, //! valid signal from upstream
    input wire T i_us_data, //! data from upstream
    output wire logic o_us_ready, //! A ready signal to upstream. **masked by** `i_sync_rst` (to avoid losing data at transition to reset state).
    //! @end

    //! @virtualbus ds_side_if @dir out downstream side interface
    //! ready signal from downstream
    input wire logic i_ds_ready,
    output wire T o_ds_data, //! data to downstream
    output wire logic o_ds_valid //! valid signal to downstream
    //! @end
);

`default_nettype wire

`endif // SKID_BUF_SVH_INCLUDED
