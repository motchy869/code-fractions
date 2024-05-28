`ifndef MY_MOD_SVH_INCLUDED
`define MY_MOD_SVH_INCLUDED

`include "axi4_lite_if_pkg.svh"

`default_nettype none

//! simple DUT to test my_mod_csr
extern module my_mod (
    input wire logic i_clk, //! clock signal
    input wire logic i_sync_rst, //! synchronous reset signal
    axi4_lite_if.slv_port if_s_axi4_lite //! AXI4-Lite slave interface
);

`default_nettype wire

`endif
