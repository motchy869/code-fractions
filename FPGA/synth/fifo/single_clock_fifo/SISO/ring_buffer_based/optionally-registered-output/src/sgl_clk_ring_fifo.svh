`ifndef SGL_CLK_RING_FIFO_SVH_INCLUDED
`define SGL_CLK_RING_FIFO_SVH_INCLUDED

// Verible directives
// verilog_lint: waive-start parameter-name-style
// verilog_lint: waive-start line-length

`default_nettype none

//! Single-clock symmetric FIFO.
//! The output can be optionally registered.
//! Some techniques used in this design are base on '[Simulation and Synthesis Techniques for Asynchronous FIFO Design](http://www.sunburst-design.com/papers/CummingsSNUG2002SJ_FIFO1.pdf)'
extern module sgl_clk_ring_fifo #(
    parameter int DATA_BIT_WIDTH = 8, //! data bit width
    parameter int DEPTH = 16, //! FIFO depth
    parameter bit EN_US_OUT_REG = 1'b0, //! enable output register on upstream side
    parameter bit EN_DS_OUT_REG = 1'b0 //! enable output register on downstream side
)(
    input wire logic i_clk, //! clock signal
    input wire logic i_sync_rst, //! synchronous reset signal

    //! @virtualbus us_side_if @dir in upstream side interface
    input wire logic i_we, //! write enable
    input wire logic [DATA_BIT_WIDTH-1:0] i_data, //! input data
    output wire logic o_full, //! full flag
    //! @end

    //! @virtualbus ds_side_if @dir out downstream side interface
    //! read enable
    input wire logic i_re,
    output wire logic [DATA_BIT_WIDTH-1:0] o_data, //! output data
    output wire logic o_empty //! empty flag
    //! @end
);

`default_nettype wire

`endif // SGL_CLK_RING_FIFO_SVH_INCLUDED
