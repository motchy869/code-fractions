// Verible directive
// verilog_lint: waive-start parameter-name-style

`default_nettype none

//! Receives data fragments from upstream and stores them in a buffer to construct data chunks.
//! When the downstream is ready and there is a chunk in the buffer, it sends the chunk to the downstream.
//!
//! NOTE: **This module is not tested yet at all.**
module fragment_to_chunk #(
    parameter int S_MAX_IN = 4, //! max size of the input fragment
    parameter int S_OUT = 8, //! size of the output chunk
    parameter type T = logic //! data type of the elements
)(
    //! common ports
    input wire logic i_clk, //! input clock
    input wire logic i_sync_rst, //! input reset synchronous to the input clock

    //! @virtualbus us_side_if @dir in upstream side interface
    input wire logic i_frag_valid, //! input valid signal which indicates that the input fragment is valid
    input wire logic [$clog2(S_MAX_IN+1)-1:0] i_frag_size, //! The size of the input fragment. When this exceeds `S_MAX_IN`, `o_next_frag_ready` will be deasserted.
    input wire logic i_pad_tail, //! Directive to append zero or more empty (all bits are set to 0) elements to the fragment to ensure that the internal buffer has integer multiple of `S_OUT` elements. This can be used to flush the internal buffer.
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

//! parameter validation
generate
    if (S_MAX_IN > S_OUT) begin: gen_input_fragment_size_param_validation
        $error("S_MAX_IN must be less than or equal to S_OUT");
    end
endgenerate

// local parameters
localparam int FRAG_BUF_CAP = 2*S_OUT; //! capacity of the fragment buffer
localparam int CLOG2_FRAG_BUF_CAP = $clog2(FRAG_BUF_CAP); //! $clog2 of the fragment buffer capacity

// ---------- functions ----------
//! Calculate the write element pointer of the fragment buffer.
function automatic logic [CLOG2_FRAG_BUF_CAP-1:0] calcWriteElemPointer(
    input logic [CLOG2_FRAG_BUF_CAP-1:0] frag_head_ptr, //! the input fragment's head pointer in the fragment buffer
    input logic [CLOG2_FRAG_BUF_CAP-1:0] elem_idx //! element index in the input fragment
);
    localparam logic [CLOG2_FRAG_BUF_CAP:0] _FRAG_BUF_CAP = (CLOG2_FRAG_BUF_CAP+1)'(FRAG_BUF_CAP);
    const logic [CLOG2_FRAG_BUF_CAP:0] ptr = (CLOG2_FRAG_BUF_CAP+1)'(frag_head_ptr) + (CLOG2_FRAG_BUF_CAP+1)'(elem_idx);
    if (ptr < _FRAG_BUF_CAP) begin
        return CLOG2_FRAG_BUF_CAP'(ptr);
    end else begin
        return CLOG2_FRAG_BUF_CAP'(ptr - _FRAG_BUF_CAP);
    end
endfunction

//! Calculate the padding fragment size.
function automatic logic [CLOG2_FRAG_BUF_CAP-1:0] calcPadFragSize(
    input logic [CLOG2_FRAG_BUF_CAP-1:0] frag_head_ptr, //! the input fragment's head pointer in the fragment buffer
    input logic [CLOG2_FRAG_BUF_CAP-1:0] frag_size // ! the size of the input fragment
);
    localparam logic [CLOG2_FRAG_BUF_CAP-1:0] _S_OUT = CLOG2_FRAG_BUF_CAP'(S_OUT);
    localparam logic [CLOG2_FRAG_BUF_CAP-1:0] _FRAG_BUF_CAP = CLOG2_FRAG_BUF_CAP'(FRAG_BUF_CAP);
    const logic [CLOG2_FRAG_BUF_CAP-1:0] tail_end_ptr = calcWriteElemPointer(frag_head_ptr, frag_size);
    if (tail_end_ptr inside {0, _S_OUT}) begin
        return 0;
    end else if (tail_end_ptr < _S_OUT) begin
        return _S_OUT - tail_end_ptr;
    end else begin
        return _FRAG_BUF_CAP - tail_end_ptr;
    end
endfunction
// --------------------

// ---------- working signals and storage ----------
wire logic g_frag_size_good; //! Indicates that the input fragment size is good.
assign g_frag_size_good = i_frag_size <= $bits(i_frag_size)'(S_MAX_IN);

var T r_frag_buf[FRAG_BUF_CAP]; //! buffer to store fragments, 2-page buffer
var logic [CLOG2_FRAG_BUF_CAP-1:0] r_buf_cnt; //! count of the fragments in the buffer
var logic r_read_page_ptr; //! Read pointer of the fragment buffer. Note that there is only 2 pages in the fragment buffer.
wire [CLOG2_FRAG_BUF_CAP-1:0] g_write_elem_start_ptr; //! write starting pointer of the fragment buffer
assign g_write_elem_start_ptr = (r_read_page_ptr == 1'b0) ? r_buf_cnt : (r_buf_cnt < $bits(r_buf_cnt)'(S_OUT)) ? $bits(r_buf_cnt)'(S_OUT) + r_buf_cnt : r_buf_cnt - $bits(r_buf_cnt)'(S_OUT);
wire g_pop_en; //! enable signal to pop a chunk from the buffer
assign g_pop_en = i_ds_ready && o_chunk_valid;
wire g_push_en; //! enable signal to push a fragment into the buffer
assign g_push_en = i_frag_valid && o_next_frag_ready;
wire logic [CLOG2_FRAG_BUF_CAP-1:0] g_pad_frag_size; //! The size of the 'padding fragment' (the number of the elements added to the input fragment according to `i_pad_tail`).
assign g_pad_frag_size = i_pad_tail ? calcPadFragSize(g_write_elem_start_ptr, i_frag_size) : '0;
// --------------------

// Drive output signals.
assign o_next_frag_ready = !i_sync_rst && g_frag_size_good && (g_pop_en ? r_buf_cnt - $bits(r_buf_cnt)'(S_OUT) : r_buf_cnt) + i_frag_size <= $bits(r_buf_cnt)'(FRAG_BUF_CAP);
assign o_chunk_valid = !i_sync_rst && r_buf_cnt >= $bits(r_buf_cnt)'(S_OUT);
assign o_chunk = r_frag_buf[$bits(r_buf_cnt)'(r_read_page_ptr)*$bits(r_buf_cnt)'(S_OUT)+:S_OUT];

//! Update the fragment buffer count.
always_ff @(posedge i_clk) begin: update_buf_cnt
    if (i_sync_rst) begin
        r_buf_cnt <= '0;
    end else begin
        r_buf_cnt <= r_buf_cnt + (g_push_en ? i_frag_size + g_pad_frag_size : '0) - (g_pop_en ? $bits(r_buf_cnt)'(S_OUT) : '0);
    end
end

//! Update the read page pointer.
always_ff @(posedge i_clk) begin: update_read_page_ptr
    if (i_sync_rst) begin
        r_read_page_ptr <= 1'b0;
    end else if (g_pop_en) begin
        r_read_page_ptr <= ~r_read_page_ptr;
    end
end

//! Update the fragment buffer.
always_ff @(posedge i_clk) begin: update_fragment_buffer
    if (i_sync_rst) begin
        r_frag_buf <= '{default:0};
        r_buf_cnt <= '0;
    end else if (g_push_en) begin
        for (logic [CLOG2_FRAG_BUF_CAP-1:0] i=0; i<CLOG2_FRAG_BUF_CAP'(S_MAX_IN); ++i) begin
            if (i < i_frag_size + g_pad_frag_size) begin
                r_frag_buf[calcWriteElemPointer(g_write_elem_start_ptr, i)] <= (i < i_frag_size) ? i_frag[$clog2(S_MAX_IN)'(i)] : '{default:'0};
            end
        end
    end
end

endmodule

`default_nettype wire
