// Verible directives
// verilog_lint: waive-start parameter-name-style
// verilog_lint: waive-start line-length

`default_nettype none

//! Single-clock symmetric FIFO.
//! Some techniques used in this design are base on '[Simulation and Synthesis Techniques for Asynchronous FIFO Design](http://www.sunburst-design.com/papers/CummingsSNUG2002SJ_FIFO1.pdf)'
module sgl_clk_fifo #(
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

// ---------- parameters ----------
localparam int BIT_WIDTH_BUF_PTR = $clog2(DEPTH); //! bit width required for buffer read & write pointers
// --------------------

// ---------- parameter validation ----------
// --------------------

// ---------- internal signal and storage ----------
//! FIFO read and write pointer type
typedef struct packed {
    logic [BIT_WIDTH_BUF_PTR-1:0] idx; //! buffer index
    logic phase; //! The buffer phase. Begins at 0 and toggles between 0 and 1 every time the index wraps around. This is utilized for distinguishing between full and empty conditions.
} buf_ptr_t;

var logic [DEPTH-1:0][DATA_BIT_WIDTH-1:0] r_fifo_buf; //! FIFO buffer
var buf_ptr_t r_rd_ptr; //! FIFO read pointer
var buf_ptr_t r_wr_ptr; //! FIFO write pointer
wire g_pop_en; //! pop enable signal
assign g_pop_en = i_re && !o_empty;
wire g_push_en; //! push enable signal
assign g_push_en = i_we && !o_full;
// --------------------

// ---------- Drive output signals. ----------
assign o_full = i_sync_rst || (r_wr_ptr.idx == r_rd_ptr.idx && r_wr_ptr.phase != r_rd_ptr.phase);
assign o_empty = r_wr_ptr.idx == r_rd_ptr.idx && r_wr_ptr.phase == r_rd_ptr.phase;
assign o_data = r_fifo_buf[r_rd_ptr.idx];
// --------------------

// ---------- blocks ----------
//! Update read pointer.
always_ff @(posedge i_clk) begin: blk_update_rd_ptr
    if (i_sync_rst) begin
        r_rd_ptr <= '{default:'0};
    end else if (g_pop_en) begin
        if (r_rd_ptr.idx == DEPTH-1) begin
            r_rd_ptr.idx <= '0;
            r_rd_ptr.phase <= ~r_rd_ptr.phase;
        end else begin
            r_rd_ptr.idx <= r_rd_ptr.idx + 1;
        end
    end
end

//! Update write pointer.
always_ff @(posedge i_clk) begin: blk_update_wr_ptr
    if (i_sync_rst) begin
        r_wr_ptr <= '{default:'0};
    end else if (g_push_en) begin
        if (r_wr_ptr.idx == DEPTH-1) begin
            r_wr_ptr.idx <= '0;
            r_wr_ptr.phase <= ~r_wr_ptr.phase;
        end else begin
            r_wr_ptr.idx <= r_wr_ptr.idx + 1;
        end
    end
end

//! Update FIFO data storage.
always_ff @(posedge i_clk) begin: blk_update_fifo_buf
    if (i_sync_rst) begin
        ; // r_fifo_buf <= '{default:'0}; // Costly. Don't worry about exposing garbage data to the downstream because there is an empty flag.
    end else if (g_push_en) begin
        r_fifo_buf[r_wr_ptr.idx] <= i_data;
    end
end
// --------------------
endmodule

`default_nettype wire
