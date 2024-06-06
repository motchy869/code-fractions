`ifndef FB_SGL_CLK_FIFO_SVH_INCLUDED
`define FB_SGL_CLK_FIFO_SVH_INCLUDED

`default_nettype none

//! Single-clock symmetric FIFO with fully-buffered output.
//! Some techniques used in this design are base on [Simulation and Synthesis Techniques for Asynchronous FIFO Design](http://www.sunburst-design.com/papers/CummingsSNUG2002SJ_FIFO1.pdf)
extern module fb_sgl_clk_fifo #(
    parameter int DATA_BIT_WIDTH = 8, //! data bit width
    parameter int DEPTH = 16 //! FIFO depth
)(
    input wire logic i_clk, //! clock signal
    input wire logic i_sync_rst, //! synchronous reset signal

    //! @virtualbus us_side_if @dir in upstream side interface
    input wire logic i_we, //! write enable
    input wire logic [DATA_BIT_WIDTH-1:0] i_data, //! input data
    output var logic or_full, //! full flag
    //! @end

    //! @virtualbus ds_side_if @dir out downstream side interface
    //! read enable
    input wire logic i_re,
    output var logic [DATA_BIT_WIDTH-1:0] or_data, //! output data
    output var logic or_empty //! empty flag
    //! @end
);

`default_nettype wire

`endif // FB_SGL_CLK_FIFO_SVH_INCLUDED
