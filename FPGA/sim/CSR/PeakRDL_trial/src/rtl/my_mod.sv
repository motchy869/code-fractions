// Verible directive
// verilog_lint: waive-start parameter-name-style
// verilog_lint: waive-start line-length

`include "axi4_lite_if_pkg.svh"
`include "ram_sp_wf.svh"
`include "csr/my_mod_csr_pkg.svh"
`include "csr/my_mod_csr.svh"
`include "csr_to_ram_bridge_if.svh"
`include "csr_to_ram_bridge.svh"

`default_nettype none

//! simple DUT to test my_mod_csr
module my_mod (
    input wire logic i_clk, //! clock signal
    input wire logic i_sync_rst, //! synchronous reset signal
    axi4_lite_if.slv_port if_s_axi4_lite //! AXI4-Lite slave interface
);
// ---------- parameters ----------
localparam int WORD_BIT_WIDTH = 32; //! word bit width
localparam int RAM_DEPTH = 8; //! depth of RAM
localparam int USE_RAM_OUTPUT_REG = 1; //! output register option, 0/1: not use/ use
localparam int RAM_BYTE_ADDR_BIT_WIDTH = $clog2(WORD_BIT_WIDTH/8*RAM_DEPTH); //! byte address bit width
localparam int BYTES_PER_WORD = WORD_BIT_WIDTH/8; //! byte per word
localparam int BYTE_ADDR_BITS_PER_WORD = $clog2(BYTES_PER_WORD); //! byte address bits per word
localparam int RAM_WORD_ADDR_BIT_WIDTH = RAM_BYTE_ADDR_BIT_WIDTH - BYTE_ADDR_BITS_PER_WORD; //! word address bit width
// --------------------

// ---------- parameter validation ----------
generate
    if (!$onehot(WORD_BIT_WIDTH)) begin: gen_invalid_WORD_bit_width
        $error("WORD_BIT_WIDTH must be power of 2");
        nonexistent_module_to_throw_a_custom_error_message_for_invalid_WORD_bit_width inst();
    end

    if (!$onehot(RAM_DEPTH)) begin: gen_invalid_addr_bit_width
        $error("RAM_DEPTH must be power of 2");
        nonexistent_module_to_throw_a_custom_error_message_for_invalid_addr_bit_width inst();
    end
endgenerate
// --------------------

// ---------- internal signal and storage ----------
wire my_mod_csr_pkg::my_mod_csr__in_t w_csr_hw_if_in; //! input to CSR module
wire my_mod_csr_pkg::my_mod_csr__out_t w_csr_hw_if_out; //! output from CSR module
// --------------------

// ---------- instances ----------
//! CSR to RAM bridge CSR-side interface
csr_to_ram_bridge_csr_side_if#(
    .WORD_BIT_WIDTH(WORD_BIT_WIDTH),
    .BYTE_ADDR_BIT_WIDTH(RAM_BYTE_ADDR_BIT_WIDTH)
) csr_to_ram_bridge_csr_side_if_0 (
    .i_clk(i_clk)
);

//! CSR to RAM bridge RAM-side interface
csr_to_ram_bridge_ram_side_if#(
    .WORD_BIT_WIDTH(WORD_BIT_WIDTH),
    .WORD_ADDR_BIT_WIDTH(RAM_WORD_ADDR_BIT_WIDTH)
) csr_to_ram_bridge_ram_side_if_0 (
    .i_clk(i_clk)
);

//! CSR module
my_mod_csr my_mod_csr_0 (
    .clk(i_clk),
    .rst(i_sync_rst),

    .s_axi4lite_awready(if_s_axi4_lite.awready),
    .s_axi4lite_awvalid(if_s_axi4_lite.awvalid),
    .s_axi4lite_awaddr(if_s_axi4_lite.awaddr),
    .s_axi4lite_awprot(if_s_axi4_lite.awprot),
    .s_axi4lite_wready(if_s_axi4_lite.wready),
    .s_axi4lite_wvalid(if_s_axi4_lite.wvalid),
    .s_axi4lite_wdata(if_s_axi4_lite.wdata),
    .s_axi4lite_wstrb(if_s_axi4_lite.wstrb),
    .s_axi4lite_bready(if_s_axi4_lite.bready),
    .s_axi4lite_bvalid(if_s_axi4_lite.bvalid),
    .s_axi4lite_bresp(if_s_axi4_lite.bresp),
    .s_axi4lite_arready(if_s_axi4_lite.arready),
    .s_axi4lite_arvalid(if_s_axi4_lite.arvalid),
    .s_axi4lite_araddr(if_s_axi4_lite.araddr),
    .s_axi4lite_arprot(if_s_axi4_lite.arprot),
    .s_axi4lite_rready(if_s_axi4_lite.rready),
    .s_axi4lite_rvalid(if_s_axi4_lite.rvalid),
    .s_axi4lite_rdata(if_s_axi4_lite.rdata),
    .s_axi4lite_rresp(if_s_axi4_lite.rresp),

    .hw_if_in(w_csr_hw_if_in),
    .hw_if_out(w_csr_hw_if_out)
);

//! RAM
ram_sp_wf#(
    .WORD_BIT_WIDTH(WORD_BIT_WIDTH),
    .DEPTH(RAM_DEPTH),
    .USE_OUTPUT_REG(USE_RAM_OUTPUT_REG)
) ram_sp_wf_0 (
    .i_clk(i_clk),
    .i_sync_rst(i_sync_rst),

    .i_we(csr_to_ram_bridge_ram_side_if_0.we),
    .i_word_addr(csr_to_ram_bridge_ram_side_if_0.word_addr),
    .i_data(csr_to_ram_bridge_ram_side_if_0.wr_data),
    .i_wr_byte_en(csr_to_ram_bridge_ram_side_if_0.wr_byte_en),
    .o_data(csr_to_ram_bridge_ram_side_if_0.rd_data)
);

//! CSR to RAM bridge
csr_to_ram_bridge#(
    .WORD_BIT_WIDTH(WORD_BIT_WIDTH),
    .BYTE_ADDR_BIT_WIDTH(RAM_BYTE_ADDR_BIT_WIDTH),
    .WORD_ADDR_BIT_WIDTH(RAM_WORD_ADDR_BIT_WIDTH),
    .OUTPUT_REG_IS_USED_IN_RAM(USE_RAM_OUTPUT_REG)
) csr_to_ram_bridge_0 (
    .i_clk(i_clk),
    .i_sync_rst(i_sync_rst),
    .if_csr_side(csr_to_ram_bridge_csr_side_if_0.slv_port),
    .if_ram_side(csr_to_ram_bridge_ram_side_if_0.mst_port)
);
// --------------------

// ---------- Drives output signals. ----------
// --------------------

// CSR -> bridge
assign csr_to_ram_bridge_csr_side_if_0.acc_req = w_csr_hw_if_out.SIMPLE_MEM.req;
assign csr_to_ram_bridge_csr_side_if_0.byte_addr = w_csr_hw_if_out.SIMPLE_MEM.addr;
assign csr_to_ram_bridge_csr_side_if_0.acc_req_is_wr = w_csr_hw_if_out.SIMPLE_MEM.req_is_wr;
assign csr_to_ram_bridge_csr_side_if_0.wr_data = w_csr_hw_if_out.SIMPLE_MEM.wr_data;
assign csr_to_ram_bridge_csr_side_if_0.wr_bit_en = w_csr_hw_if_out.SIMPLE_MEM.wr_bit_en;

// CSR <- bridge
assign w_csr_hw_if_in.SIMPLE_MEM.rd_ack = csr_to_ram_bridge_csr_side_if_0.rd_ack;
assign w_csr_hw_if_in.SIMPLE_MEM.rd_data = csr_to_ram_bridge_csr_side_if_0.rd_data;
assign w_csr_hw_if_in.SIMPLE_MEM.wr_ack = csr_to_ram_bridge_csr_side_if_0.wr_ack;

endmodule

`default_nettype wire
