// Verible directives
// verilog_lint: waive-start parameter-name-style
// verilog_lint: waive-start line-length

`include "ds_side_reg_layer.svh"

`default_nettype none

//! Output register layer for downstream side interface.
//! This module can be used to attach registered outputs to the existing module's downstream side interface.
module ds_side_reg_layer #(
    parameter type T = logic //! data type
)(
    input wire logic i_clk, //! clock signal
    input wire logic i_sync_rst, //! synchronous reset signal

    ds_side_reg_layer_core_side_if.slv_port if_s_core_side, //! slave interface to the core

    //! @virtualbus partner_side_if @dir in partner side interface
    output wire logic o_valid_to_partner, //! valid signal to partner
    output wire T o_data_to_partner, //! data to partner
    input wire logic i_ready_from_partner //! ready signal from partner
    //! @end
);
// ---------- parameters ----------
// --------------------

// ---------- parameter validation ----------
// --------------------

// ---------- internal signal and storage ----------
var logic r_valid_buf; //! buffer for valid signal
var T r_data_buf; //! buffer for data signal

// --------------------

// ---------- Drive output signals. ----------
assign if_s_core_side.ready_reg_layer_to_core = !r_valid_buf || i_ready_from_partner;
assign o_valid_to_partner = r_valid_buf;
assign o_data_to_partner = r_data_buf;
// --------------------

// ---------- blocks ----------
//! Update data buffer.
always_ff @(posedge i_clk) begin: blk_update_core_data_buf
    if (i_sync_rst) begin
        r_valid_buf <= 1'b0;
        r_data_buf <= '{default:'0};
    end else begin
        r_valid_buf <= if_s_core_side.valid_core_to_reg_layer ? 1'b1 : 1'b0;
        r_data_buf <= if_s_core_side.valid_core_to_reg_layer ? if_s_core_side.data_core_to_reg_layer : r_data_buf;
    end
end
// --------------------
endmodule

`default_nettype wire
