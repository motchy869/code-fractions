// Verible directive
// verilog_lint: waive-start parameter-name-style
// verilog_lint: waive-start line-length

`include "pn32.svh"

`default_nettype none

//! top module to test ```chunkizer```
module top (
    input wire logic i_clk, //! clock signal
    input wire logic i_async_rst, //! reset signal **asynchronous** to clock
    output wire logic [2:0] o_led //! Signals to on/off LEDs. This is generated from the output of DUT to prevent them from being optimized away.
);
// ---------- parameters ----------
localparam int unsigned SZ_MAX_IN = 8;//! max size of the input fragment
localparam int unsigned SZ_OUT = 4;//! The size of the output chunk.
localparam int unsigned FRAG_ELEM_BIT_WIDTH = 8; //! the bit width of the fragment's element
localparam int unsigned BIT_WIDTH__SZ_MAX_IN = $clog2(SZ_MAX_IN+1); //! the bit width of the fragment's max size
// --------------------

// ---------- signal and storage ----------
(* mark_debug = "true" *) var logic [1:0] r_sync_rst; //! 2-stage FFs to synchronize the reset signal
(* mark_debug = "true" *) wire g_sync_rst; //! reset signal synchronized to the clock
(* mark_debug = "true" *) assign g_sync_rst = r_sync_rst[1];
var logic r_delayed_rst; //! Reset signal delayed by 1 clock cycle. Mainly used to set PN32 generator's seed.

(* mark_debug = "true" *) wire w_pn32_bit; //! PN32 bit sequence

(* mark_debug = "true" *) var logic r_frag_valid; //! valid signal of the fragment
(* mark_debug = "true" *) var logic [BIT_WIDTH__SZ_MAX_IN-1:0] r_frag_size; //! size of the fragment
(* mark_debug = "true" *) wire w_flush; //! flush signal
(* mark_debug = "true" *) assign w_flush = 1'b0;
(* mark_debug = "true" *) var logic [SZ_MAX_IN-1:0][FRAG_ELEM_BIT_WIDTH-1:0] r_frag; //! fragment
(* mark_debug = "true" *) wire w_next_frag_ready; //! ready signal for the next fragment
(* mark_debug = "true" *) var logic r_ds_ready; //! ready signal for the downstream side IF of the DUT
(* mark_debug = "true" *) wire w_chunk_valid; //! valid signal of the chunk
(* mark_debug = "true" *) wire [SZ_OUT-1:0][FRAG_ELEM_BIT_WIDTH-1:0] w_chunk; //! chunk

(* mark_debug = "true" *) var logic r_next_frag_ready; //! buffer to sample ```w_next_frag_ready```
(* mark_debug = "true" *) var logic r_chunk_valid; //! buffer to sample ```w_chunk_valid```
(* mark_debug = "true" *) var logic [SZ_OUT-1:0][FRAG_ELEM_BIT_WIDTH-1:0] r_chunk; //! buffer to sample ```w_chunk```
// --------------------

// ---------- instances ----------
//! PN32 sequence generator
pn32 pn32_inst (
    .i_clk(i_clk),
    .i_sync_rst(g_sync_rst),
    .i_set_shift_reg(r_delayed_rst),
    .i_shift_reg_in(32'h12345678),
    .o_bit_out(w_pn32_bit)
);

//! DUT instance
chunkizer #(
    .SZ_MAX_IN(SZ_MAX_IN),
    .SZ_OUT(SZ_OUT)
) dut (
    .i_clk(i_clk),
    .i_sync_rst(g_sync_rst),

    .i_frag_valid(r_frag_valid),
    .i_frag_size(r_frag_size),
    .i_flush(w_flush),
    .i_frag(r_frag),
    .o_next_frag_ready(w_next_frag_ready),

    .i_ds_ready(r_ds_ready),
    .o_chunk_valid(w_chunk_valid),
    .o_chunk(w_chunk)
);
// --------------------

// ---------- Drives output signals. ----------
assign o_led[0] = r_next_frag_ready;
assign o_led[1] = r_chunk_valid;
assign o_led[2] = ! r_chunk;
// --------------------

// ---------- blocks ----------
//! Updates the synchronized reset signal.
always_ff @(posedge i_clk) begin: blk_update_sync_rst
    r_sync_rst <= {r_sync_rst[0], i_async_rst};
end

//! Updates the delayed reset signal.
always_ff @(posedge i_clk) begin: blk_update_delayed_rst
    r_delayed_rst <= g_sync_rst;
end

//! Feeds DUT inputs.
always_ff @(posedge i_clk) begin: blk_feed_dut_inputs
    if (g_sync_rst) begin
        r_frag_valid <= 1'b0;
        r_frag_size <= '0;
        r_frag <= '{default:'0};
        r_ds_ready <= 1'b0;
    end else begin
        r_frag_valid <= w_pn32_bit;
        r_frag_size <= {r_frag_size[$left(r_frag_size)-2:0], w_pn32_bit};
        r_frag <= {{r_frag}[0+:SZ_MAX_IN*FRAG_ELEM_BIT_WIDTH-1], w_pn32_bit};
        r_ds_ready <= w_pn32_bit;
    end
end

//! Sample outputs of the DUT.
always_ff @(posedge i_clk) begin: blk_sample_dut_outputs
    r_next_frag_ready <= w_next_frag_ready;
    r_chunk_valid <= w_chunk_valid;
    r_chunk <= w_chunk;
end
// --------------------
endmodule

`default_nettype wire
