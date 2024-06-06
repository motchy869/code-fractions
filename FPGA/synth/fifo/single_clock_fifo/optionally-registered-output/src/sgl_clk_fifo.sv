// Verible directives
// verilog_lint: waive-start parameter-name-style
// verilog_lint: waive-start line-length

`default_nettype none

//! Single-clock symmetric FIFO.
//! The output can be optionally registered.
//! Some techniques used in this design are base on '[Simulation and Synthesis Techniques for Asynchronous FIFO Design](http://www.sunburst-design.com/papers/CummingsSNUG2002SJ_FIFO1.pdf)'
module sgl_clk_fifo #(
    parameter int DATA_BIT_WIDTH = 8, //! data bit width
    parameter int DEPTH = 16, //! FIFO depth
    parameter bit EN_US_OUT_REG = 1'b0, //! enable output register on upstream side
    parameter bit EN_DS_OUT_REG = 1'b0 //! enable output register on downstream side
)(
    input wire logic i_clk, //! clock signal
    input wire logic i_sync_rst, //! synchronous reset signal

    //! @virtualbus us_side_if @dir in upstream side interface
    input wire logic i_we, //! write enable
    input wire logic [DATA_BIT_WIDTH-1:0] i_data, //! input data
    output wire logic o_full, //! full flag
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

wire g_pop_en; //! pop enable signal
assign g_pop_en = i_re && !o_empty;
wire g_push_en; //! push enable signal
assign g_push_en = i_we && !o_full;

var logic [DEPTH-1:0][DATA_BIT_WIDTH-1:0] r_fifo_buf; //! FIFO buffer
var buf_ptr_t r_rd_ptr; //! FIFO read pointer
var buf_ptr_t r_wr_ptr; //! FIFO write pointer

var logic [DEPTH-1:0][DATA_BIT_WIDTH-1:0] g_nxt_fifo_buf; //! the value of `r_fifo_buf` right after the next clock rising edge
var buf_ptr_t g_nxt_rd_ptr; //! the value of `r_rd_ptr` right after the next clock rising edge
var buf_ptr_t g_nxt_wr_ptr; //! the value of `r_wr_ptr` right after the next clock rising edge

var logic r_out_full; //! output register for `o_full`, will be optimized away if `EN_US_OUT_REG` is 0
var logic r_out_empty; //! output register for `o_empty`, will be optimized away if `EN_DS_OUT_REG` is 0
var logic [DATA_BIT_WIDTH-1:0] r_out_data; //! output register for `o_data`, will be optimized away if `EN_DS_OUT_REG` is 0
// --------------------

// ---------- Drive output signals. ----------
assign o_full = EN_US_OUT_REG ? r_out_full : r_wr_ptr.idx == r_rd_ptr.idx && r_wr_ptr.phase != r_rd_ptr.phase;
assign o_empty = EN_DS_OUT_REG ? r_out_empty : r_wr_ptr.idx == r_rd_ptr.idx && r_wr_ptr.phase == r_rd_ptr.phase;
assign o_data = EN_DS_OUT_REG ? r_out_data : r_fifo_buf[r_rd_ptr.idx];
// --------------------

// ---------- blocks ----------
//! Determine the next value of FIFO read pointer.
always_comb begin: blk_det_nxt_rd_ptr
    if (i_sync_rst) begin
        g_nxt_rd_ptr = '{default:'0};
    end else if (g_pop_en) begin
        if (r_rd_ptr.idx == DEPTH-1) begin
            g_nxt_rd_ptr.idx = '0;
            g_nxt_rd_ptr.phase = ~r_rd_ptr.phase;
        end else begin
            g_nxt_rd_ptr.idx = r_rd_ptr.idx + 1;
            g_nxt_rd_ptr.phase = r_rd_ptr.phase;
        end
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
        if (r_wr_ptr.idx == DEPTH-1) begin
            g_nxt_wr_ptr.idx = '0;
            g_nxt_wr_ptr.phase = ~r_wr_ptr.phase;
        end else begin
            g_nxt_wr_ptr.idx = r_wr_ptr.idx + 1;
            g_nxt_wr_ptr.phase = r_wr_ptr.phase;
        end
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
    for (int i=0; i<DEPTH; ++i) begin
        if (g_push_en && r_wr_ptr.idx == i) begin
            g_nxt_fifo_buf[i] = i_data;
        end else begin
            g_nxt_fifo_buf[i] = r_fifo_buf[i];
        end
    end
end

//! Update FIFO buffer.
always_ff @(posedge i_clk) begin: blk_update_fifo_buf
    r_fifo_buf <= g_nxt_fifo_buf;
end

//! Update output registers.
always_ff @(posedge i_clk) begin: blk_update_out_regs
    if (EN_US_OUT_REG) begin
        r_out_full <= g_nxt_wr_ptr.idx == g_nxt_rd_ptr.idx && g_nxt_wr_ptr.phase != g_nxt_rd_ptr.phase;
    end

    if (EN_DS_OUT_REG) begin
        r_out_empty <= g_nxt_wr_ptr.idx == g_nxt_rd_ptr.idx && g_nxt_wr_ptr.phase == g_nxt_rd_ptr.phase;
        r_out_data <= g_nxt_fifo_buf[g_nxt_rd_ptr.idx];
    end
end
// --------------------
endmodule

`default_nettype wire
