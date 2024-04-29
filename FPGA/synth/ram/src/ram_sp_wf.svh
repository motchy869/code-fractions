`ifndef RAM_SP_WF_SVH_INCLUDED
`define RAM_SP_WF_SVH_INCLUDED

extern module ram_sp_wf #(
    parameter int DATA_BIT_WIDTH = 8, //! data bit width
    parameter int DEPTH = 8, //! depth of RAM, **must be power of 2**
    parameter int USE_OUTPUT_REG = 0 //! output register option, 0/1: use/not use
)(
    input wire i_clk, //! clock signal
    input wire i_sync_rst, //! synchronous reset signal
    input wire i_we, //! write enable signal
    input wire [$clog2(DEPTH)-1:0] i_word_addr, //! word address
    input wire [DATA_BIT_WIDTH-1:0] i_data, //! input data
    output wire [DATA_BIT_WIDTH-1:0] o_data //! output data
);

`endif
