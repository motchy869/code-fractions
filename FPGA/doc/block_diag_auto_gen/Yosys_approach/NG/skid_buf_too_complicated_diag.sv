// Verible directives
// verilog_lint: waive-start parameter-name-style
// verilog_lint: waive-start line-length

`default_nettype none

module skid_buf_too_complicated_diag #(
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

// ---------- internal signal and storage ----------
// FIFO read and write pointer type
typedef struct packed {
    logic idx; //! buffer index
    logic phase; //! The buffer phase. Begins at 0 and toggles between 0 and 1 every time the index wraps around. This is utilized for distinguishing between full and empty conditions.
} buf_ptr_t;

var logic [1:0][BIT_WIDTH_DATA-1:0] r_fifo_buf; //! FIFO buffer
var buf_ptr_t r_rd_ptr; //! FIFO read pointer
var buf_ptr_t r_wr_ptr; //! FIFO write pointer
wire g_buf_full; //! buffer full signal
assign g_buf_full = r_rd_ptr.idx == r_wr_ptr.idx && r_rd_ptr.phase != r_wr_ptr.phase;
wire g_buf_empty; //! buffer empty signal
assign g_buf_empty = r_rd_ptr.idx == r_wr_ptr.idx && r_rd_ptr.phase == r_wr_ptr.phase;
wire g_push_en; //! push enable signal
assign g_push_en = i_us_valid && o_us_ready;
wire g_pop_en; //! pop enable signal
assign g_pop_en = o_ds_valid && i_ds_ready;
// --------------------

// ---------- Drives output signals. ----------
assign o_us_ready = i_sync_rst ? 1'b0 : !g_buf_full;
assign o_ds_valid = !g_buf_empty;
assign o_ds_data = r_fifo_buf[r_rd_ptr.idx];
// --------------------

// ---------- blocks ----------
//! Updates write pointer.
always_ff @(posedge i_clk) begin: blk_update_wr_ptr
    if (i_sync_rst) begin
        r_wr_ptr <= '0;
    end else if (g_push_en) begin
        r_wr_ptr.idx <= ~r_wr_ptr.idx;
        if (r_wr_ptr.idx) begin
            r_wr_ptr.phase <= ~r_wr_ptr.phase;
        end
    end
end

//! Updates read pointer.
always_ff @(posedge i_clk) begin: blk_update_rd_ptr
    if (i_sync_rst) begin
        r_rd_ptr <= '0;
    end else if (g_pop_en) begin
        r_rd_ptr.idx <= ~r_rd_ptr.idx;
        if (r_rd_ptr.idx) begin
            r_rd_ptr.phase <= ~r_rd_ptr.phase;
        end
    end
end

//! Updates FIFO data storage.
always_ff @(posedge i_clk) begin: blk_update_fifo_buf
    if (i_sync_rst) begin
        r_fifo_buf <= '0;
    end else if (g_push_en) begin
        r_fifo_buf[r_wr_ptr.idx] <= i_us_data;
    end
end
// --------------------
endmodule

`default_nettype wire
