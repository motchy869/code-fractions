// Verible directive
// verilog_lint: waive-start parameter-name-style
// verilog_lint: waive-start line-length

`ifndef SIMPLE_DUT_SVH_INCLUDED
`define SIMPLE_DUT_SVH_INCLUDED

`default_nettype none

//! A simple AXI4-Lite slave with 4 writable registers.
//! This is based on the AXI4-Lite slave template generated from Vivado 2023.2.
extern module simple_dut#(
    parameter int AXI4_LITE_ADDR_BIT_WIDTH = 32, //! bit width of AXI4-Lite address bus
    parameter int AXI4_LITE_DATA_BIT_WIDTH = 32 //! bit width of AXI4-Lite data bus
)(
    input wire logic i_clk, //! clock signal
    input wire logic i_sync_rst, //! reset signal synchronous to clock
    axi4_lite_if.slv_port if_s_axi4_lite, //! AXI4-Lite slave interface
    input wire logic [3:0][AXI4_LITE_DATA_BIT_WIDTH-1:0] i_vec, //! An input vector. Details are described in `or_in_prod`
    input wire logic i_vec_valid, //! A valid signal for the input vector
    output var logic [AXI4_LITE_DATA_BIT_WIDTH-1:0] or_in_prod, //!An inner product between register 0,1,2,3 fields and `i_vec`. The result is truncated to AXI4_LITE_DATA_BIT_WIDTH bits.
    output var logic or_in_prod_valid //! A valid signal for `or_in_prod`
);

`default_nettype wire

`endif
