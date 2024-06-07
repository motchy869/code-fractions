// Verible directive
// verilog_lint: waive-start parameter-name-style
// verilog_lint: waive-start line-length

`default_nettype none

//! Receives data fragments from upstream and stores them in a buffer to construct data chunks.
//! When the downstream is ready and there is a chunk in the buffer, it sends the chunk to the downstream.
module frag_to_chunk#(
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
    output wire logic o_chunk_valid, //! output valid signal which indicates that the output chunk is valid
    output wire T o_chunk[S_OUT] //! output chunk
    //! @end
);

//! parameter validation
generate
    if (S_MAX_IN < 1) begin: gen_input_fragment_size_param_validation
        $error("S_MAX_IN must be greater than or equal to 1");
        nonexistent_module_to_throw_a_custom_error_message_for invalid_parameters();
    end

    if (S_OUT < 1) begin: gen_output_chunk_size_param_validation
        $error("S_OUT must be greater than or equal to 1");
        nonexistent_module_to_throw_a_custom_error_message_for invalid_parameters();
    end
endgenerate

// ---------- local parameters ----------
localparam int BIT_WIDTH__S_OUT = $clog2(S_OUT + 1); //! bit width required to represent `S_OUT`

//! The capacity (unit is **element**) of the fragment buffer.
//! This size should be greater than or equal to 2 x max(`S_MAX_IN`, `S_OUT`), otherwise deadlock may occur.
//!
//! In this module, `FRAG_BUF_CAP` is set to `S_OUT` x ceil(2 x max(`S_MAX_IN`, `S_OUT`)/S_OUT).
localparam int FRAG_BUF_CAP = S_OUT*((2*((S_MAX_IN <= S_OUT) ? S_OUT : S_MAX_IN) + S_OUT - 1)/S_OUT);
localparam int BIT_WIDTH__FRAG_BUF_CAP = $clog2(FRAG_BUF_CAP + 1); // bit width required to represent `FRAG_BUF_CAP`
localparam int NUM_FRAG_BUF_READ_PAGES = FRAG_BUF_CAP/S_OUT; //! the number of the read-pages in the fragment buffer
localparam int BIT_WIDTH__NUM_FRAG_BUF_READ_PAGES = $clog2(NUM_FRAG_BUF_READ_PAGES + 1); //! bit width required to represent `NUM_FRAG_BUF_READ_PAGES`
// --------------------

// ---------- functions ----------
//! Calculate the number of the padding elements described in the specification of `i_pad_tail`.
function automatic logic [BIT_WIDTH__S_OUT-1:0] f_calcNumPadElem(
    input logic pad_tail, // mirror of `i_pad_tail`
    input logic frag_push_en, // mirror of `r_frag_push_en`
    input logic [BIT_WIDTH__S_MAX_IN-1:0] frag_size, // mirror of `i_frag_size`
    input logic [BIT_WIDTH__FRAG_BUF_CAP-1:0] buf_elem_cnt // mirror of `r_buf_elem_cnt`
);
    logic [BIT_WIDTH__FRAG_BUF_CAP-1:0] modulo_a = (buf_elem_cnt + BIT_WIDTH__FRAG_BUF_CAP'(frag_size)) % BIT_WIDTH__FRAG_BUF_CAP'(S_OUT);
    logic [BIT_WIDTH__FRAG_BUF_CAP-1:0] modulo_b = buf_elem_cnt % BIT_WIDTH__FRAG_BUF_CAP'(S_OUT);

    if (pad_tail == 1'b0) begin
        return '0;
    end

    if (frag_push_en) begin
        if (modulo_a == '0) begin
            return '0;
        end
        return BIT_WIDTH__S_OUT'(S_OUT) - BIT_WIDTH__S_OUT'(modulo_a);
    end else begin
        if (modulo_b == '0) begin
            return '0;
        end
        return BIT_WIDTH__S_OUT'(S_OUT) - BIT_WIDTH__S_OUT'(modulo_b);
    end
endfunction
// --------------------

// ---------- internal signals and storage ----------
`ifdef UNDER_SIMULATION
    var logic r_init_rst_done = 1'b0; //! (simulation only) Begins at 0. Turns to 1 after initial reset.
`endif

wire logic g_frag_size_good; //! Indicates that the input fragment size is good.
assign g_frag_size_good = i_frag_size <= BIT_WIDTH__S_MAX_IN'(S_MAX_IN);

var T r_frag_buf[FRAG_BUF_CAP]; //! buffer to store fragments, 2-page buffer
var logic [BIT_WIDTH__FRAG_BUF_CAP-1:0] r_buf_elem_cnt; //! count of the elements in the fragment buffer
var logic [BIT_WIDTH__FRAG_BUF_CAP-1:0] r_elem_write_ptr; //! The write-pointer of the fragment buffer (unit is **element**).
var logic [BIT_WIDTH__NUM_FRAG_BUF_READ_PAGES-1:0] r_page_read_ptr; //! The read-pointer of the fragment buffer(unit is **page**).
wire logic g_frag_push_en; //! enable signal to push a fragment into the fragment buffer
assign g_frag_push_en = i_frag_valid && o_next_frag_ready;
wire logic [BIT_WIDTH__S_OUT-1:0] g_num_pad_elem; //! the number of the padding elements described in the specification of `i_pad_tail`.
assign g_num_pad_elem = f_calcNumPadElem(i_pad_tail, g_frag_push_en, i_frag_size, r_buf_elem_cnt);
wire logic g_chunk_pop_en; //! enable signal to pop a chunk from the fragment buffer
assign g_chunk_pop_en = i_ds_ready && o_chunk_valid;
wire logic [BIT_WIDTH__FRAG_BUF_CAP-1:0] g_delta_elem_write_ptr; //! the increment of `r_elem_write_ptr`
assign g_delta_elem_write_ptr = (g_frag_push_en ? BIT_WIDTH__FRAG_BUF_CAP'(i_frag_size) : '0) + BIT_WIDTH__FRAG_BUF_CAP'(g_num_pad_elem);
// --------------------

// ---------- Drive output signals. ----------
assign o_next_frag_ready = !i_sync_rst && g_frag_size_good && (g_chunk_pop_en ? r_buf_elem_cnt - BIT_WIDTH__FRAG_BUF_CAP'(S_OUT) : r_buf_elem_cnt) + i_frag_size <= BIT_WIDTH__FRAG_BUF_CAP'(FRAG_BUF_CAP);
assign o_chunk_valid = r_buf_elem_cnt >= BIT_WIDTH__FRAG_BUF_CAP'(S_OUT);
assign o_chunk = r_frag_buf[BIT_WIDTH__FRAG_BUF_CAP'(r_page_read_ptr)*BIT_WIDTH__FRAG_BUF_CAP'(S_OUT)+:S_OUT];
// --------------------

// ---------- processes ----------
`define ASST_VAL_IS_KNOWN(val) `ifdef UNDER_SIMULATION\
    assert(!r_init_rst_done || !$isunknown(val)) else begin $display("file: %s, line: %d", `__FILE__, `__LINE__); $fatal(2, "unknown value"); end\
    `endif
`define ASST_VAL_IN_RANGE(cond) `ifdef UNDER_SIMULATION\
    assert(!r_init_rst_done || cond) else begin $display("file: %s, line: %d", `__FILE__, `__LINE__); $fatal(2, "value out of range"); end\
    `endif

`ifdef UNDER_SIMULATION
    //! Record the initial reset event.
    always_ff @(posedge i_clk) begin: blk_rcd_init_rst_evt
        if (i_sync_rst) begin
            r_init_rst_done <= 1'b1;
        end
    end
`endif

//! Update the fragment buffer elements count.
always_ff @(posedge i_clk) begin: blk_update_buf_elem_cnt
    if (i_sync_rst) begin
        r_buf_elem_cnt <= '0;
    end else begin
        r_buf_elem_cnt <= r_buf_elem_cnt + (g_frag_push_en ? BIT_WIDTH__FRAG_BUF_CAP'(i_frag_size) : '0) + BIT_WIDTH__FRAG_BUF_CAP'(g_num_pad_elem) - (g_chunk_pop_en ? BIT_WIDTH__FRAG_BUF_CAP'(S_OUT) : '0);
        `ASST_VAL_IN_RANGE(r_buf_elem_cnt <= FRAG_BUF_CAP)
    end
end

//! Update the page read-pointer.
always_ff @(posedge i_clk) begin: blk_update_page_read_ptr
    if (i_sync_rst) begin
        r_page_read_ptr <= '0;
    end else if (g_chunk_pop_en) begin
        if (r_page_read_ptr == BIT_WIDTH__NUM_FRAG_BUF_READ_PAGES'(NUM_FRAG_BUF_READ_PAGES - int'(1))) begin
            r_page_read_ptr <= '0;
        end else begin
            r_page_read_ptr <= r_page_read_ptr + BIT_WIDTH__NUM_FRAG_BUF_READ_PAGES'(1);
        end
    end
    `ASST_VAL_IN_RANGE(r_page_read_ptr <= NUM_FRAG_BUF_READ_PAGES)
end

//! Update the elem write-pointer.
always_ff @(posedge i_clk) begin: blk_update_elem_write_ptr
    if (i_sync_rst) begin
        r_elem_write_ptr <= '0;
    end else begin
        if (BIT_WIDTH__FRAG_BUF_CAP'(FRAG_BUF_CAP) - r_elem_write_ptr > g_delta_elem_write_ptr) begin
            r_elem_write_ptr <= r_elem_write_ptr + g_delta_elem_write_ptr;
        end else begin
            r_elem_write_ptr <= g_delta_elem_write_ptr - (BIT_WIDTH__FRAG_BUF_CAP'(FRAG_BUF_CAP) - r_elem_write_ptr);
        end
    end
    `ASST_VAL_IN_RANGE(r_elem_write_ptr < FRAG_BUF_CAP)
end

//! Update the fragment buffer.
always_ff @(posedge i_clk) begin: blk_update_frag_buf
    if (i_sync_rst) begin
        // r_frag_buf <= '{default:0}; // Costly. This is not mandatory because there is `o_chunk_valid`.
    end else begin
        localparam int MAX_DELTA = S_MAX_IN + S_OUT- 1;
        `ifdef UNDEFINED // hard to synthesize, leads to SIGSEGV in Vivado Simulator
            for (bit [BIT_WIDTH__FRAG_BUF_CAP-1:0] i = '0; i < BIT_WIDTH__FRAG_BUF_CAP'(MAX_DELTA); ++i) begin
                if (i < g_delta_elem_write_ptr) begin
                    automatic logic [BIT_WIDTH__FRAG_BUF_CAP-1:0] g_current_write_ptr = (BIT_WIDTH__FRAG_BUF_CAP'(FRAG_BUF_CAP) - r_elem_write_ptr > i) ? r_elem_write_ptr + i : i - (BIT_WIDTH__FRAG_BUF_CAP'(FRAG_BUF_CAP) - r_elem_write_ptr);
                    r_frag_buf[g_current_write_ptr] <= (g_frag_push_en && i < BIT_WIDTH__FRAG_BUF_CAP'(i_frag_size)) ? i_frag[i] : '{default:'0};
                end
            end
        `else
            localparam int BIT_WIDTH__REL_IDX = BIT_WIDTH__FRAG_BUF_CAP + 1;
            for (int i=0; i<FRAG_BUF_CAP; ++i) begin
                automatic logic [BIT_WIDTH__REL_IDX-1:0] rel_idx = BIT_WIDTH__REL_IDX'(i) + ((BIT_WIDTH__REL_IDX'(i) >= BIT_WIDTH__REL_IDX'(r_elem_write_ptr)) ? '0 : BIT_WIDTH__REL_IDX'(FRAG_BUF_CAP)) - BIT_WIDTH__REL_IDX'(r_elem_write_ptr);
                if (rel_idx < BIT_WIDTH__REL_IDX'(i_frag_size)) begin
                    `ASST_VAL_IS_KNOWN(i_frag[rel_idx])
                    r_frag_buf[i] <= i_frag[rel_idx];
                end else if (rel_idx < BIT_WIDTH__REL_IDX'(g_delta_elem_write_ptr)) begin
                    r_frag_buf[i] <= '{default:'0};
                end
            end
        `endif
    end
end
// --------------------

endmodule

`default_nettype wire
