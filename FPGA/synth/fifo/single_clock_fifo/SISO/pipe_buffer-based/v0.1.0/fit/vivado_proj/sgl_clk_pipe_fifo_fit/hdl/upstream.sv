// Verible directive
// verilog_lint: waive-start parameter-name-style
// verilog_lint: waive-start line-length

`default_nettype none

//! example upstream module
module upstream #(
    parameter type T_ELEM = logic [7:0] //! element data type
)(
    //! @virtualbus cont_if @dir in control interface
    //! input clock
    input wire logic i_clk,
    input wire logic i_sync_rst, //! input reset signal synchronous to the input clock
    //! @end

    //! @virtualbus ds_side_if @dir out downstream side interface
    //! write-enable
    output wire logic o_wr_en,
    output wire T_ELEM o_out_elem, //! output element
    input wire logic i_full //! full flag from downstream side
    //! @end
);
// ---------- imports ----------
// --------------------

// ---------- parameters ----------
localparam int unsigned BW_CNT = 8; //! bit width for the internal count
// --------------------

// ---------- parameter validation ----------
// --------------------

// ---------- functions ----------
// --------------------

// ---------- signals and storage ----------
(* keep = "true" *) var logic [BW_CNT-1:0] r_cnt; //! internal count
// --------------------

// ---------- instances ----------
// --------------------

// ---------- Drives output signals. ----------
assign o_wr_en = (r_cnt[1:0] == 2'b11);
assign o_out_elem = T_ELEM'(r_cnt);
// --------------------

// ---------- blocks ----------
//! Updates the internal count
always_ff @(posedge i_clk) begin: blk_update_cnt
    if (i_sync_rst) begin
        r_cnt <= '0;
    end else begin
        r_cnt <= r_cnt + BW_CNT'(1);
    end
end
// --------------------
endmodule

`default_nettype wire
