// Verible directives
// verilog_lint: waive-start parameter-name-style
// verilog_lint: waive-start line-length

`default_nettype none

//! Output register layer for downstream side interface.
//! This module can be used to attach registered outputs to the existing module's downstream side interface.
module ds_side_if_out_reg_layer #(
    parameter type T = logic //! data type
)(
    input wire logic i_clk, //! clock signal
    input wire logic i_sync_rst, //! synchronous reset signal

    //! @virtualbus core_side_if @dir in core side interface
    input wire logic i_valid_from_core, //! valid signal from core
    input wire T i_data_from_core, //! data from core
    output wire logic o_ready_to_core, //! ready signal to core
    //! @end

    //! @virtualbus partner_side_if @dir in partner side interface
    input wire logic i_ready_from_partner, //! ready signal from partner
    output wire logic o_valid_to_partner, //! valid signal to partner
    output wire T o_data_to_partner //! data to partner
    //! @end
);
// ---------- parameters ----------
// --------------------

// ---------- parameter validation ----------
// --------------------

// ---------- internal signal and storage ----------
typedef struct {
    logic valid; //! valid
    T data; //! data
} data_buf_t;
var data_buf_t r_data_buf; //! data buffer to store core data
// --------------------

// ---------- Drive output signals. ----------
assign o_ready_to_core = !r_data_buf.valid || i_ready_from_partner;
assign o_valid_to_partner = r_data_buf.valid;
assign o_data_to_partner = r_data_buf.data;
// --------------------

// ---------- blocks ----------
//! Update data buffer.
always_ff @(posedge i_clk) begin: blk_update_core_data_buf
    if (i_sync_rst) begin
        r_data_buf <= '{default:'0};
    end else begin
        r_data_buf <= o_ready_to_core ? '{valid: i_valid_from_core, data: i_data_from_core} : r_data_buf;
    end
end
// --------------------
endmodule

`default_nettype wire
