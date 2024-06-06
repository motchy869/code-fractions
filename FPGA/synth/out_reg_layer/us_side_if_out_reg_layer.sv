// Verible directives
// verilog_lint: waive-start parameter-name-style
// verilog_lint: waive-start line-length

`default_nettype none

//! Output register layer for upstream side interface.
//! This module can be used to attach registered outputs to the existing module's upstream side interface.
//! The essence of this module is equal to skid buffer.
module ds_side_if_out_reg_layer #(
    parameter type T = logic //! data type
)(
    input wire logic i_clk, //! clock signal
    input wire logic i_sync_rst, //! synchronous reset signal

    //! @virtualbus core_side_if @dir in core side interface
    input wire logic i_ready_from_core, //! ready signal from core
    output wire logic o_valid_to_core, //! valid signal to core
    output wire T o_data_to_core, //! data to core
    //! @end

    //! @virtualbus partner_side_if @dir in partner side interface
    input wire logic i_valid_from_partner, //! valid signal from partner
    input wire T i_data_from_partner, //! data from partner
    output wire logic o_ready_to_partner //! ready signal to partner
    //! @end
);
// ---------- parameters ----------
// --------------------

// ---------- parameter validation ----------
// --------------------

// ---------- internal signal and storage ----------
//! FIFO read and write pointer type
typedef struct packed {
    logic idx; //! buffer index
    logic phase; //! The buffer phase. Begins at 0 and toggles between 0 and 1 every time the index wraps around. This is utilized for distinguishing between full and empty conditions.
} buf_ptr_t;

var T r_fifo_buf[2]; //! FIFO buffer
var buf_ptr_t r_rd_ptr; //! FIFO read pointer
var buf_ptr_t r_wr_ptr; //! FIFO write pointer

wire g_buf_full; //! buffer full signal
assign g_buf_full = r_rd_ptr.idx == r_wr_ptr.idx && r_rd_ptr.phase != r_wr_ptr.phase;
wire g_buf_empty; //! buffer empty signal
assign g_buf_empty = r_rd_ptr.idx == r_wr_ptr.idx && r_rd_ptr.phase == r_wr_ptr.phase;

wire g_push_en; //! push enable signal
assign g_push_en = i_valid_from_partner && !g_buf_full;
wire g_pop_en; //! pop enable signal
assign g_pop_en = i_ready_from_core && !g_buf_empty;

var T g_nxt_fifo_buf[2]; //! the value of `r_fifo_buf` right after the next clock rising edge
var buf_ptr_t g_nxt_rd_ptr; //! the value of `r_rd_ptr` right after the next clock rising edge
var buf_ptr_t g_nxt_wr_ptr; //! the value of `r_wr_ptr` right after the next clock rising edge

var logic r_out_ready_to_partner; //! output register for `o_ready_to_partner`
// --------------------

// ---------- Drive output signals. ----------
assign o_core_valid = !g_buf_empty;
assign o_core_data = r_fifo_buf[r_rd_ptr.idx];
assign o_ready_to_partner = r_out_ready_to_partner;
// --------------------

// ---------- blocks ----------
//! Determine the next value of FIFO read pointer.
always_comb begin: blk_det_nxt_rd_ptr
    if (i_sync_rst) begin
        g_nxt_rd_ptr = '{default:'0};
    end else if (g_pop_en) begin
        g_nxt_rd_ptr.idx = ~r_rd_ptr.idx;
        g_nxt_rd_ptr.phase = r_rd_ptr.idx ? ~r_rd_ptr.phase : r_rd_ptr.phase;
    end else begin
        g_nxt_rd_ptr = r_rd_ptr;
    end
end

//! Update FIFO read pointer.
always_ff @(posedge i_clk) begin: blk_update_rd_ptr
    r_rd_ptr <= g_nxt_rd_ptr;
end

//! Determine the next value of FIFO write pointer.
always_comb begin: blk_det_nxt_wr_ptr
    if (i_sync_rst) begin
        g_nxt_wr_ptr = '{default:'0};
    end else if (g_push_en) begin
        g_nxt_wr_ptr.idx = ~r_wr_ptr.idx;
        g_nxt_wr_ptr.phase = r_wr_ptr.idx ? ~r_wr_ptr.phase : r_wr_ptr.phase;
    end else begin
        g_nxt_wr_ptr = r_wr_ptr;
    end
end

//! Update FIFO write pointer.
always_ff @(posedge i_clk) begin: blk_update_wr_ptr
    r_wr_ptr <= g_nxt_wr_ptr;
end

//! Determine the next value of FIFO buffer.
always_comb begin: blk_det_nxt_fifo_buf
    g_nxt_fifo_buf[0] = (g_push_en && !r_wr_ptr.idx) ? i_data_from_partner : r_fifo_buf[0];
    g_nxt_fifo_buf[1] = (g_push_en && r_wr_ptr.idx) ? i_data_from_partner : r_fifo_buf[1];
end

//! Update FIFO buffer.
always_ff @(posedge i_clk) begin: blk_update_fifo_buf
    r_fifo_buf <= g_nxt_fifo_buf;
end

//! Update the output register for ready signal to partner.
always_ff @(posedge i_clk) begin: blk_update_fifo_buf
    r_out_ready_to_partner <= !(g_nxt_wr_ptr.idx == g_nxt_rd_ptr.idx && g_nxt_wr_ptr.phase != g_nxt_rd_ptr.phase);
end
// --------------------
endmodule

`default_nettype wire
