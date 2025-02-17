// Verible directives
// verilog_lint: waive-start parameter-name-style
// verilog_lint: waive-start line-length

`ifndef SKID_BUF_V0_1_0_INCLUDED
`define SKID_BUF_V0_1_0_INCLUDED

`default_nettype none

//! simple skid buffer which can be used to cut timing arc
//! ## changelog
//! ### [0.1.0] - 2024-12-12
//! - initial release
module skid_buf_v0_1_0 #(
    `ifdef COMPILER_MATURITY_LEVEL_0 // This macro should be set MANUALLY in the project settings if needed.
        parameter int unsigned BIT_WIDTH_ELEM = 8 //! bit width of the element
    `else
        parameter type T_E = logic [7:0] //! element data type
    `endif
)(
    input wire logic i_clk, //! clock signal
    input wire logic i_sync_rst, //! synchronous reset signal
    input wire logic i_freeze, //! freeze directive, which stops all state transitions except for the reset

    //! @virtualbus us_side_if @dir in upstream side interface
    input wire logic i_us_valid, //! valid signal from upstream
    `ifdef COMPILER_MATURITY_LEVEL_0
        input wire logic [BIT_WIDTH_ELEM-1:0] i_us_data, //! data from upstream
    `else
        input wire T_E i_us_data, //! data from upstream
    `endif
    output wire logic o_us_ready, //! A ready signal to upstream. **masked by** `i_sync_rst` (to avoid losing data at transition to reset state).
    //! @end

    //! @virtualbus ds_side_if @dir out downstream side interface
    //! ready signal from downstream
    input wire logic i_ds_ready,
    `ifdef COMPILER_MATURITY_LEVEL_0
        output wire logic [BIT_WIDTH_ELEM-1:0] o_ds_data, //! data to downstream
    `else
        output wire T_E o_ds_data, //! data to downstream
    `endif
    output wire logic o_ds_valid //! valid signal to downstream
    //! @end
);
// ---------- parameters ----------
// --------------------

// ---------- parameter validation ----------
// --------------------

// ---------- internal signal and storage ----------
`ifdef COMPILER_MATURITY_LEVEL_0
    typedef logic [BIT_WIDTH_ELEM-1:0] T_E;
`endif

// FIFO read and write pointer type
typedef struct packed {
    logic idx; //! buffer index
    logic phase; //! The buffer phase. Begins at 0 and toggles between 0 and 1 every time the index wraps around. This is utilized for distinguishing between full and empty conditions.
} buf_ptr_t;

var T_E [1:0] r_fifo_buf; //! FIFO buffer
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
assign o_us_ready = !i_sync_rst && !g_buf_full;
assign o_ds_valid = !g_buf_empty;
assign o_ds_data = r_fifo_buf[r_rd_ptr.idx];
// --------------------

// ---------- blocks ----------
//! Updates write pointer.
always_ff @(posedge i_clk) begin: blk_update_wr_ptr
    if (i_sync_rst) begin
        r_wr_ptr <= '{default:'0};
    end else if (!i_freeze) begin
        if (g_push_en) begin
            r_wr_ptr.idx <= ~r_wr_ptr.idx;
            if (r_wr_ptr.idx) begin
                r_wr_ptr.phase <= ~r_wr_ptr.phase;
            end
        end
    end
end

//! Updates read pointer.
always_ff @(posedge i_clk) begin: blk_update_rd_ptr
    if (i_sync_rst) begin
        r_rd_ptr <= '{default:'0};
    end else if (!i_freeze) begin
        if (g_pop_en) begin
            r_rd_ptr.idx <= ~r_rd_ptr.idx;
            if (r_rd_ptr.idx) begin
                r_rd_ptr.phase <= ~r_rd_ptr.phase;
            end
        end
    end
end

//! Updates FIFO data storage.
always_ff @(posedge i_clk) begin: blk_update_fifo_buf
    if (i_sync_rst) begin
        r_fifo_buf <= '{default:'0};
    end else if (!i_freeze) begin
        if (g_push_en) begin
            r_fifo_buf[r_wr_ptr.idx] <= i_us_data;
        end
    end
end
// --------------------
endmodule

`default_nettype wire
`endif // SKID_BUF_V0_1_0_INCLUDED
