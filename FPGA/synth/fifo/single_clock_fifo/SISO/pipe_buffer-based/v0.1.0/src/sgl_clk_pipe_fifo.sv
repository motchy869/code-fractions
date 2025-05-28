// Verible directive
// verilog_lint: waive-start parameter-name-style
// verilog_lint: waive-start line-length


`ifndef SGL_CLK_PIPE_FIFO_SV_INCLUDED
`define SGL_CLK_PIPE_FIFO_SV_INCLUDED

`default_nettype none

//! Single-clock symmetric FIFO.
//! The internal storage uses a shift register.
//! This can avoid large selector in the output circuit, different from ring-buffer-based FIFO.
module sgl_clk_pipe_fifo #(
    `ifndef COMPILER_MATURITY_LEVEL_0 // This macro should be set MANUALLY in the project settings if needed.
        parameter type T_ELEM = logic [7:0], //! element data type
    `else
        parameter int unsigned BW_ELEM = 8, //! element data bit width (>=1)
    `endif
    parameter int DEPTH = 16 //! FIFO depth
)(
    //! @virtualbus cont_if @dir in control interface
    //! input clock
    input wire logic i_clk,
    input wire logic i_sync_rst, //! input reset signal synchronous to the input clock
    //! @end

    //! @virtualbus us_side_if @dir in upstream side interface
    //! write-enable
    input wire logic i_wr_en,
    `ifndef COMPILER_MATURITY_LEVEL_0
        input wire T_ELEM i_in_elem, //! input element
    `else
        input wire logic [BW_ELEM-1:0] i_in_elem, //! input element
    `endif
    output wire logic o_full, //! full flag
    //! @end

    //! @virtualbus ds_side_if @dir out downstream side interface
    //! read-enable
    input wire logic i_rd_en,
    `ifndef COMPILER_MATURITY_LEVEL_0
        output wire T_ELEM o_out_elem, //! output element
    `else
        output wire logic [BW_ELEM-1:0] o_out_elem, //! output element
    `endif
    output wire logic o_empty //! empty flag
    //! @end
);
// ---------- imports ----------
// --------------------

// ---------- parameters ----------
localparam int unsigned BW_CNT = $clog2(DEPTH+1); //! bit width for the element count
// --------------------

// ---------- parameter validation ----------
generate
    `ifdef COMPILER_MATURITY_LEVEL_0
        if (BW_ELEM < 1) begin: gen_too_small_BW_ELEM
            nonexistent_module_to_throw_a_custom_error_message_for_too_small_BW_ELEM inst();
        end
    `endif
    if (DEPTH < 1) begin: gen_too_small_DEPTH
        nonexistent_module_to_throw_a_custom_error_message_for_too_small_DEPTH inst();
    end
endgenerate
// --------------------

// ---------- brief sketch ----------
// --------------------

// ---------- functions ----------
// --------------------

// ---------- signals and storage ----------
`ifdef COMPILER_MATURITY_LEVEL_0
    typedef logic [BW_ELEM-1:0] T_ELEM; //! element data type
`endif

var T_ELEM [DEPTH-1:0] r_shift_reg; //! shift register as the storage for FIFO elements
var logic [BW_CNT-1:0] r_cnt; //! element count, the number of elements in the FIFO
wire g_pop_en; //! pop-enable signal
assign g_pop_en = (i_rd_en && !o_empty);
wire g_push_en; //! push-enable signal
assign g_push_en = (i_wr_en && !o_full);
// --------------------

// ---------- instances ----------
// --------------------

// ---------- Drives output signals. ----------
assign o_full = (r_cnt == BW_CNT'(DEPTH));
assign o_out_elem = r_shift_reg[0];
assign o_empty = (r_cnt == '0);
// --------------------

// ---------- blocks ----------
//! Updates the element count.
always_ff @(posedge i_clk) begin: blk_update_cnt
    if (i_sync_rst) begin
        r_cnt <= '0;
    end else begin
        if (g_push_en && !g_pop_en) begin
            r_cnt <= r_cnt + BW_CNT'(1);
        end else if (!g_push_en && g_pop_en) begin
            r_cnt <= r_cnt - BW_CNT'(1);
        end // else begin
            // no change
        // end
    end
end

//! Updates the shift register.
always_ff @(posedge i_clk) begin: blk_update_shift_reg
    if (i_sync_rst) begin
        r_shift_reg <= '{default:'0};
    end else begin
        for (int i=0; i<DEPTH; ++i) begin
            unique case ({g_push_en, g_pop_en})
                2'b01: r_shift_reg[i] <= (i < DEPTH-1) ? r_shift_reg[i+1] : '0;
                2'b10: if (BW_CNT'(i) == r_cnt) r_shift_reg[i] <= i_in_elem;
                2'b11: r_shift_reg[i] <= (BW_CNT'(i) == r_cnt - BW_CNT'(1)) ? i_in_elem : r_shift_reg[i+1];
                default: /* no change */;
            endcase
        end
    end
end
// --------------------
endmodule

`default_nettype wire

`endif // SGL_CLK_PIPE_FIFO_SV_INCLUDED
