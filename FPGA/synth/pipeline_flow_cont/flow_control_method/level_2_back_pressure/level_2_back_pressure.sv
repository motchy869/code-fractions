// Verible directive
// verilog_lint: waive-start parameter-name-style
// verilog_lint: waive-start line-length

`default_nettype none

//! Computes the sum of two inputs.
//! Both feed-stop and back-pressure flow control are supported.
module level_2_back_pressure #(
    parameter int unsigned BIT_WIDTH_IN = 8 //! input bit with, must be greater than 0
)(
    input wire logic i_clk, //! input clock
    input wire logic i_sync_rst, //! input reset signal synchronous to the input clock
    input wire logic i_freeze, //! freeze directive, which stops all state transitions except for the reset
    //! @virtualbus us_side_if @dir in upstream side interface
    output wire logic o_ready, //! ready signal to upstream side which indicates that the upstream side is allowed to update input data (to this module) right AFTER the next rising edge of the clock
    input wire logic i_in_valid, //! Indicates that the input data is valid
    input wire logic signed [BIT_WIDTH_IN-1:0] i_a, //! input a
    input wire logic signed [BIT_WIDTH_IN-1:0] i_b, //! input b
    //! @end
    //! @virtualbus ds_side_if @dir out downstream side interface
    //! ready signal from downstream side which indicates that this module is allowed to update output data (to downstream side) right AFTER the next rising edge of the clock
    input wire logic i_ds_ready,
    output wire logic o_out_valid, //! Indicates that the output data is valid
    output wire logic signed [BIT_WIDTH_IN:0] o_sum //! output sum
    //! @end
);
// ---------- parameters ----------
localparam int unsigned BIT_WIDTH_OUT = BIT_WIDTH_IN + 1; //! output bit width
// --------------------

// ---------- parameter validation ----------
generate
    if (BIT_WIDTH_IN == '0) begin: gen_input_bit_width_validation
        nonexistent_module_to_throw_a_custom_error_message_for too_small_input_bit_width();
    end
endgenerate
// --------------------

// ---------- functions ----------
// --------------------

// ---------- signals and storage ----------
wire g_adv_pipeline; //! signal indicating that the pipeline should advance
assign g_adv_pipeline = i_in_valid && o_ready;
var logic r_vld_dly_line; //! valid delay line before the output skid buffer
var logic signed [BIT_WIDTH_OUT-1:0] r_sum; //! pipeline for sum
// --------------------

// ---------- instances ----------
skid_buf_v0_1_0 #(
    .T_E(logic [BIT_WIDTH_OUT-1:0])
) output_skid_buf (
    .i_clk(i_clk),
    .i_sync_rst(i_sync_rst),
    .i_freeze(i_freeze),
    .i_us_valid(i_in_valid && r_vld_dly_line),
    .i_us_data(r_sum),
    .o_us_ready(o_ready),
    .i_ds_ready(i_ds_ready),
    .o_ds_valid(o_out_valid),
    .o_ds_data(o_sum)
);
// --------------------

// ---------- Drives output signals. ----------
// --------------------

// ---------- blocks ----------
//! Updates valid delay line.
always_ff @(posedge i_clk) begin: blk_update_vld_dly_line
    if (i_sync_rst) begin
        r_vld_dly_line <= '0;
    end else if (!i_freeze) begin
        if (g_adv_pipeline) begin
            r_vld_dly_line <= 1'b1;
        end
    end
end

//! Updates sum.
always_ff @(posedge i_clk) begin: blk_update_sum
    if (i_sync_rst) begin
        r_sum <= '0;
    end else if (!i_freeze) begin
        if (g_adv_pipeline) begin
            r_sum <= BIT_WIDTH_OUT'(i_a) + BIT_WIDTH_OUT'(i_b);
        end
    end
end
// --------------------
endmodule

`default_nettype wire
