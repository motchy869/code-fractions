// Verible directive
// verilog_lint: waive-start parameter-name-style
// verilog_lint: waive-start line-length

`default_nettype none

//! Galois LFSR generating PN32 sequence
//! reference docs:
//! 1. Linear-feedback shift register (Wikipedia)
//! 2. Efficient Shift Registers, LFSR Counters, and Long Pseudo-Random Sequence Generators (XAPP052)
module pn32 #(
    localparam int unsigned L = 32 //! the length of the shift register (**fixed**, cannot be changed)
)(
    input wire logic i_clk, //! clock signal
    input wire logic i_sync_rst, //! reset signal synchronous to i_clk
    input wire logic i_set_shift_reg, //! instruction to set the shift register
    input wire logic [L-1:0] i_shift_reg_in, //! input data to set the shift register
    output wire logic o_bit_out //! output bit
);
// ---------- parameters ----------
// --------------------

// ---------- parameter validation ----------
// --------------------

// ---------- functions ----------
// --------------------

// ---------- signals and storage ----------
var logic [L-1:0] r_shift_reg = '0; //! shift register
// --------------------

// ---------- instances ----------
// --------------------

// ---------- Drive output signals. ----------
assign o_bit_out = r_shift_reg[0];
// --------------------

// ---------- blocks ----------
//! Updates the shift register.
always_ff @(posedge i_clk) begin: blk_update_shift_reg
    if (i_sync_rst) begin
        r_shift_reg <= '0;
    end else if (i_set_shift_reg) begin
        r_shift_reg <= i_shift_reg_in;
    end else begin
        // generator polynomial: x^32 + x^22 + x^2 + 1
        r_shift_reg[0] <= r_shift_reg[1];
        r_shift_reg[1] <= r_shift_reg[2] ^ r_shift_reg[0];
        r_shift_reg[20:2] <= r_shift_reg[21:3];
        r_shift_reg[21] <= r_shift_reg[22] ^ r_shift_reg[0];
        r_shift_reg[30:22] <= r_shift_reg[31:23];
        r_shift_reg[31] <= r_shift_reg[0];
    end
end
// --------------------
endmodule

`default_nettype uwire
