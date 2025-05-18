// Verible directive
// verilog_lint: waive-start parameter-name-style
// verilog_lint: waive-start line-length

`ifndef MIMO_FIFO_V0_1_0_SV_INCLUDED
`define MIMO_FIFO_V0_1_0_SV_INCLUDED

`default_nettype none

//! A MIMO (multiple-input multiple-output) FIFO with FWFT (first-word fall-through).
//!
//! This module receives elements from the upstream side up to ```MAX_N_I``` elements at one clock cycle, and sends the elements to the downstream side up to ```MAX_N_O``` elements at one clock cycle.
//! The internal storage capacity is ```2*max(MAX_N_I, MAX_N_O)``` elements.
module mimo_fifo_v0_1_0 #(
    parameter int unsigned MAX_N_I = 8, //! maximal instantaneous number of input elements (>0)
    parameter int unsigned MAX_N_O = 8, //! maximal instantaneous number of output elements (>0)
    `ifndef COMPILER_MATURITY_LEVEL_0 // This macro should be set MANUALLY in the project settings if needed.
        parameter type T_E = logic [7:0] //! element data type
    `else
        parameter int unsigned BW_ELEM = 8 //! element data bit width
    `endif
)(
    //! @virtualbus cont_if @dir in control interface
    input wire logic i_clk, //! input clock
    input wire logic i_sync_rst, //! input reset signal synchronous to the input clock
    input wire logic i_freeze, //! freeze directive, which stops all state transitions except for the reset
    //! @end
    //! @virtualbus us_side_if @dir in upstream side interface
    //! Full-signal to upstream side. This signal is asserted when and only when: ```i_sync_rst``` is high, **or** there are less than ```i_n_i``` free element-slots. Upstream side **MUST NOT** use this signal to control ```i_n_i``` by combinatorial logic. If do so, combinatorial loop will be created.
    output wire logic o_full,
    input wire logic [$clog2(MAX_N_I+1)-1:0] i_n_i, //! Number of input elements. 0 corresponds to write-enable signal is low. This value is **clipped** to ```MAX_N_I```.
    `ifndef COMPILER_MATURITY_LEVEL_0
        input wire T_E [MAX_N_I-1:0] i_elems, //! Input elements from upstream side. Only first ```i_n_i``` elements are valid.
    `else
        input wire logic [MAX_N_I-1:0][BW_ELEM-1:0] i_elems, //! Input elements from upstream side. Only first ```i_n_i``` elements are valid.
    `endif
    //! @end
    //! @virtualbus ds_side_if @dir out downstream side interface
    //! Empty-signal to downstream side. This signal is asserted when and only when: ```i_sync_rst``` is high, **or** there are less than ```i_n_o``` elements. Downstream side **MUST NOT** use this signal to control ```i_n_o``` by combinatorial logic. If do so, combinatorial loop will be created.
    output wire logic o_empty,
    input wire logic [$clog2(MAX_N_O+1)-1:0] i_n_o, //! Number of required elements from downstream side. 0 corresponds to read-enable signal is low. This value is **clipped** to ```MAX_N_O```.
    `ifndef COMPILER_MATURITY_LEVEL_0
        output wire T_E [MAX_N_O-1:0] o_elems //! Output elements to downstream side. Only first ```i_n_o``` elements are valid.
    `else
        output wire logic [MAX_N_O-1:0][BW_ELEM-1:0] o_elems //! Output elements to downstream side. Only first ```i_n_o``` elements are valid.
    `endif
    //! @end
);
// ---------- parameters ----------
localparam int unsigned N_SLTS = 2*((MAX_N_I > MAX_N_I) ? MAX_N_I : MAX_N_O); //! the number of element-slots
// --------------------

// ---------- parameter validation ----------
generate
    if (MAX_N_I < 1) begin: gen_MAX_N_I_lower_bound_validation
        nonexistent_module_to_throw_a_custom_error_message_for_too_small_MAX_N_I inst();
    end
    if (MAX_N_O < 1) begin: gen_MAX_N_O_lower_bound_validation
        nonexistent_module_to_throw_a_custom_error_message_for_too_small_MAX_N_O inst();
    end
endgenerate
// --------------------

// ---------- brief sketch ----------
// --------------------

// ---------- functions ----------
// --------------------

// ---------- signals and storage ----------
`ifdef COMPILER_MATURITY_LEVEL_0
    typedef logic [BW_ELEM-1:0] T_E;
`endif
var T_E [N_SLTS-1:0] r_elem_slts; //! element-slots
var logic [$clog2(N_SLTS+1)-1:0] r_elem_cnt; //! the number of elements in the element-slots
wire [$clog2(N_SLTS+1)-1:0] g_free_elem_slts = $clog2(N_SLTS+1)'(N_SLTS) - r_elem_cnt; //! the number of free element-slots
var logic [MAX_N_O-1:0][$clog2(N_SLTS)-1:0] r_rd_ptrs; //! Read pointers. The i-th element is for the i-th output element.
var logic [MAX_N_I-1:0][$clog2(N_SLTS)-1:0] r_wr_ptrs; //! Write pointers. The i-th element is for the i-th input element

wire [$clog2(MAX_N_I+1)-1:0] g_n_i_clp = (i_n_i > $clog2(MAX_N_I+1)'(MAX_N_I)) ? $clog2(MAX_N_I+1)'(MAX_N_I) : i_n_i; //! the number of input elements, clipped to ```MAX_N_I```
wire [$clog2(MAX_N_O+1)-1:0] g_n_o_clp = (i_n_o > $clog2(MAX_N_O+1)'(MAX_N_O)) ? $clog2(MAX_N_O+1)'(MAX_N_O) : i_n_o; //! the number of output elements, clipped to ```MAX_N_O```

wire g_can_push = $clog2(N_SLTS+1)'(g_n_i_clp) <= g_free_elem_slts; //! indicates that elements can be pushed
wire g_can_pop = $clog2(N_SLTS+1)'(g_n_o_clp) <= r_elem_cnt; //! indicates that elements can be popped
wire g_push_now = (g_n_i_clp > '0) && g_can_push; //! indicates that the elements from upstream side should be pushed now
wire g_pop_now = (g_n_o_clp > '0) && g_can_pop; //! indicates that the elements should be popped now
// --------------------

// ---------- instances ----------
// --------------------

// ---------- Drives output signals. ----------
assign o_full = i_sync_rst || ~g_can_push;
assign o_empty = i_sync_rst || ~g_can_pop;
genvar i_gen;
generate
    for (i_gen=0; i_gen<MAX_N_O; ++i_gen) begin: gen_drv_out_elems
        assign o_elems[i_gen] = r_elem_slts[r_rd_ptrs[i_gen]];
    end
endgenerate
// --------------------

// ---------- blocks ----------
//! Updates `r_elem_slts`.
always_ff @(posedge i_clk) begin: blk_update_elem_slts
    if (i_sync_rst) begin
        r_elem_slts <= '{default:'0};
    end else if (~i_freeze && g_push_now) begin
        automatic logic [$clog2(N_SLTS)-1:0] wr_range_btm_idx = r_wr_ptrs[0];
        automatic logic [$clog2(N_SLTS)-1:0] wr_range_top_idx = r_wr_ptrs[g_n_i_clp-1]; // Note that `g_n_i_clp > 0` here.
        automatic logic range_ptn = wr_range_top_idx >= wr_range_btm_idx;
        for (int unsigned i=0; i<N_SLTS; ++i) begin
            // Note that when `N_SLTS` is power of 2, `$clog2(N_SLTS)'(N_SLTS) == 0`, and conditional branch will be optimized out.
            automatic logic in_range = range_ptn ? (i >= wr_range_btm_idx && i <= wr_range_top_idx) : (i >= wr_range_btm_idx || i <= wr_range_top_idx);
            // verilator lint_off STATICVAR
            localparam int unsigned TEMP_BW = $clog2(N_SLTS) + 1; // +1 is for avoiding overflow warning by compiler, but this overflow is harmless.
            // verilator lint_on STATICVAR
            automatic logic [$clog2(MAX_N_I)-1:0] intra_input_idx = ($clog2(N_SLTS)'(i) >= wr_range_btm_idx) ? $clog2(MAX_N_I)'($clog2(N_SLTS)'(i) - $clog2(N_SLTS)'(wr_range_btm_idx)) : $clog2(MAX_N_I)'($clog2(N_SLTS+1)'(i) + $clog2(N_SLTS+1)'(N_SLTS) - $clog2(N_SLTS+1)'(wr_range_btm_idx));
            if (in_range) begin
                r_elem_slts[i] <= i_elems[intra_input_idx];
            end
        end
    end
end

//! Updates `r_elem_cnt`.
always_ff @(posedge i_clk) begin: blk_update_elem_cnt
    if (i_sync_rst) begin
        r_elem_cnt <= '0;
    end else if (~i_freeze) begin
        automatic logic [$clog2(N_SLTS+1)-1:0] inc = g_push_now ? $clog2(N_SLTS+1)'(g_n_i_clp) : '0;
        automatic logic [$clog2(N_SLTS+1)-1:0] dec = g_pop_now ? $clog2(N_SLTS+1)'(g_n_o_clp) : '0;
        r_elem_cnt <= r_elem_cnt + inc - dec;
    end
end

//! Updates `r_rd_ptrs`.
always_ff @(posedge i_clk) begin: blk_update_rd_ptr
    for (int unsigned i=0; i<MAX_N_O; ++i) begin
        if (i_sync_rst) begin
            r_rd_ptrs[i] <= $clog2(N_SLTS)'(i);
        end else if (~i_freeze && g_pop_now) begin
            // Note that when `N_SLTS` is power of 2, `$clog2(N_SLTS)'(N_SLTS) == 0`, and conditional branch will be optimized out.
            automatic logic ov_flw = (r_rd_ptrs[i] > $clog2(N_SLTS)'(N_SLTS-1) - $clog2(N_SLTS)'(g_n_o_clp));
            r_rd_ptrs[i] <= ov_flw ? r_rd_ptrs[i] + $clog2(N_SLTS)'(g_n_o_clp) - $clog2(N_SLTS)'(N_SLTS) : r_rd_ptrs[i] + $clog2(N_SLTS)'(g_n_o_clp);
        end
    end
end

//! Updates `r_wr_ptrs`.
always_ff @(posedge i_clk) begin: blk_update_wr_ptr
    for (int unsigned i=0; i<MAX_N_I; ++i) begin
        if (i_sync_rst) begin
            r_wr_ptrs[i] <= $clog2(N_SLTS)'(i);
        end else if (~i_freeze && g_push_now) begin
            // Note that when `N_SLTS` is power of 2, `$clog2(N_SLTS)'(N_SLTS) == 0`, and conditional branch will be optimized out.
            automatic logic ov_flw = (r_wr_ptrs[i] > $clog2(N_SLTS)'(N_SLTS-1) - $clog2(N_SLTS)'(g_n_i_clp));
            r_wr_ptrs[i] <= ov_flw ? r_wr_ptrs[i] + $clog2(N_SLTS)'(g_n_i_clp) - $clog2(N_SLTS)'(N_SLTS) : r_wr_ptrs[i] + $clog2(N_SLTS)'(g_n_i_clp);
        end
    end
end
// --------------------
endmodule

`default_nettype wire
`endif // MIMO_FIFO_V0_1_0_SV_INCLUDED
