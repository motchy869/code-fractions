// Verible directive
// verilog_lint: waive-start parameter-name-style
// verilog_lint: waive-start line-length

`default_nettype none

//! Computes the sum of two inputs.
//! NEITHER feed-stop nor back-pressure flow control are supported.
module level_0_no_cont #(
    parameter int unsigned BIT_WIDTH_IN = 8 //! input bit with, must be greater than 0
)(
    input wire logic i_clk, //! input clock
    input wire logic i_sync_rst, //! input reset signal synchronous to the input clock
    input wire logic i_freeze, //! freeze directive, which stops all state transitions except for the reset
    //! @virtualbus us_side_if @dir in upstream side interface
    input wire logic i_in_valid, //! Indicates that the input data is valid.
    input wire logic signed [BIT_WIDTH_IN-1:0] i_a, //! input a
    input wire logic signed [BIT_WIDTH_IN-1:0] i_b, //! input b
    //! @end
    //! @virtualbus ds_side_if @dir out downstream side interface
    //! Indicates that the pipeline is filled with processed data, and the downstream side can start using the output data. This signal should be used just for initial garbage data skip, NOT for flow control.
    output wire logic o_pipeline_filled,
    output wire logic signed [BIT_WIDTH_IN:0] o_sum //! output sum
    //! @end
);
// ---------- parameters ----------
localparam int unsigned BIT_WIDTH_OUT = BIT_WIDTH_IN + 1; //! output bit width
localparam int unsigned CYCLE_LATENCY = 1; //! cycle latency
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
var logic [CYCLE_LATENCY-1:0] r_vld_dly_line; //! delay line for the input valid signal
var logic signed [BIT_WIDTH_OUT-1:0] r_sum; //! sum
// --------------------

// ---------- instances ----------
// --------------------

// ---------- Drives output signals. ----------
assign o_pipeline_filled = !i_sync_rst && r_vld_dly_line[CYCLE_LATENCY-1];
assign o_sum = r_sum;
// --------------------

// ---------- blocks ----------
//! Updates valid delay line.
always_ff @(posedge i_clk) begin: blk_update_vld_dly_line
    if (i_sync_rst) begin
        r_vld_dly_line <= '0;
    end else if (!i_freeze) begin
        if (i_in_valid) begin
            r_vld_dly_line <= 1'b1;
        end
    end
end

//! Updates sum.
always_ff @(posedge i_clk) begin: blk_update_sum
    if (i_sync_rst) begin
        r_sum <= '0;
    end else if (!i_freeze) begin
        if (i_in_valid) begin
            r_sum <= BIT_WIDTH_OUT'(i_a) + BIT_WIDTH_OUT'(i_b);
        end
    end
end
// --------------------
endmodule

`default_nettype wire
