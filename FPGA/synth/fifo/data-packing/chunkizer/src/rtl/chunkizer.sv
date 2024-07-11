// Verible directive
// verilog_lint: waive-start parameter-name-style
// verilog_lint: waive-start line-length

`ifndef CHUNKIZER_DEFINED
`define CHUNKIZER_DEFINED

`default_nettype none

module chunkizer #(
    parameter int unsigned SZ_MAX_IN = 8, //! max size of the input fragment
    parameter int unsigned SZ_OUT = 4, //! Size of the output chunk.
    localparam int unsigned BIT_WIDTH_ELEM = 8, //! bit width of each element in the input fragment (**fixed**, cannot be changed)
    localparam int unsigned BIT_WIDTH__SZ_MAX_IN = $clog2(SZ_MAX_IN+1) //! bit width required to represent ```SZ_MAX_IN```
)(
    input wire logic i_clk, //! input clock
    input wire logic i_sync_rst, //! input reset synchronous to the input clock
    //! @virtualbus us_side_if @dir in upstream side interface
    input wire logic i_frag_valid, //! input valid signal which indicates that the input fragment is valid
    input wire logic [BIT_WIDTH__SZ_MAX_IN-1:0] i_frag_size, //! the size of the input fragment, **clipped** to ```SZ_MAX_IN```
    input wire logic i_flush, //! During this is asserted, if there are more than 0 and less than ```SZ_OUT``` elements, a chunk is output with those elements with the remaining part of that chunk filled with zeros.
    input wire logic [SZ_MAX_IN-1:0][BIT_WIDTH_ELEM-1:0] i_frag, //! input fragment
    output wire logic o_next_frag_ready, //! Output ready signal which indicates that the upstream-side can send the next fragment. **Masked by reset**.
    //! @end
    //! @virtualbus ds_side_if @dir out downstream side interface
    //! input ready signal which indicates that the downstream side is ready to accept a new chunk
    input wire logic i_ds_ready,
    output wire logic o_chunk_valid, //! output valid signal which indicates that the output chunk is valid
    output wire logic [SZ_OUT-1:0][BIT_WIDTH_ELEM-1:0] o_chunk //! output chunk
    //! @end
);
// ---------- parameters ----------
localparam int unsigned FIFO_DEPTH = 16; //! Depth of the each internal fifo. Note that the dead-lock can **NOT** occur because this value > 1.
localparam int unsigned NUM_FIFOS = (SZ_MAX_IN > SZ_OUT) ? SZ_MAX_IN : SZ_OUT; //! the number of the internal fifo

localparam int unsigned BIT_WIDTH_SZ_OUT = $clog2(SZ_OUT + 1); //! bit width sufficient to represent ```SZ_OUT```
localparam int unsigned BIT_WIDTH_NUM_FIFOS = $clog2(NUM_FIFOS + 1); //! bit width sufficient to represent ```NUM_FIFOS```
localparam int unsigned BIT_WIDTH_FIFO_IDX = $clog2(NUM_FIFOS); //! bit width sufficient to represent the FIFO ID.
// --------------------

// ---------- parameter validation ----------
// --------------------

// ---------- functions ----------
//! Performs circular right shift. The length of the input vector is ```NUM_FIFOS```.
function automatic logic [NUM_FIFOS-1:0] f_circ_right_shift__NUM_FIFOS(
    input logic [NUM_FIFOS-1:0] vec, // input vector
    input logic [$clog2(NUM_FIFOS+1)-1:0] s // shift amount, clipped to [0, NUM_FIFOS-1]
);
    localparam int unsigned BIT_WIDTH_S = $clog2(NUM_FIFOS+1);
    localparam int unsigned BIT_WIDTH_IDX = $clog2(NUM_FIFOS);
    automatic logic [BIT_WIDTH_S-1:0] s_clp = (s < BIT_WIDTH_S'(NUM_FIFOS)) ? s : BIT_WIDTH_S'(NUM_FIFOS-1);
    automatic logic [NUM_FIFOS-1:0] result;

    for (int unsigned i=0; i<NUM_FIFOS; i++) begin
        localparam int unsigned BIT_WIDTH_NAIVE_IDX = BIT_WIDTH_IDX+1;
        automatic logic [BIT_WIDTH_NAIVE_IDX-1:0] naive_idx = BIT_WIDTH_NAIVE_IDX'(i) + BIT_WIDTH_NAIVE_IDX'(s_clp);
        if (naive_idx < BIT_WIDTH_NAIVE_IDX'(NUM_FIFOS)) begin
            result[i] = vec[BIT_WIDTH_IDX'(naive_idx)];
        end else begin
            result[i] = vec[BIT_WIDTH_IDX'(naive_idx - BIT_WIDTH_NAIVE_IDX'(NUM_FIFOS))];
        end
    end
    return result;
endfunction

//! Counts the number of hot bits aligned to LSB. The length of the bit vector is ```SZ_OUT```.
function automatic logic [BIT_WIDTH_SZ_OUT-1:0] f_cnt_lsb_aligned_hot_bits__SZ_OUT(input logic [SZ_OUT-1:0] val);
    automatic logic [BIT_WIDTH_SZ_OUT-1:0] cnt = '0;
    if (val == '0) begin
        cnt = '0;
    end else if (val == '1) begin
        cnt = BIT_WIDTH_SZ_OUT'(unsigned'(SZ_OUT));
    end else begin
        for (int unsigned i=0; i<SZ_OUT-1; ++i) begin
            if (val[i] == 1'b1 && val[i+1] == 1'b0) begin
                cnt = BIT_WIDTH_SZ_OUT'(1+i);
            end
        end
    end
    return cnt;
endfunction
// --------------------

// ---------- signals and storage ----------
wire [BIT_WIDTH__SZ_MAX_IN-1:0] g_frag_size_clp; //! clipped input fragment size
assign g_frag_size_clp = (i_frag_size <= BIT_WIDTH__SZ_MAX_IN'(SZ_MAX_IN)) ? i_frag_size : BIT_WIDTH__SZ_MAX_IN'(SZ_MAX_IN);

var logic [BIT_WIDTH_NUM_FIFOS-1:0] r_wr_dst_fifo_base_idx; //! base index of the internal fifo to write the input fragment
var logic [BIT_WIDTH_NUM_FIFOS-1:0] r_rd_src_fifo_base_idx; //! base index of the internal fifo to read the output chunk

typedef struct packed {
    logic [BIT_WIDTH_ELEM-1:0] din;
    logic wr_en;
    logic rd_en;
    logic [BIT_WIDTH_ELEM-1:0] dout;
    logic full;
    logic empty;
} ip_fifo_port_t;

var ip_fifo_port_t [NUM_FIFOS-1:0] g_fifo_ports; //! ports of the internal fifo

var logic [NUM_FIFOS-1:0] g_fifo_in_frag_dst_range; //! bit [i] is 1 if and only if the (```r_wr_dst_fifo_base_idx``` + i)-th fifo is in range of fragment destination.
var logic [NUM_FIFOS-1:0] g_fifo_in_frag_dst_range_and_not_full; //! bit [i] is 1 if and only if the (```r_wr_dst_fifo_base_idx``` + i)-th fifo is in range of fragment destination and is not full.
wire g_there_is_space_to_write_frag; //! Indicates that there is space to write the input fragment.
assign g_there_is_space_to_write_frag = (g_fifo_in_frag_dst_range == g_fifo_in_frag_dst_range_and_not_full);
wire g_frag_push_en; //! Indicates that the input fragment should be pushed to the internal fifo at the next positive edge of the clock.
assign g_frag_push_en = i_frag_valid && g_there_is_space_to_write_frag;

var logic [NUM_FIFOS-1:0] g_fifo_in_chunk_src_range; //! bit [i] is 1 if and only if the (```r_rd_src_fifo_base_idx``` + i)-th fifo is in range of chunk source.
var logic [NUM_FIFOS-1:0] g_fifo_in_chunk_src_range_and_not_empty; //! bit [i] is 1 if and only if the (```r_rd_src_fifo_base_idx``` + i)-th fifo is in range of chunk source and is not empty.
wire g_there_is_complete_chunk; //! Indicates that there is a complete chunk in the internal fifo.
assign g_there_is_complete_chunk = (g_fifo_in_chunk_src_range == g_fifo_in_chunk_src_range_and_not_empty);
wire g_there_is_incomplete_chunk; //! Indicates that there is an incomplete chunk in the internal fifo.
assign g_there_is_incomplete_chunk = g_there_is_complete_chunk && (g_fifo_in_chunk_src_range_and_not_empty != '0);
var logic [BIT_WIDTH_SZ_OUT-1:0] g_curr_chunk_net_sz; //! the number of the **net** (namely, non-padded) elements in the current chunk.
wire g_chunk_pop_en; //! Indicates that the output chunk should be popped from the internal fifo at the next positive edge of the clock.
assign g_chunk_pop_en = o_chunk_valid && i_ds_ready;
var logic [SZ_OUT-1:0][BIT_WIDTH_ELEM-1:0] g_chunk; //! the output chunk
// --------------------

// ---------- instances ----------
generate
    genvar i_gen;
    for (i_gen = 0; i_gen < NUM_FIFOS; ++i_gen) begin: gen_fifos
        ip_fifo fifo ( // See 'ip_fifo.veo' for the port definition of 'ip_fifo'.
            .clk(i_clk),
            .srst(i_sync_rst),
            .din(g_fifo_ports[i_gen].din),
            .wr_en(g_fifo_ports[i_gen].wr_en),
            .rd_en(g_fifo_ports[i_gen].rd_en),
            .dout(g_fifo_ports[i_gen].dout),
            .full(g_fifo_ports[i_gen].full),
            .empty(g_fifo_ports[i_gen].empty)
        );
    end
endgenerate
// --------------------

// ---------- Drive output signals. ----------
assign o_next_frag_ready = !i_sync_rst && g_there_is_space_to_write_frag;
assign o_chunk_valid = g_there_is_complete_chunk || (g_there_is_incomplete_chunk && i_flush);
assign o_chunk = g_chunk;
// --------------------

// ---------- blocks ----------
//! Checks if there is space to write the input fragment.
always_comb begin: blk_chk_space_to_write
    localparam int unsigned BW = BIT_WIDTH_NUM_FIFOS + 1;

    for (int unsigned i = 0; i < NUM_FIFOS; ++i) begin
        automatic logic [BW-1:0] exc_end_of_range = BW'(r_wr_dst_fifo_base_idx) + BW'(g_frag_size_clp); // exclusive end of the range
        if (BW'(i) >= BW'(r_wr_dst_fifo_base_idx)) begin
            g_fifo_in_frag_dst_range[i] = (BW'(i) < exc_end_of_range);
        end else begin
            g_fifo_in_frag_dst_range[i] = (BW'(NUM_FIFOS + i) < exc_end_of_range);
        end
        g_fifo_in_frag_dst_range_and_not_full[i] = g_fifo_in_frag_dst_range[i] && !g_fifo_ports[i].full;
    end
end

//! Controls the write-enable signals of the internal fifos.
always_comb begin: blk_cont_fifo_wr_en
    for (int unsigned i = 0; i < NUM_FIFOS; ++i) begin
        g_fifo_ports[i].wr_en = g_frag_push_en && g_fifo_in_frag_dst_range[i];
    end
end

//! Feeds data to the internal fifos.
always_comb begin: blk_feed_data_to_fifos
    // To avoid too long timing arc, don't use ```g_fifo_in_frag_dst_range```.
    localparam int unsigned BW = BIT_WIDTH_NUM_FIFOS + 1;

    for (int unsigned i = 0; i < NUM_FIFOS; ++i) begin
        automatic logic [BW-1:0] exc_end_of_range = BW'(r_wr_dst_fifo_base_idx) + BW'(g_frag_size_clp); // exclusive end of the range

        if (BW'(i) >= BW'(r_wr_dst_fifo_base_idx)) begin
            if (BW'(i) < exc_end_of_range) begin
                g_fifo_ports[i].din = i_frag[BW'(i) - r_wr_dst_fifo_base_idx];
                assert(BW'(i) - r_wr_dst_fifo_base_idx inside {[0:SZ_MAX_IN-1]}) else $fatal(2, "i: %d, r_wr_dst_fifo_base_idx: %d, BW'(i) - r_wr_dst_fifo_base_idx: %d", i, r_wr_dst_fifo_base_idx, BW'(i) - r_wr_dst_fifo_base_idx);
            end else begin
                g_fifo_ports[i].din = '0;
            end
        end else if (BW'(NUM_FIFOS + i) < exc_end_of_range) begin
            g_fifo_ports[i].din = i_frag[BW'(NUM_FIFOS + i) - r_wr_dst_fifo_base_idx];
            assert(BW'(NUM_FIFOS + i) - r_wr_dst_fifo_base_idx inside {[0:SZ_MAX_IN-1]}) else $fatal(2, "i: %d, r_wr_dst_fifo_base_idx: %d, BW'(NUM_FIFOS + i) - r_wr_dst_fifo_base_idx: %d", i, r_wr_dst_fifo_base_idx, BW'(NUM_FIFOS + i) - r_wr_dst_fifo_base_idx);
        end else begin
            g_fifo_ports[i].din = '0;
        end
    end
end

//! Updates the base index of the internal fifo to write the input fragment.
always_ff @(posedge i_clk) begin: blk_update_wr_dst_fifo_base_idx
    localparam int unsigned BW = BIT_WIDTH_NUM_FIFOS + 1; // Note that ```NUM_FIFOS``` >= ```SZ_MAX_IN```.

    if (i_sync_rst) begin
        r_wr_dst_fifo_base_idx <= '0;
    end else if (g_frag_push_en) begin
        automatic logic [BW-1:0] naive_idx = BW'(r_wr_dst_fifo_base_idx) + BW'(g_frag_size_clp);
        if (naive_idx < BW'(NUM_FIFOS)) begin
            r_wr_dst_fifo_base_idx <= BIT_WIDTH_NUM_FIFOS'(naive_idx);
        end else begin
            r_wr_dst_fifo_base_idx <= BIT_WIDTH_NUM_FIFOS'(naive_idx - BW'(NUM_FIFOS));
        end
    end
end

//! Checks if there is a complete chunk in the internal fifo.
always_comb begin: blk_chk_comp_chunk
    localparam int unsigned BW = BIT_WIDTH_NUM_FIFOS + 1;

    for (int unsigned i = 0; i < NUM_FIFOS; ++i) begin
        automatic logic [BW-1:0] exc_end_of_range = BW'(r_rd_src_fifo_base_idx) + BW'(SZ_OUT); // exclusive end of the range
        if (BW'(i) >= BW'(r_rd_src_fifo_base_idx)) begin
            g_fifo_in_chunk_src_range[i] = (BW'(i) < exc_end_of_range);
        end else begin
            g_fifo_in_chunk_src_range[i] = (BW'(NUM_FIFOS + i) < exc_end_of_range);
        end
        g_fifo_in_chunk_src_range_and_not_empty[i] = g_fifo_in_chunk_src_range[i] && !g_fifo_ports[i].empty;
    end
end

//! Control read-enable signals.
always_comb begin: blk_cont_fifo_rd_en
    for (int unsigned i = 0; i < NUM_FIFOS; ++i) begin
        g_fifo_ports[i].rd_en = g_chunk_pop_en && g_fifo_in_chunk_src_range_and_not_empty[i];
    end
end

//! Calculates the size of the incomplete chunk.
always_comb begin: blk_calc_incomp_chunk_sz
    localparam int unsigned BW = BIT_WIDTH_NUM_FIFOS + 1;
    automatic logic [NUM_FIFOS-1:0] lsb_aligned_ver_of__fifo_in_chunk_src_range_and_not_empty;

    lsb_aligned_ver_of__fifo_in_chunk_src_range_and_not_empty = f_circ_right_shift__NUM_FIFOS(g_fifo_in_chunk_src_range_and_not_empty, BIT_WIDTH_NUM_FIFOS'(r_rd_src_fifo_base_idx));
    g_curr_chunk_net_sz = f_cnt_lsb_aligned_hot_bits__SZ_OUT(SZ_OUT'(lsb_aligned_ver_of__fifo_in_chunk_src_range_and_not_empty));
end

//! Updates the base index of the internal fifo to read the output chunk.
always_ff @(posedge i_clk) begin: blk_update_rd_src_fifo_base_idx
    localparam int unsigned BW = BIT_WIDTH_NUM_FIFOS + 1; // Note that ```NUM_FIFOS``` >= ```SZ_OUT```.

    if (i_sync_rst) begin
        r_rd_src_fifo_base_idx <= '0;
    end else if (g_chunk_pop_en) begin
        automatic logic [BW-1:0] naive_idx = BW'(r_rd_src_fifo_base_idx) + BW'(g_curr_chunk_net_sz);
        if (naive_idx < BW'(NUM_FIFOS)) begin
            r_rd_src_fifo_base_idx <= BIT_WIDTH_NUM_FIFOS'(naive_idx);
        end else begin
            r_rd_src_fifo_base_idx <= BIT_WIDTH_NUM_FIFOS'(naive_idx - BW'(NUM_FIFOS));
        end
    end
end

//! Determines the output chunk.
always_comb begin: blk_det_o_chunk
    localparam int unsigned BW = BIT_WIDTH_NUM_FIFOS + 1;

    for (int unsigned i = 0; i < SZ_OUT; ++i) begin
        if (i < g_curr_chunk_net_sz) begin
            automatic logic [BW-1:0] naive_idx = BW'(r_rd_src_fifo_base_idx) + BW'(i);
            if (naive_idx < BW'(NUM_FIFOS)) begin
                g_chunk[i] = g_fifo_ports[naive_idx].dout;
            end else begin
                g_chunk[i] = g_fifo_ports[naive_idx - BW'(NUM_FIFOS)].dout;
            end
        end else begin
            g_chunk[i] = '0;
        end
    end
end
// --------------------
endmodule

`default_nettype wire

`endif // CHUNKIZER_DEFINED
