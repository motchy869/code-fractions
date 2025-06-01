// Verible directive
// verilog_lint: waive-start parameter-name-style
// verilog_lint: waive-start line-length

`ifndef ASYNC_RST_SYNC_RLS_V0_1_0_SV_INCLUDED
`define ASYNC_RST_SYNC_RLS_V0_1_0_SV_INCLUDED

`default_nettype none

//! A mixed reset signal generation module.
//! RESET timing is not guaranteed to be synchronous, but RELEASE timing is guaranteed to be synchronous.
//!
//! The technique used in this module is described in the blog post linked below.
//!
//! [【FPGA】同期リセットと非同期リセット【リセット回路】](http://fpgainfo.blog.fc2.com/blog-entry-87.html)
module async_rst_sync_rls_v0_1_0 (
    input wire logic i_clk, //! clock signal
    input wire logic i_rst, //! input reset signal, which is not guaranteed to be synchronous
    output wire logic o_rst //! output reset signal, whose RELEASE timing is guaranteed to be synchronous
);
// ---------- imports ----------
// --------------------

// ---------- parameters ----------
// --------------------

// ---------- parameter validation ----------
// --------------------

// ---------- brief sketch ----------
// --------------------

// ---------- functions ----------
// --------------------

// ---------- signals and storage ----------
var logic [1:0] r_sft_reg; //! 2-stage shift register for synchronizing the release signal
// --------------------

// ---------- instances ----------
// --------------------

// ---------- Drives output signals. ----------
assign o_rst = r_sft_reg[1];
// --------------------

// ---------- blocks ----------
//! Update shift register
always_ff @(posedge i_clk or posedge i_rst) begin: blk_update_sft_reg
    if (i_rst) begin
        r_sft_reg <= '1;
    end else begin
        r_sft_reg <= {r_sft_reg[0], 1'b0};
    end
end
// --------------------
endmodule

`default_nettype wire

`endif // ASYNC_RST_SYNC_RLS_V0_1_0_SV_INCLUDED
