// Verible directive
// verilog_lint: waive-start parameter-name-style
// verilog_lint: waive-start line-length

`ifndef POW2_BST_CHG_RING_BUF_V0_1_0_SV_INCLUDED
`define POW2_BST_CHG_RING_BUF_V0_1_0_SV_INCLUDED

`default_nettype none

//! A ring buffer with power-of-two capacity and burst-charging.
//!
//! This module receives **exactly** ```2**EXP_CHG``` elements from the upstream side at one clock cycle, and discharges **up to** ```2**EXP_CHG``` elements at one clock cycle.
//! There is **no handshake** function, so a parent module must handle the flow control.
module pow2_bst_chg_ring_buf_v0_1_1 #(
    parameter bit BE_UNSAFE = 1'b0, //! Enable unsafe configuration, which disables most of costly invalid-value sanitizing, improving place&route feasibility.
    parameter int unsigned EXP_BUF = 7, //! Buffer size exponent, must be in range [1,31]. The buffer size is ```2**EXP_BUF```.
    parameter int unsigned EXP_CHG = 6, //! Charging burst size exponent, must be in range [1,```EXP_BUF```). The charging burst size is ```2**EXP_CHG```.
    `ifndef COMPILER_MATURITY_LEVEL_0 // This macro should be set MANUALLY in the project settings if needed.
        parameter type T_ELEM = logic [7:0] //! element data type
    `else
        parameter int unsigned BW_ELEM = 8 //! element data bit width (>=1)
    `endif
)(
    //! @virtualbus cont_if @dir in control interface
    //! input clock
    input wire logic i_clk,
    input wire logic i_sync_rst, //! input reset signal synchronous to the input clock
    input wire logic i_freeze, //! Freeze directive, which stops all state transitions except for the reset. this signal can be used to flow control by the parent module.
    input wire logic [EXP_BUF:0] i_n_init_zero_elems, //! number of the initial ```'0``` data elements in the buffer, **clipped** to the range [0,```2**EXP_BUF```]
    //! @end
    //! @virtualbus us_side_if @dir in upstream-side interface
    //! number of free slots in the buffer
    output wire logic [EXP_BUF:0] o_cnt_free,
    output wire logic o_c_ready, //! Ready signal indicating that the charging elements (described below) can be accepted. An equation ```o_c_ready = (o_cnt_free >= 2**EXP_CHG)``` holds.
    input wire logic i_c_valid, //! valid signal indicating that the charging elements (described below) are valid
    `ifndef COMPILER_MATURITY_LEVEL_0
        input wire T_ELEM [2**EXP_CHG-1:0] i_c_elems, //! charging elements
    `else
        input wire logic [2**EXP_CHG-1:0][BW_ELEM-1:0] i_c_elems, //! charging elements
    `endif
    //! @end
    //! @virtualbus ds_side_if @dir out downstream-side interface
    //! number of elements in the buffer
    output wire logic [EXP_BUF:0] o_cnt,
    `ifndef COMPILER_MATURITY_LEVEL_0
        output wire T_ELEM [2**EXP_BUF-1:0] o_mrr_buf, //! Mirrored internal buffer which is virtually rotated so that the head element comes to the index 0. Only first ```o_cnt``` elements are valid.
    `else
        output wire logic [2**EXP_BUF-1:0][BW_ELEM-1:0] o_mrr_buf, //! Mirrored internal buffer which is virtually rotated so that the head element comes to the index 0. Only first ```o_cnt``` elements are valid.
    `endif
    input wire logic [EXP_CHG:0] i_n_dc //! Number of discharging elements. At the next clock rising-edge, ```i_n_dc``` elements are removed from the buffer. Under safe configuration, ```i_n_dc``` is **clipped** to the range [0,```o_cnt```]. Under unsafe configuration, this **MUST NOT** be greater than ```o_cnt```, otherwise **UNDEFINED** behavior will occur.
    //! @end
);
// ---------- imports ----------
// --------------------

// ---------- parameters ----------
localparam int unsigned BUF_CAPACITY = 2**EXP_BUF; //! buffer capacity
localparam int unsigned CHG_BST_SIZE = 2**EXP_CHG; //! charging burst size
localparam int unsigned BW_BUF_CNT = EXP_BUF+1; //! bit width of the buffer element count
localparam int unsigned BW_BUF_IDX = EXP_BUF; //! bit width of the buffer index
// --------------------

// ---------- parameter validation ----------
generate
    if (EXP_BUF < 1) begin: gen_too_small_EXP_BUF
        nonexistent_module_to_throw_a_custom_error_message_for too_small_EXP_BUF();
    end
    if (EXP_BUF > 31) begin: gen_too_large_EXP_BUF
        nonexistent_module_to_throw_a_custom_error_message_for too_large_EXP_BUF();
    end
    if (EXP_CHG < 1) begin: gen_too_small_EXP_CHG
        nonexistent_module_to_throw_a_custom_error_message_for too_small_EXP_CHG();
    end
    if (EXP_CHG >= EXP_BUF) begin: gen_too_large_EXP_CHG
        nonexistent_module_to_throw_a_custom_error_message_for too_large_EXP_CHG();
    end
    `ifdef COMPILER_MATURITY_LEVEL_0
        if (BW_ELEM < 1) begin: gen_too_small_BW_ELEM
            nonexistent_module_to_throw_a_custom_error_message_for too_small_BW_ELEM();
        end
    `endif
endgenerate
// --------------------

// ---------- brief sketch ----------
// --------------------

// ---------- functions ----------
// --------------------

// ---------- signals and storage ----------
var logic r_init_rst_done = 1'b0; //! initial reset done flag (only for simulation)

`ifdef COMPILER_MATURITY_LEVEL_0
    typedef logic [BW_ELEM-1:0] T_ELEM; //! element data type
`endif

var T_ELEM [BUF_CAPACITY-1:0] r_buf; //! internal buffer, element-slots
var logic [BW_BUF_IDX-1:0] r_head_idx; //! head index of the buffer
var logic [BW_BUF_IDX-1:0] r_tail_idx; //! tail index of the buffer
var logic [BW_BUF_CNT-1:0] r_cnt; //! number of elements in the buffer
var logic [BW_BUF_CNT-1:0] r_cnt_free; //! number of free slots in the buffer

wire [BW_BUF_CNT-1:0] w_snt_n_dc; //! Sanitized version of ```i_n_dc```. Under safe configuration, it is **clipped** to the range [0,```o_cnt```]. Under unsafe configuration, this is merely a pass-through.

generate
    if (BE_UNSAFE) begin: gen_unsafe
        assign w_snt_n_dc = BW_BUF_CNT'(i_n_dc);
    end else begin: gen_safe
        assign w_snt_n_dc = (BW_BUF_CNT'(i_n_dc) > r_cnt) ? r_cnt : BW_BUF_CNT'(i_n_dc);
    end
endgenerate

wire logic g_chg_en = i_c_valid && o_c_ready; //! charging enable signal
// --------------------

// ---------- instances ----------
// --------------------

// ---------- Drives output signals. ----------
assign o_cnt_free = r_cnt_free;
assign o_c_ready = (r_cnt_free >= BW_BUF_CNT'(CHG_BST_SIZE));
assign o_cnt = r_cnt;
genvar i_gen;
generate
    for (i_gen=0; i_gen<BUF_CAPACITY; i_gen++) begin: gen_drv_o_mrr_buf
        assign o_mrr_buf[i_gen] = r_buf[BW_BUF_IDX'(i_gen + r_head_idx)];
    end
endgenerate
// --------------------

// ---------- blocks ----------
//! Updates the number of elements and free slots in the buffer.
always_ff @(posedge i_clk) begin: blk_update_cnt_and_free
    if (i_sync_rst) begin
        localparam logic [BW_BUF_CNT-1:0] BC = BW_BUF_CNT'(BUF_CAPACITY);
        automatic logic [BW_BUF_CNT-1:0] cnt_rst = (i_n_init_zero_elems > BC) ? BC : i_n_init_zero_elems;
        r_cnt <= cnt_rst;
        r_cnt_free <= BC - cnt_rst;
    end else if (!i_freeze) begin
        r_cnt <= r_cnt + (g_chg_en ? BW_BUF_CNT'(CHG_BST_SIZE) : '0) - w_snt_n_dc;
        r_cnt_free <= r_cnt_free + w_snt_n_dc - (g_chg_en ? BW_BUF_CNT'(CHG_BST_SIZE) : '0);
    end
end

//! Updates the head and tail indices.
always_ff @(posedge i_clk) begin: blk_update_idx
    if (i_sync_rst) begin
        r_head_idx <= '0;
        r_tail_idx <= '0;
    end else if (!i_freeze) begin
        r_head_idx <= r_head_idx + BW_BUF_IDX'(w_snt_n_dc);
        r_tail_idx <= r_tail_idx + (g_chg_en ? BW_BUF_IDX'(CHG_BST_SIZE) : '0);
    end
end

//! Updates the buffer.
always_ff @(posedge i_clk) begin: blk_update_buf
    if (i_sync_rst) begin
        r_buf <= '{default:'0};
    end else if (!i_freeze && g_chg_en) begin
        automatic logic [BW_BUF_IDX-1:0] chg_end_idx = r_tail_idx + BW_BUF_IDX'(CHG_BST_SIZE-1);
        for (int unsigned i=0; i<BUF_CAPACITY; ++i) begin
            if (chg_end_idx >= r_tail_idx) begin //! Charged region doesn't wrap around.
                if (BW_BUF_IDX'(i) >= r_tail_idx && BW_BUF_IDX'(i) <= chg_end_idx) begin
                    r_buf[i] <= i_c_elems[BW_BUF_IDX'(i) - BW_BUF_IDX'(r_tail_idx)];
                end
            end else begin //! Charged region wraps around.
                if (BW_BUF_IDX'(i) >= r_tail_idx) begin
                    r_buf[i] <= i_c_elems[BW_BUF_IDX'(i) - BW_BUF_IDX'(r_tail_idx)];
                end else if (BW_BUF_IDX'(i) <= chg_end_idx) begin
                    r_buf[i] <= i_c_elems[BW_BUF_IDX'(i) + BW_BUF_IDX'(BW_BUF_CNT'(BUF_CAPACITY) - BW_BUF_CNT'(r_tail_idx))];
                end
            end
        end
    end
end

//! bug detection (only for simulation)
always_ff @(posedge i_clk) begin: blk_bug_det
    if (i_sync_rst) begin
        r_init_rst_done <= 1'b1;
    end
    if (!BE_UNSAFE && r_init_rst_done) begin
        if (!(r_head_idx + BW_BUF_IDX'(r_cnt) == r_tail_idx)) begin
            $error("BUG: head_idx + cnt != tail_idx");
        end
    end
end
// --------------------
endmodule

`default_nettype wire

`endif // POW2_BST_CHG_RING_BUF_V0_1_0_SV_INCLUDED
