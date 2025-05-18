// Verible directive
// verilog_lint: waive-start parameter-name-style
// verilog_lint: waive-start line-length

`ifndef MIMO_DLY_LINE_V0_1_1_SV_INCLUDED
`define MIMO_DLY_LINE_V0_1_1_SV_INCLUDED

`default_nettype none

//! A MIMO (multiple-input multiple-output) delay line.
//! All outputs are **buffered**.
//!
//! This module receives elements from the upstream side up to ```MAX_N_C``` elements at one clock cycle, and discharges up to ```MAX_N_DC``` elements at one clock cycle.
//! There is no handshake feature, so a parent module must handle the flow control.
module mimo_dly_line_v0_1_1 #(
    parameter bit BE_UNSAFE = 1'b0, //! Enable unsafe configuration, which disables most of costly invalid-value sanitizing, improving place&route feasibility.
    parameter int unsigned L = 16, //! delay line length (>0)
    parameter int unsigned MAX_N_C = 4, //! maximal instantaneous number of charging elements, must be in range [1,```L```]
    parameter int unsigned MAX_N_DC = 4, //! maximal instantaneous number of discharging elements, must be in range [1,```L```]
    `ifndef COMPILER_MATURITY_LEVEL_0 // This macro should be set MANUALLY in the project settings if needed.
        parameter type T_E = logic [7:0] //! element data type
    `else
        parameter int unsigned BW_ELEM = 8 //! element data bit width (>=1)
    `endif
)(
    //! @virtualbus cont_if @dir in control interface
    input wire logic i_clk, //! input clock
    input wire logic i_sync_rst, //! input reset signal synchronous to the input clock
    input wire logic i_freeze, //! Freeze directive, which stops all state transitions except for the reset. this signal can be used to flow control by the parent module.
    input wire logic [$clog2(L+1)-1:0] i_n_init_0_elems, //! number of the initial '0 data elements in delay line, **clipped** to the range [0,```L```]
    output wire logic [$clog2(L+1)-1:0] o_cnt, //! current number of elements in the delay line
    output wire logic [$clog2(L+1)-1:0] o_cnt_free, //! number of free slots in the delay line
    input wire logic [$clog2(MAX_N_C+1)-1:0] i_n_c, //! Number of charging elements. At the next clock rising-edge, ```i_n_c``` elements are added to the delay line. **MUST NOT** be greater than ```o_cnt_free```. Under safe configuration, ```i_n_c``` is **clipped** to the range [0,```o_cnt_free```]. Under unsafe configuration, invalid value will cause **UNDEFINED** behavior.
    input wire logic [$clog2(MAX_N_DC+1)-1:0] i_n_dc, //! Number of discharging elements, **MUST NOT** be greater than ```o_cnt```. At the next clock rising-edge, ```i_n_dc``` elements are removed from the delay line. Under safe configuration, ```i_n_dc``` is **clipped** to the range [0,```o_cnt```]. Under unsafe configuration, invalid value will cause **UNDEFINED** behavior.
    //! @end
    //! @virtualbus data_in_if @dir in data input interface
    `ifndef COMPILER_MATURITY_LEVEL_0
        //! Charging elements. First ```i_n_c``` elements are assumed to be valid.
        input wire T_E [MAX_N_C-1:0] i_c_elems,
    `else
        //! Charging elements. First ```i_n_c``` elements are assumed to be valid.
        input wire logic [MAX_N_C-1:0][BW_ELEM-1:0] i_c_elems,
    `endif
    //! @end
    //! @virtualbus data_out_if @dir out data output interface
    `ifndef COMPILER_MATURITY_LEVEL_0
        //! Delay line. Only first ```o_cnt``` elements are valid.
        output wire T_E [L-1:0] o_line
    `else
        //! Delay line. Only first ```o_cnt``` elements are valid.
        output wire logic [L-1:0][BW_ELEM-1:0] o_line
    `endif
    //! @end
);
// ---------- imports ----------
// --------------------

// ---------- parameters ----------
// --------------------

// ---------- parameter validation ----------
generate
    if (L < 1) begin: gen_L_lower_bound_validation
        nonexistent_module_to_throw_a_custom_error_message_for_too_small_L inst();
    end
    if (MAX_N_C > L) begin: gen_MAX_N_C_upper_bound_validation
        nonexistent_module_to_throw_a_custom_error_message_for_too_large_MAX_N_C inst();
    end
    if (MAX_N_DC > L) begin: gen_MAX_N_DC_upper_bound_validation
        nonexistent_module_to_throw_a_custom_error_message_for_too_large_MAX_N_DC inst();
    end
    `ifdef COMPILER_MATURITY_LEVEL_0
        if (BW_ELEM < 1) begin: gen_too_small_BW_ELEM
            nonexistent_module_to_throw_a_custom_error_message_for_too_small_BW_ELEM inst();
        end
    `endif
endgenerate
// --------------------

// ---------- brief sketch ----------
// --------------------

// ---------- functions ----------
// --------------------

// ---------- signals and storage ----------
`ifdef COMPILER_MATURITY_LEVEL_0
    typedef logic [BW_ELEM-1:0] T_E; //! element data type
`endif

var T_E [L-1:0] r_line; //! line buffer, element-slots
var logic [$clog2(L+1)-1:0] r_cnt; //! number of elements in the delay line
var logic [$clog2(L+1)-1:0] r_cnt_free; //! number of free slots in the delay line

wire [$clog2(MAX_N_C+1)-1:0] w_snt_n_c; //! Sanitized version of ```i_n_c```. Under safe configuration, it is **clipped** to the range [0,```o_cnt_free```]. Under unsafe configuration, this is merely a pass-through.
wire [$clog2(MAX_N_DC+1)-1:0] w_snt_n_dc; //! Sanitized version of ```i_n_dc```. Under safe configuration, it is **clipped** to the range [0,```o_cnt```]. Under unsafe configuration, this is merely a pass-through.

generate
    if (BE_UNSAFE) begin: gen_unsafe
        assign w_snt_n_c = i_n_c;
        assign w_snt_n_dc = i_n_dc;
    end else begin: gen_safe
        assign w_snt_n_c = ($clog2(L+1)'(i_n_c) > r_cnt_free) ? $clog2(MAX_N_C+1)'(r_cnt_free) : i_n_c;
        assign w_snt_n_dc = ($clog2(L+1)'(i_n_dc) > r_cnt) ? $clog2(MAX_N_DC+1)'(r_cnt) : i_n_dc;
    end
endgenerate
// --------------------

// ---------- instances ----------
// --------------------

// ---------- Drives output signals. ----------
assign o_cnt = r_cnt;
assign o_cnt_free = r_cnt_free;
assign o_line = r_line;
// --------------------

// ---------- blocks ----------
//! Updates the number of elements and free slots in the delay line.
always_ff @(posedge i_clk) begin: blk_update_cnt_and_free
    if (i_sync_rst) begin
        automatic logic [$clog2(L+1)-1:0] cnt_rst = (i_n_init_0_elems > $clog2(L+1)'(L)) ? $clog2(L+1)'(L) : i_n_init_0_elems;
        r_cnt <= cnt_rst;
        r_cnt_free <= $clog2(L+1)'(L) - cnt_rst;
    end else if (!i_freeze) begin
        // if (!BE_UNSAFE) begin // just for debug
        //     if (w_snt_n_c != i_n_c) begin
        //         $fatal(2, "[time=%0t] value mismatch, w_snt_n_c: %0d, i_n_c: %0d", $realtime, w_snt_n_c, i_n_c);
        //     end
        //     if (w_snt_n_dc != i_n_dc) begin
        //         $fatal(2, "[time=%0t] value mismatch, w_snt_n_dc: %0d, i_n_dc: %0d", $realtime, w_snt_n_dc, i_n_dc);
        //     end
        // end
        r_cnt <= r_cnt + $clog2(L+1)'(w_snt_n_c) - $clog2(L+1)'(w_snt_n_dc);
        r_cnt_free <= r_cnt_free + $clog2(L+1)'(w_snt_n_dc) - $clog2(L+1)'(w_snt_n_c);
    end
end

//! Updates the delay line.
always_ff @(posedge i_clk) begin: blk_update_line
    if (i_sync_rst) begin
        r_line <= '{default:'0};
    end else if (!i_freeze) begin
        localparam int unsigned BW1 = $clog2(L + MAX_N_DC);
        for (int unsigned i=0; i<L; ++i) begin
            automatic logic [BW1-1:0] src_idx_a = BW1'(i) + BW1'(w_snt_n_dc);
            automatic logic [BW1-1:0] src_idx_b = src_idx_a - BW1'(r_cnt);
            r_line[i] <= (src_idx_a < BW1'(r_cnt)) ? r_line[src_idx_a] : ( // Old element is used. This line causes `Warning (10027)` in Quartus Prime Lite 23.1std, but it is safe.
                (src_idx_b < BW1'(w_snt_n_c)) ? i_c_elems[src_idx_b] : // Input element is used.
                '{default:'0} // Nothing can be used. Clears the slot.
            );
        end
    end
end
// --------------------
endmodule

`default_nettype wire

`endif // MIMO_DLY_LINE_V0_1_1_SV_INCLUDED
