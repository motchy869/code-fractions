`ifndef RAM_SP_WF_SVH_INCLUDED
`define RAM_SP_WF_SVH_INCLUDED

extern module ram_sp_wf#(
    parameter int WORD_BIT_WIDTH = 32, //! word bit width, **must be power of 2**
    parameter int DEPTH = 8, //! depth of RAM, **must be power of 2**
    parameter bit USE_OUTPUT_REG = 0 //! output register option, 0/1: not use/ use
)(
    input wire logic i_clk, //! clock signal
    input wire logic i_sync_rst, //! synchronous reset signal
    input wire logic i_we, //! write enable signal
    input wire logic [$clog2(DEPTH)-1:0] i_word_addr, //! word address
    input wire logic [WORD_BIT_WIDTH-1:0] i_data, //! input data
    input wire logic [WORD_BIT_WIDTH/8-1:0] i_wr_byte_en, //! write byte enable signal
    output wire logic [WORD_BIT_WIDTH-1:0] o_data //! output data
);

`endif
