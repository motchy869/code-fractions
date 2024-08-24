// Verible directive
// verilog_lint: waive-start parameter-name-style
// verilog_lint: waive-start line-length

`include "avmm_if_pkg_v0_1_0.svh"
`include "avmm_if_v0_1_0.svh"

`default_nettype none

//! A quite simple Avalon-MM agent template with 4 writable registers.
//! Read and write latency is 0 and 1, respectively.
extern module my_avmm_agt_template_v0_1_0 #(
    parameter int AVMM_ADDR_BIT_WIDTH = 2, //! Bit width of Avalon-MM address bus. Typically log2(number of registers). Note that in default Avalon uses **byte** addressing in hosts and **word** addressing in agents.
    parameter int AVMM_DATA_BIT_WIDTH = 32 //! bit width of Avalon-MM data bus
)(
    input wire i_clk, //! clock signal
    input wire i_sync_rst, //! reset signal synchronous to clock
    avmm_if_v0_1_0.agt_pt if_agt_avmm //! Avalon-MM agent interface
);

`default_nettype wire
