`ifndef PN32_SVH_INCLUDED
`define PN32_SVH_INCLUDED

// Verible directive
// verilog_lint: waive-start parameter-name-style
// verilog_lint: waive-start line-length

`default_nettype none

//! Galois LFSR generating PN32 sequence
//! reference docs:
//! 1. Linear-feedback shift register (Wikipedia)
//! 2. Efficient Shift Registers, LFSR Counters, and Long Pseudo-Random Sequence Generators (XAPP052)
extern module pn32 #(
    localparam int unsigned L = 32 //! the length of the shift register (**fixed**, cannot be changed)
)(
    input wire logic i_clk, //! clock signal
    input wire logic i_sync_rst, //! reset signal synchronous to i_clk
    input wire logic i_set_shift_reg, //! instruction to set the shift register
    input wire logic [L-1:0] i_shift_reg_in, //! input data to set the shift register
    output wire logic o_bit_out //! output bit
);

`default_nettype wire

`endif // PN32_SVH_INCLUDED
