// Verible directive
// verilog_lint: waive-start parameter-name-style
// verilog_lint: waive-start line-length

`default_nettype none

//! Receives data fragments from upstream and stores them in a buffer to construct data chunks.
//! When the downstream is ready and there is a chunk in the buffer, it sends the chunk to the downstream.
//!
//! NOTE: **This module is not tested yet at all.**
extern module frag_to_chunk#(
    parameter int S_MAX_IN = 16, //! max size of the input fragment
    parameter int S_OUT = 8, //! The size of the output chunk. **Recommended to be power of 2**. Other large numbers may lead to timing closure failure due to costly modulus operation.
    parameter type T = logic, //! data type of the elements
    localparam int BIT_WIDTH__S_MAX_IN = $clog2(S_MAX_IN+1) //! bit width required to represent `S_MAX_IN`
)(
    //! common ports
    input wire logic i_clk, //! input clock
    input wire logic i_sync_rst, //! input reset synchronous to the input clock

    //! @virtualbus us_side_if @dir in upstream side interface
    input wire logic i_frag_valid, //! input valid signal which indicates that the input fragment is valid
    input wire logic [BIT_WIDTH__S_MAX_IN-1:0] i_frag_size, //! The size of the input fragment. When this exceeds `S_MAX_IN`, `o_next_frag_ready` will be deasserted.
    //! Directive to append zero or more empty (all bits are set to 0) elements to the **internal** fragment buffer to ensure that the internal buffer has integer multiple of `S_OUT` elements.
    //! This can be used to flush the internal buffer.
    //! When `i_pad_tail` is asserted and one of the following conditions is met, appropriate empty elements are added to the fragment buffer.
    //!
    //! (a) `i_frag_valid` is **not** asserted and the number of elements in the internal fragment buffer (let it be called `r_buf_elem_cnt`) is not an integer multiple of `S_OUT`.
    //!
    //! (b) `i_frag_valid` and `o_next_frag_ready` are asserted and the sum of the `r_buf_elem_cnt` and `i_frag_size` is not an integer multiple of `S_OUT`.
    input wire logic i_pad_tail,
    input wire T i_frag[S_MAX_IN], //! input fragment
    output wire logic o_next_frag_ready, //! Output ready signal which indicates that the upstream-side can send the next fragment. Masked by reset.
    //! @end

    //! @virtualbus ds_side_if @dir out downstream side interface
    //! input ready signal which indicates that the downstream side is ready to accept a new chunk
    input wire logic i_ds_ready,
    output wire logic o_chunk_valid, //! Output valid signal which indicates that the output chunk is valid. Masked by reset.
    output wire T o_chunk[S_OUT] //! output chunk
    //! @end
);

`default_nettype wire
