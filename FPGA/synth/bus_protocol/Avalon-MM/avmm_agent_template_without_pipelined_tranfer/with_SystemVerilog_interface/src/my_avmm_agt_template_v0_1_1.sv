// Verible directive
// verilog_lint: waive-start parameter-name-style
// verilog_lint: waive-start line-length

`include "avmm_if_defs_pkg_v0_1_0.svh"

`default_nettype none

//! A quite simple Avalon-MM agent template with 4 writable registers.
//! This module doesn't support pipelined transfer, but this is enough in most cases (such as CSR).
module my_avmm_agt_template_v0_1_1 #(
    parameter int AVMM_ADDR_BIT_WIDTH = 2, //! Bit width of Avalon-MM address bus. Typically log2(number of registers). Note that in default Avalon uses **byte** addressing in hosts and **word** addressing in agents.
    parameter int AVMM_DATA_BIT_WIDTH = 32 //! bit width of Avalon-MM data bus
)(
    input wire logic i_clk, //! clock signal
    input wire logic i_sync_rst, //! reset signal synchronous to clock
    avmm_if_lv0_v0_1_0.agt_pt if_agt_avmm //! Avalon-MM agent interface
);
// ---------- parameters ----------
localparam int unsigned NUM_REGS = 1 << AVMM_ADDR_BIT_WIDTH; //! The number of registers. Note that this is not always power of 2. It depends on the design.
// --------------------

// ---------- parameter validation ----------
// --------------------

// ---------- functions ----------
// --------------------

// ---------- signals and storage ----------
wire g_addr_is_in_range; //! Indicates that the address is in valid range.
assign g_addr_is_in_range = if_agt_avmm.address <= AVMM_ADDR_BIT_WIDTH'(NUM_REGS - 1);
wire [AVMM_DATA_BIT_WIDTH-1:0] g_byte_en_bit_mask; //! byte enable bit mask
generate
    genvar i_gen;
    for (i_gen=0; i_gen<AVMM_DATA_BIT_WIDTH/8; i_gen+=1) begin: gen_byte_en_bit_mask
        assign g_byte_en_bit_mask[i_gen*8 +: 8] = {8{if_agt_avmm.byteenable[i_gen]}};
    end
endgenerate

var logic r_wr_resp_vld; //! the value of ```writeresponsevalid``` right AFTER the next rising edge of the clock
var logic [AVMM_DATA_BIT_WIDTH-1:0] g_rd_data; //! read data
var avmm_if_defs_pkg_v0_1_0::avmm_resp_t g_rd_resp; //! read response
var avmm_if_defs_pkg_v0_1_0::avmm_resp_t g_wr_resp; //! write response.

var logic [AVMM_DATA_BIT_WIDTH-1:0] r_reg_0; //! register 0
var logic [AVMM_DATA_BIT_WIDTH-1:0] r_reg_1; //! register 1
var logic [AVMM_DATA_BIT_WIDTH-1:0] r_reg_2; //! register 2
var logic [AVMM_DATA_BIT_WIDTH-1:0] r_reg_3; //! register 3
// --------------------

// ---------- instances ----------
// --------------------

// ---------- Drives output signals. ----------
assign if_agt_avmm.readdata = g_rd_data;
assign if_agt_avmm.response = if_agt_avmm.read ? g_rd_resp : g_wr_resp;
// --------------------

// ---------- blocks ----------
//! Decodes the address and drives the read data.
always_comb begin: blk_dec_rd_addr
    if (if_agt_avmm.read) begin
        g_rd_resp = avmm_if_defs_pkg_v0_1_0::AVMM_RESP_OKAY;
        case (if_agt_avmm.address)
            AVMM_ADDR_BIT_WIDTH'(0): g_rd_data = r_reg_0;
            AVMM_ADDR_BIT_WIDTH'(1): g_rd_data = r_reg_1;
            AVMM_ADDR_BIT_WIDTH'(2): g_rd_data = r_reg_2;
            AVMM_ADDR_BIT_WIDTH'(3): g_rd_data = r_reg_3;
            default: begin
                g_rd_resp = avmm_if_defs_pkg_v0_1_0::AVMM_RESP_DECODEERROR;
                g_rd_data = '0;
            end
        endcase
    end else begin
        g_rd_resp = avmm_if_defs_pkg_v0_1_0::AVMM_RESP_OKAY;
        g_rd_data = '0;
    end
end

//! Drives the write response.
always_comb begin: blk_drv_wr_resp
    if (if_agt_avmm.write) begin
        g_wr_resp = g_addr_is_in_range ? avmm_if_defs_pkg_v0_1_0::AVMM_RESP_OKAY : avmm_if_defs_pkg_v0_1_0::AVMM_RESP_DECODEERROR;
    end else begin
        g_wr_resp = avmm_if_defs_pkg_v0_1_0::AVMM_RESP_OKAY;
    end
end

//! Writes the data to the register.
always_ff @(posedge i_clk) begin: blk_write_regs
    if (i_sync_rst) begin
        r_reg_0 <= '0;
        r_reg_1 <= '0;
        r_reg_2 <= '0;
        r_reg_3 <= '0;
    end else if (if_agt_avmm.write) begin
        automatic logic [AVMM_DATA_BIT_WIDTH-1:0] masked_wr_dat = if_agt_avmm.writedata & g_byte_en_bit_mask;
        case (if_agt_avmm.address)
            AVMM_ADDR_BIT_WIDTH'(0): r_reg_0 <= (r_reg_0 & ~g_byte_en_bit_mask) | masked_wr_dat;
            AVMM_ADDR_BIT_WIDTH'(1): r_reg_1 <= (r_reg_1 & ~g_byte_en_bit_mask) | masked_wr_dat;
            AVMM_ADDR_BIT_WIDTH'(2): r_reg_2 <= (r_reg_2 & ~g_byte_en_bit_mask) | masked_wr_dat;
            AVMM_ADDR_BIT_WIDTH'(3): r_reg_3 <= (r_reg_3 & ~g_byte_en_bit_mask) | masked_wr_dat;
            default: begin
                // nothing to do
            end
        endcase
    end
end
// --------------------
endmodule

`default_nettype wire
