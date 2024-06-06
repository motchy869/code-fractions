`ifndef SGL_CLK_FIFO_SVH_INCLUDED
`define SGL_CLK_FIFO_SVH_INCLUDED

`default_nettype none

//! Single-clock symmetric FIFO.
//! Some techniques used in this design are base on [Simulation and Synthesis Techniques for Asynchronous FIFO Design](http://www.sunburst-design.com/papers/CummingsSNUG2002SJ_FIFO1.pdf)
extern module sgl_clk_fifo #(
    parameter int DATA_BIT_WIDTH = 8, //! data bit width
    parameter int DEPTH = 16 //! FIFO depth
)(
    input wire logic i_clk, //! clock signal
    input wire logic i_sync_rst, //! synchronous reset signal

    //! @virtualbus us_side_if @dir in upstream side interface
    input wire logic i_we, //! write enable
    input wire logic [DATA_BIT_WIDTH-1:0] i_data, //! input data
    output wire logic o_full, //! The full flag. **OR-ed with** `i_sync_rst` (to avoid losing data at transition to reset state).
    //! @end

    //! @virtualbus ds_side_if @dir out downstream side interface
    //! read enable
    input wire logic i_re,
    output wire logic [DATA_BIT_WIDTH-1:0] o_data, //! output data
    output wire logic o_empty //! empty flag
    //! @end
);

`default_nettype wire

`endif // SGL_CLK_FIFO_SVH_INCLUDED
