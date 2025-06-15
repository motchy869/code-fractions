// Verible directive
// verilog_lint: waive-start parameter-name-style
// verilog_lint: waive-start line-length

`ifndef DP_RAM_SGL_CLK_AW_BR_V0_1_0_DEFINED
`define DP_RAM_SGL_CLK_AW_BR_V0_1_0_DEFINED

`default_nettype none

//! A single-clock dual-port RAM.
//! A-side is write-only, B-side is read-only.
//!
//! This module is intended to be inferred as a block RAM by synthesis tools.
module dp_ram_sgl_clk_aw_br_v0_1_0 #(
    parameter int unsigned WD_SZ_BASE = 16, //! base word size
    parameter int unsigned WD_SZ_A = WD_SZ_BASE, //! A-side-word-size, must be a positive integer multiple of `WD_SZ_BASE`
    parameter int unsigned WD_SZ_B = 4*WD_SZ_BASE, //! B-side-word-size, must be a positive integer multiple of `WD_SZ_BASE`
    parameter int unsigned WD_CNT = 16, //! number of base words in the RAM
    parameter int unsigned NUM_OUT_REG = 1 //! Number of output registers for B-side, must be greater than 0. The read latency is ```NUM_OUT_REG``` clock cycles.
)(
    //! @virtualbus cont_if @dir in control interface
    //! clock signal
    input wire logic i_clk,
    input wire logic i_sync_rst, //! reset signal synchronous to clock
    //! @end
    //! @virtualbus a_side_if @dir in A-side side interface
    input wire logic i_a_wr_en, //! write enable for A-side
    input wire logic [$clog2(WD_CNT*WD_SZ_BASE/WD_SZ_A)-1:0] i_a_wr_addr, //! write word address for A-side
    input wire logic [WD_SZ_A-1:0] i_a_wr_data, //! write data for A-side
    //! @end
    //! @virtualbus b_side_if @dir in B-side side interface
    input wire logic i_b_rd_en, //! read enable for B-side
    input wire logic [$clog2(WD_CNT*WD_SZ_BASE/WD_SZ_B)-1:0] i_b_rd_addr, //! read word address for B-side
    output wire logic [WD_SZ_B-1:0] o_b_rd_data //! read data for B-side
    //! @end
);
// ---------- imports ----------
// --------------------

// ---------- parameters ----------
localparam int unsigned BIT_CNT = WD_CNT*WD_SZ_BASE; //! total number of bits in the RAM
localparam int unsigned WD_CNT_A = BIT_CNT/WD_SZ_A; //! number of A-side words in the RAM
localparam int unsigned WD_CNT_B = BIT_CNT/WD_SZ_B; //! number of B-side words in the RAM
// localparam int unsigned ADDR_SZ_A = $clog2(WD_CNT_A); //! address size for A-side
// localparam int unsigned ADDR_SZ_B = $clog2(WD_CNT_B); //! address size for B-side
// --------------------

// ---------- parameter validation ----------
generate
    if (WD_SZ_A < 1) begin: gen_too_small_WD_SZ_A
        nonexistent_module_to_throw_a_custom_error_message_for_too_small_WD_SZ_A inst();
    end
    if (WD_SZ_A % WD_SZ_BASE != 0) begin: gen_non_divisible_WD_SZ_A
        nonexistent_module_to_throw_a_custom_error_message_for_invalid_WD_SZ_A inst();
    end
    if (WD_SZ_B < 1) begin: gen_too_small_WD_SZ_B
        nonexistent_module_to_throw_a_custom_error_message_for_too_small_WD_SZ_B inst();
    end
    if (WD_SZ_B % WD_SZ_BASE != 0) begin: gen_non_divisible_WD_SZ_B
        nonexistent_module_to_throw_a_custom_error_message_for_invalid_WD_SZ_B inst();
    end
    if (WD_CNT_A*WD_SZ_A != BIT_CNT) begin: gen_invalid_WD_SZ_A
        nonexistent_module_to_throw_a_custom_error_message_for_invalid_WD_SZ_A inst();
    end
    if (WD_CNT_B*WD_SZ_B != BIT_CNT) begin: gen_invalid_WD_SZ_B
        nonexistent_module_to_throw_a_custom_error_message_for_invalid_WD_SZ_B inst();
    end
    if (NUM_OUT_REG < 1) begin: gen_too_small_NUM_OUT_REG
        nonexistent_module_to_throw_a_custom_error_message_for_too_small_NUM_OUT_REG inst();
    end
endgenerate
// --------------------

// ---------- brief sketch ----------
// --------------------

// ---------- functions ----------
// --------------------

// ---------- signals and storage ----------
typedef union packed {
    logic [WD_CNT-1:0][WD_SZ_BASE-1:0] view_base; //! base view
    logic [WD_CNT_A-1:0][WD_SZ_A-1:0] view_a; //! A-side view
    logic [WD_CNT_B-1:0][WD_SZ_B-1:0] view_b; //! B-side view
} ram_storage_t;
var ram_storage_t r_ram; //! RAM storage
var logic [NUM_OUT_REG-1:0][WD_SZ_B-1:0] r_out_reg; //! output registers for B-side read data
// --------------------

// ---------- instances ----------
// --------------------

// ---------- Drives output signals. ----------
assign o_b_rd_data = r_out_reg[NUM_OUT_REG-1]; //! output data for B-side
// --------------------

// ---------- blocks ----------
//! Updates RAM storage.
always_ff @(posedge i_clk) begin: blk_update_ram
    if (~i_sync_rst & i_a_wr_en) begin
        r_ram.view_a[i_a_wr_addr] <= i_a_wr_data;
    end
end

//! Updates output registers for B-side read data.
always_ff @(posedge i_clk) begin: blk_update_out_reg
    if (i_sync_rst) begin
        r_out_reg <= '0;
    end else if (i_b_rd_en) begin
        r_out_reg[0] <= r_ram.view_b[i_b_rd_addr];
        for (int i=1; i<NUM_OUT_REG; i++) begin
            r_out_reg[i] <= r_out_reg[i-1];
        end
    end
end
// --------------------
endmodule

`default_nettype wire

`endif // DP_RAM_SGL_CLK_AW_BR_V0_1_0_DEFINED
