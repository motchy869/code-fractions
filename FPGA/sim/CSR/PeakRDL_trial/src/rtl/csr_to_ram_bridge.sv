// Verible directive
// verilog_lint: waive-start parameter-name-style
// verilog_lint: waive-start line-length

`include "csr_to_ram_bridge_if.svh"

`default_nettype none

//! Translate access from CSR to RAM operation.
module csr_to_ram_bridge#(
    parameter int WORD_BIT_WIDTH = 32, //! word bit width, **must be power of 2**
    parameter int BYTE_ADDR_BIT_WIDTH = 8, //! byte address bit width
    parameter int WORD_ADDR_BIT_WIDTH = BYTE_ADDR_BIT_WIDTH - $clog2(WORD_BIT_WIDTH/8), //! word address bit width
    parameter bit OUTPUT_REG_IS_USED_IN_RAM = 0 //! RAM output register option, 0/1: use/not use
)(
    input wire logic i_clk, //! clock signal
    input wire logic i_sync_rst, //! synchronous reset signal

    csr_to_ram_bridge_csr_side_if.slv_port if_csr_side, //! CSR-side slave interface
    csr_to_ram_bridge_ram_side_if.mst_port if_ram_side //! RAM-side master interface
);
// ---------- parameters ----------
localparam int BYTES_PER_WORD = WORD_BIT_WIDTH/8; //! byte per word
localparam int BYTE_ADDR_BITS_PER_WORD = $clog2(BYTES_PER_WORD); //! byte address bits per word
// --------------------

// ---------- parameter validation ----------
generate
    if (if_csr_side.WORD_BIT_WIDTH != WORD_BIT_WIDTH) begin: gen_invalid_WORD_BIT_WIDTH
        $error("WORD_BIT_WIDTH must be equal to WORD_BIT_WIDTH of if_csr_side");
        nonexistent_module_to_throw_a_custom_error_message_for invalid_parameters();
    end

    if (if_csr_side.BYTE_ADDR_BIT_WIDTH != BYTE_ADDR_BIT_WIDTH) begin: gen_invalid_BYTE_ADDR_BIT_WIDTH
        $error("BYTE_ADDR_BIT_WIDTH must be equal to BYTE_ADDR_BIT_WIDTH of if_csr_side");
        nonexistent_module_to_throw_a_custom_error_message_for invalid_parameters();
    end

    if (if_ram_side.WORD_ADDR_BIT_WIDTH != WORD_ADDR_BIT_WIDTH) begin: gen_invalid_WORD_ADDR_BIT_WIDTH
        $error("WORD_ADDR_BIT_WIDTH must be equal to WORD_ADDR_BIT_WIDTH of if_ram_side");
        nonexistent_module_to_throw_a_custom_error_message_for invalid_parameters();
    end
endgenerate
// --------------------

// ---------- internal signal and storage ----------
wire [WORD_BIT_WIDTH/8-1:0] g_byte_en; //! byte enable signal
wire [WORD_ADDR_BIT_WIDTH-1:0] g_word_addr; //! word address
var logic [OUTPUT_REG_IS_USED_IN_RAM:0] r_rd_ack; //! read acknowledge signal
var logic r_wr_ack; //! write acknowledge signal
// --------------------

// ---------- Drive output signals. ----------
assign if_csr_side.rd_ack = r_rd_ack[OUTPUT_REG_IS_USED_IN_RAM];
assign if_csr_side.rd_data = if_ram_side.rd_data;
assign if_csr_side.wr_ack = r_wr_ack;

assign if_ram_side.we = if_csr_side.acc_req && if_csr_side.acc_req_is_wr;
assign if_ram_side.word_addr = g_word_addr;
assign if_ram_side.wr_byte_en = g_byte_en;
assign if_ram_side.wr_data = if_csr_side.wr_data;
// --------------------

generate
    genvar i_gen;
    for (i_gen=0; i_gen<WORD_BIT_WIDTH/8; ++i_gen) begin: gen_byte_en
        assign g_byte_en[i_gen] = &(if_csr_side.wr_bit_en[i_gen*8 +: 8]);
    end
endgenerate

assign g_word_addr = if_csr_side.byte_addr[BYTE_ADDR_BITS_PER_WORD +: WORD_ADDR_BIT_WIDTH];

//! Control `r_rd_ack`.
always_ff @(posedge i_clk) begin: cont_rd_ack
    if (i_sync_rst) begin
        r_rd_ack <= '0;
    end else begin
        r_rd_ack[0] <= if_csr_side.acc_req && !if_csr_side.acc_req_is_wr;
        if (OUTPUT_REG_IS_USED_IN_RAM) begin
            r_rd_ack[1] <= r_rd_ack[0];
        end
    end
end

//! Control `r_wr_ack`.
always_ff @(posedge i_clk) begin: cont_wr_ack
    if (i_sync_rst) begin
        r_wr_ack <= '0;
    end else begin
        r_wr_ack <= if_csr_side.acc_req && if_csr_side.acc_req_is_wr;
    end
end
endmodule

`default_nettype wire
