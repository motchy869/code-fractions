`ifndef SUB_MODS_SVH_INCLUDED
`define SUB_MODS_SVH_INCLUDED

// Verible directives
// verilog_lint: waive-start parameter-name-style
// verilog_lint: waive-start line-length
// verilog_lint: waive-start module-filename

`include "types.svh"

`default_nettype none

module g_nxt_rd_ptr (
    input wire logic i_clk, //! clock signal
    input wire logic i_sync_rst, //! synchronous reset signal

    input wire logic i_pop_en, //! pop enable signal
    output buf_ptr_t o_ptr //! pointer
);
endmodule

module g_nxt_wr_ptr (
    input wire logic i_clk, //! clock signal
    input wire logic i_sync_rst, //! synchronous reset signal

    input wire logic i_push_en, //! push enable signal
    output buf_ptr_t o_ptr //! pointer
);
endmodule

module g_nxt_fifo_buf #(
    parameter int unsigned BIT_WIDTH_DATA = 8 //! bit width of data
)(
    input wire logic i_clk, //! clock signal
    input wire logic i_sync_rst, //! synchronous reset signal

    input wire logic i_wr_idx, //! write index
    input wire logic i_wr_en, //! write-enable signal
    input wire logic [BIT_WIDTH_DATA-1:0] i_wr_data, //! write data

    output wire logic [1:0][BIT_WIDTH_DATA-1:0] o_nxt_data //! next data
);
endmodule

`default_nettype wire

`endif // SUB_MODS_SVH_INCLUDED
