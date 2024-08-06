`ifndef SUB_MODS_SVH_INCLUDED
`define SUB_MODS_SVH_INCLUDED

// Verible directives
// verilog_lint: waive-start parameter-name-style
// verilog_lint: waive-start line-length
// verilog_lint: waive-start module-filename

`default_nettype none

module r_rd_ptr (
    input wire logic i_clk, //! clock signal
    input wire logic i_sync_rst, //! synchronous reset signal

    input wire logic i_pop_en, //! pop enable signal
    output wire logic o_idx, //! index
    output wire logic o_phase //! phase
);
endmodule

module r_wr_ptr (
    input wire logic i_clk, //! clock signal
    input wire logic i_sync_rst, //! synchronous reset signal

    input wire logic i_push_en, //! push enable signal
    output wire logic o_idx, //! index
    output wire logic o_phase //! phase
);
endmodule

module r_fifo_buf #(
    parameter int unsigned BIT_WIDTH_DATA = 8 //! bit width of data
)(
    input wire logic i_clk, //! clock signal
    input wire logic i_sync_rst, //! synchronous reset signal

    input wire logic i_wr_idx, //! write index
    input wire logic i_wr_en, //! write-enable signal
    input wire logic [BIT_WIDTH_DATA-1:0] i_wr_data, //! write data

    input wire logic i_rd_idx, //! read index
    output wire logic [BIT_WIDTH_DATA-1:0] o_rd_data //! read-enable signal
);
endmodule

`default_nettype wire

`endif // SUB_MODS_SVH_INCLUDED
