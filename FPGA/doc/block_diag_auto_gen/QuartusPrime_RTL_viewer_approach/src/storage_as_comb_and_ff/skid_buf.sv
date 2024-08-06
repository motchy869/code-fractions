// Verible directives
// verilog_lint: waive-start parameter-name-style
// verilog_lint: waive-start line-length

`default_nettype none

`include "types.svh"
`include "sub_mods.svh"

module skid_buf #(
    parameter int unsigned BIT_WIDTH_DATA = 8 //! bit width of data
)(
    input wire logic i_clk, //! clock signal
    input wire logic i_sync_rst, //! synchronous reset signal

    //! @virtualbus us_side_if @dir in upstream side interface
    input wire logic i_us_valid,
    input wire logic [BIT_WIDTH_DATA-1:0] i_us_data, //! data from upstream
    output wire logic o_us_ready, //! A ready signal to upstream. **masked by** `i_sync_rst` (to avoid losing data at transition to reset state).
    //! @end

    //! @virtualbus ds_side_if @dir out downstream side interface
    //! ready signal from downstream
    input wire logic i_ds_ready,
    output wire logic [BIT_WIDTH_DATA-1:0] o_ds_data, //! data to downstream
    output wire logic o_ds_valid //! valid signal to downstream
    //! @end
);
// ---------- parameters ----------
// --------------------

// ---------- parameter validation ----------
// --------------------

// ---------- functions ----------
// --------------------

// ---------- sub-modules ----------
// Quartus Prime Lite doesn't support nested module declarations.
// --------------------

// ---------- internal signal and storage ----------
var buf_ptr_t r_rd_ptr; //! FIFO read pointer
var buf_ptr_t r_wr_ptr; //! FIFO write pointer
buf_ptr_t w_nxt_rd_ptr; //! next read pointer
buf_ptr_t w_nxt_wr_ptr; //! next write pointer

wire g_buf_full; //! buffer full signal
assign g_buf_full = r_rd_ptr.idx == r_wr_ptr.idx && r_rd_ptr.phase != r_wr_ptr.phase;
wire g_buf_empty; //! buffer empty signal
assign g_buf_empty = r_rd_ptr.idx == r_wr_ptr.idx && r_rd_ptr.phase == r_wr_ptr.phase;
wire g_push_en; //! push enable signal
assign g_push_en = i_us_valid && o_us_ready;
wire g_pop_en; //! pop enable signal
assign g_pop_en = o_ds_valid && i_ds_ready;

var logic [1:0][BIT_WIDTH_DATA-1:0] r_fifo_buf; //! FIFO buffer
wire [1:0][BIT_WIDTH_DATA-1:0] w_nxt_fifo_buf_data; //! next FIFO buffer data
// --------------------

// ---------- instances ----------
//! Determines the next read pointer.
g_nxt_rd_ptr g_nxt_rd_ptr (
    .i_sync_rst(i_sync_rst),

    .i_pop_en(g_pop_en),
    .o_ptr(w_nxt_rd_ptr)
);

//! Determines the next write pointer.
g_nxt_wr_ptr g_nxt_wr_ptr (
    .i_sync_rst(i_sync_rst),

    .i_push_en(g_push_en),
    .o_ptr(w_nxt_wr_ptr)
);

//! Determines the next FIFO buffer data.
g_nxt_fifo_buf #(
    .BIT_WIDTH_DATA(BIT_WIDTH_DATA)
) g_nxt_fifo_buf (
    .i_sync_rst(i_sync_rst),

    .i_wr_idx(r_wr_ptr.idx),
    .i_wr_en(g_push_en),
    .i_wr_data(i_us_data),
    .o_nxt_data(w_nxt_fifo_buf_data)
);
// --------------------

// ---------- Drive output signals. ----------
assign o_us_ready = !i_sync_rst && !g_buf_full;
assign o_ds_valid = !g_buf_empty;
assign o_ds_data = r_fifo_buf[r_rd_ptr.idx];
// --------------------

// ---------- blocks ----------
//! Updates read and write pointers.
always_ff @(posedge i_clk) begin: blk_update_ptrs
    r_rd_ptr <= w_nxt_rd_ptr;
    r_wr_ptr <= w_nxt_wr_ptr;
end

//! Updates FIFO buffer data.
always_ff @(posedge i_clk) begin: blk_update_fifo_buf
    r_fifo_buf <= w_nxt_fifo_buf_data;
end
// --------------------
endmodule

`default_nettype wire
