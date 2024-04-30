// Some techniques used in this file are based on on 'ug901-vivado-synthesis-examples'

// Verible directive
// verilog_lint: waive-start parameter-name-style
// verilog_lint: waive-start line-length

`default_nettype none

//! Single-port wite-first RAM with optional output register.
//! This module is intended to be inferred as a block RAM by synthesis tools.
//!
//! **CAUTION**: This module has **NOT** been tested yet.
//!
//! read latency:
//! - 1 cycle if `USE_OUTPUT_REG` is 0
//! - 2 cycles if `USE_OUTPUT_REG` is 1
//!
//! **NOTE**: 'read latency is n' means that if address input is changed right after the k-th clock rising edge, the corresponding data is shown right after the (k+n)-th clock rising edge.
//!
//! example timing diagram
//! ![example](timing_diagram_example_@read_latency=2.png)
module ram_sp_wf #(
    parameter int WORD_BIT_WIDTH = 8, //! word bit width, **must be power of 2**
    parameter int DEPTH = 8, //! depth of RAM, **must be power of 2**
    parameter bit USE_OUTPUT_REG = 0 //! output register option, 0/1: not use/ use
)(
    input wire i_clk, //! clock signal
    input wire i_sync_rst, //! synchronous reset signal
    input wire i_we, //! write enable signal
    input wire [$clog2(DEPTH)-1:0] i_word_addr, //! word address
    input wire [WORD_BIT_WIDTH-1:0] i_data, //! input data
    input wire [WORD_BIT_WIDTH/8-1:0] i_byte_en, //! byte enable signal
    output wire [WORD_BIT_WIDTH-1:0] o_data //! output data
);
// ---------- parameters ----------
localparam int WORD_ADDR_BIT_WIDTH = $clog2(DEPTH); //! word address bit width, `$clog2(DEPTH)`
// --------------------

// ---------- parameter validation ----------
generate
    if (!$onehot(WORD_BIT_WIDTH)) begin: gen_invalid_WORD_bit_width
        $error("WORD_BIT_WIDTH must be power of 2");
        nonexistent_module_to_throw_a_custom_error_message_for invalid_parameters();
    end

    if (!$onehot(DEPTH)) begin: gen_invalid_addr_bit_width
        $error("DEPTH must be power of 2");
        nonexistent_module_to_throw_a_custom_error_message_for invalid_parameters();
    end
endgenerate
// --------------------

// ---------- internal signal and storage ----------
var logic [WORD_BIT_WIDTH-1:0] r_ram [DEPTH]; //! RAM
var logic [USE_OUTPUT_REG:0][WORD_BIT_WIDTH-1:0] r_out_reg; //! output register
// --------------------

// ---------- Drive output signals. ----------
assign o_data = r_out_reg[USE_OUTPUT_REG];
// --------------------

//! Update RAM content.
always_ff @(posedge i_clk) begin: update_ram
    if (!i_sync_rst && i_we) begin
        for (int i=0; i<WORD_BIT_WIDTH/8; ++i) begin
            if (i_byte_en[i]) begin
                r_ram[i_word_addr][i*8 +: 8] <= i_data[i*8 +: 8];
            end
        end
    end
end

//! Control output register.
always_ff @(posedge i_clk) begin: cont_out_reg
    if (i_sync_rst) begin
        r_out_reg <= '0;
    end else begin
        if (i_we) begin
            r_out_reg[0] <= i_data;
            if (USE_OUTPUT_REG == 1) begin
                r_out_reg[1] <= i_data;
            end
        end else begin
            r_out_reg[0] <= r_ram[i_word_addr];
            if (USE_OUTPUT_REG == 1) begin
                r_out_reg[1] <= r_out_reg[0];
            end
        end
    end
end

endmodule

`default_nettype wire
