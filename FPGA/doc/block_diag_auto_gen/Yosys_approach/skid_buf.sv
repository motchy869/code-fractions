// Verible directives
// verilog_lint: waive-start parameter-name-style
// verilog_lint: waive-start line-length

`include "sub_mods.svh"

`default_nettype none

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
// --------------------

// ---------- internal signal and storage ----------
wire r_rd_ptr_idx; //! read pointer index
wire r_rd_ptr_phase; //! read pointer phase
wire r_wr_ptr_idx; //! write pointer index
wire r_wr_ptr_phase; //! write pointer phase

wire g_buf_full; //! buffer full signal
assign g_buf_full = r_rd_ptr_idx == r_wr_ptr_idx && ~(r_rd_ptr_phase == r_wr_ptr_phase);
wire g_buf_empty; //! buffer empty signal
assign g_buf_empty = r_rd_ptr_idx == r_wr_ptr_idx && r_rd_ptr_phase == r_wr_ptr_phase;
wire g_push_en; //! push enable signal
assign g_push_en = i_us_valid && o_us_ready;
wire g_pop_en; //! pop enable signal
assign g_pop_en = o_ds_valid && i_ds_ready;
// --------------------

// ---------- instances ----------
r_rd_ptr r_rd_ptr (
    .i_clk(i_clk),
    .i_sync_rst(i_sync_rst),

    .i_pop_en(g_pop_en),
    .o_idx(r_rd_ptr_idx),
    .o_phase(r_rd_ptr_phase)
);

r_wr_ptr r_wr_ptr (
    .i_clk(i_clk),
    .i_sync_rst(i_sync_rst),

    .i_push_en(g_push_en),
    .o_idx(r_wr_ptr_idx),
    .o_phase(r_wr_ptr_phase)
);

r_fifo_buf r_fifo_buf (
    .i_clk(i_clk),
    .i_sync_rst(i_sync_rst),

    .i_wr_idx(r_wr_ptr_idx),
    .i_wr_en(g_push_en),
    .i_wr_data(i_us_data),
    .i_rd_idx(r_rd_ptr_idx),
    .o_rd_data(o_ds_data)
);
// --------------------

// ---------- Drives output signals. ----------
assign o_us_ready = i_sync_rst ? 1'b0 : !g_buf_full;
assign o_ds_valid = !g_buf_empty;
// --------------------

// ---------- blocks ----------
// --------------------
endmodule

`default_nettype wire
