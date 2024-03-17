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
    input wire logic [$clog2(S_MAX_IN)-1:0] i_frag_size, //! the number of the input fragment **clipped up to `S_MAX_IN`**
    input wire T i_frag[S_MAX_IN], //! input fragment
    output wire logic o_ds_ready, //! output ready signal which indicates that the upstream-side can send the next fragment
    //! @end

    //! @virtualbus ds_side_if @dir out downstream side interface
    //! input ready signal which indicates that the downstream is ready to accept the output chunk
    input wire logic i_ds_ready,
    output wire logic o_chunk_valid, //! output valid signal which indicates that the output chunk is valid
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
localparam int FRAG_BUF_CAP = 2*S_MAX_IN; //! capacity of the fragment buffer
localparam int CLOG2_FRAG_BUF_CAP = $clog2(FRAG_BUF_CAP); //! $clog2 of the fragment buffer capacity

// ---------- working signals and storage ----------
// input clipping
wire [$clog2(S_MAX_IN)-1:0] g_clipped_frag_size; //! fragment size input clipped up to `S_MAX_IN`
assign g_clipped_frag_size = $bits(g_clipped_frag_size)'(int'(i_frag_size) > S_MAX_IN ? S_MAX_IN : int'(i_frag_size));

var T r_frag_buf[FRAG_BUF_CAP]; //! buffer to store fragments, 2-page buffer
var logic [CLOG2_FRAG_BUF_CAP-1:0] r_buf_cnt; //! count of the fragments in the buffer
var logic r_read_page_ptr; //! Read pointer of the fragment buffer. Note that there is only 2 pages in the fragment buffer.
wire g_push_en; //! enable signal to push the fragment into the buffer
assign g_push_en = o_ds_ready && i_frag_valid;
wire [CLOG2_FRAG_BUF_CAP-1:0] g_write_elem_start_ptr; //! write starting pointer of the fragment buffer
assign g_write_elem_start_ptr = (r_read_page_ptr == 1'b0) ? r_buf_cnt : CLOG2_FRAG_BUF_CAP'((int'(r_buf_cnt) < S_OUT) ? S_OUT + int'(r_buf_cnt) : int'(r_buf_cnt) - S_OUT);
wire g_pop_en; //! enable signal to pop the fragment from the buffer
assign g_pop_en = i_ds_ready && o_chunk_valid;
// --------------------

// Drive output signals.
assign o_ds_ready = !i_sync_rst && (i_ds_ready ? int'(r_buf_cnt) - S_OUT : int'(r_buf_cnt)) + int'(g_clipped_frag_size) < FRAG_BUF_CAP;
assign o_chunk_valid = !i_sync_rst && int'(r_buf_cnt) >= S_OUT;
assign o_chunk = r_frag_buf[int'(r_read_page_ptr)*S_OUT+:S_OUT];

//! Update the fragment buffer count.
always_ff @(posedge i_clk) begin: update_buf_cnt
    if (i_sync_rst) begin
        r_buf_cnt <= '0;
    end else begin
        r_buf_cnt <= r_buf_cnt + (g_push_en ? g_clipped_frag_size : '0) - (g_pop_en ? S_OUT : '0);
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

//! Calculate the write element pointer of the fragment buffer.
function automatic int calcWriteElemPointer(input int offset, input int increment);
    const int ptr = offset + increment;
    if (ptr < FRAG_BUF_CAP) begin
        return ptr;
    end else begin
        return ptr - FRAG_BUF_CAP;
    end
endfunction

//! Update the fragment buffer.
always_ff @(posedge i_clk) begin: update_fragment_buffer
    if (i_sync_rst) begin
        r_frag_buf <= '{default:0};
        r_buf_cnt <= '0;
    end else if (g_push_en) begin
        for (int i=0; i<S_MAX_IN; ++i) begin
            if (i < i_frag_size) begin
                r_frag_buf[calcWriteElemPointer(g_write_elem_start_ptr, i)] <= i_frag[i];
            end
        end
    end
end

endmodule

`default_nettype wire
