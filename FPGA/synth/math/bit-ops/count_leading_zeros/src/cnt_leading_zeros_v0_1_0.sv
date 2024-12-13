// Verible directive
// verilog_lint: waive-start parameter-name-style
// verilog_lint: waive-start line-length

`default_nettype none

//! Counts leading zeros of the input unsigned integer.
//! NEITHER feed-stop nor back-pressure flow control are supported.
//!
//! cycle latency: ```INPUT_REG_CHAIN_LEN``` + 1 + ```OUTPUT_REG_CHAIN_LEN```
module cnt_leading_zeros_v0_1_0 #(
    parameter int unsigned BW_IN = 8, //! bit width of input
    parameter int unsigned INPUT_REG_CHAIN_LEN = 1, //! Input register chain length. When this is set to 0, the input registers are not instantiated. Modern fitting tools will utilize these registers for register re-timing to achieve better timing closure.
    parameter int unsigned OUTPUT_REG_CHAIN_LEN = 1 //! Output register chain length. When this is set to 0, the output registers are not instantiated. Like the input register chain, these registers may also have positive effect for better timing closure.
)(
    input wire logic i_clk, //! input clock
    input wire logic i_sync_rst, //! input reset signal synchronous to the input clock
    input wire logic i_freeze, //! freeze directive, which stops all state transitions except for the reset
    //! @virtualbus us_side_if @dir in upstream side interface
    input wire logic i_in_valid, //! Indicates that the input data is valid.
    input wire logic [BW_IN-1:0] i_in_val, //! input value
    //! @end
    //! @virtualbus ds_side_if @dir out downstream side interface
    //! Indicates that the pipeline is filled with processed data, and the downstream side can start using the output data. This signal should be used just for initial garbage data skip, NOT for flow control.
    output wire logic o_pipeline_filled,
    output wire logic [$clog2(BW_IN+1)-1:0] o_out_val //! output value
    //! @end
);
// ---------- parameters ----------
localparam int unsigned BW_OUT = $clog2(BW_IN+1); //! bit width of output
// --------------------

// ---------- parameter validation ----------
generate
    if (BW_IN == '0) begin: gen_validate_BW_IN
        nonexistent_module_to_throw_a_custom_error_message_for too_small_BW_IN();
    end
endgenerate
// --------------------

// ---------- functions ----------
// --------------------

// ---------- signals and storage ----------
//! data structure for input register chain
typedef struct packed {
    logic [BW_IN-1:0] val;
    logic valid;
} in_reg_chain_elem_t;

//! data structure for output register chain
typedef struct packed {
    logic [BW_OUT-1:0] val;
    logic valid;
} out_reg_chain_elem_t;

wire in_reg_chain_elem_t w_post_irc_val; //! value from input register chain
var in_reg_chain_elem_t r_phase_1; //! Phase 1 result. In this phase, upper portions (there are ```BW_IN``` patterns) are OR-ed to find the first non-zero bit (step-like shape will show up).
var logic [BW_IN-1:0] g_ph_2_ohv; //! one-hot vector for phase 2
var out_reg_chain_elem_t g_pre_orc_out_val; //! value to output register chain
// --------------------

// ---------- instances ----------
reg_chain_v0_1_0 #(
    .CHAIN_LEN(INPUT_REG_CHAIN_LEN),
    .T(in_reg_chain_elem_t)
) in_reg_chain (
    .i_clk(i_clk),
    .i_sync_rst(i_sync_rst),
    .i_freeze(i_freeze),
    .i_us_data({i_in_val, i_in_valid}),
    .o_ds_data(w_post_irc_val)
);

reg_chain_v0_1_0 #(
    .CHAIN_LEN(INPUT_REG_CHAIN_LEN),
    .T(out_reg_chain_elem_t)
) out_reg_chain (
    .i_clk(i_clk),
    .i_sync_rst(i_sync_rst),
    .i_freeze(i_freeze),
    .i_us_data(g_pre_orc_out_val),
    .o_ds_data({o_out_val, o_pipeline_filled})
);
// --------------------

// --------------------

// ---------- Drives output signals. ----------
// --------------------

// ---------- blocks ----------
always_ff @(posedge i_clk) begin: blk_phase_1
    if (i_sync_rst) begin
        r_phase_1 <= '{default: '0};
    end else if (!i_freeze) begin
        var automatic logic [2*BW_IN-2:0] val = {(BW_IN-1)'(0), w_post_irc_val.val}; // Temporary variable to avoid non-constant range. Fitting tools will optimize away the calculation for leading zeros.
        for (int i=0; i<BW_IN; ++i) begin
            //r_phase_1.val[i] <= |w_post_irc_val.val[BW_IN-1:i]; // This fails due to non-constant range
            r_phase_1.val[i] <= |val[i+:BW_IN];
        end
        r_phase_1.valid <= w_post_irc_val.valid;
    end
end

//! In phase 2, the number of the leading zeros are determined.
always_comb begin: blk_phase_2
    g_ph_2_ohv[BW_IN-1] = r_phase_1.val[BW_IN-1];
    for (int unsigned i=0; i<BW_IN-1; ++i) begin
        g_ph_2_ohv[i] = r_phase_1.val[i] & ~r_phase_1.val[i+1];
    end

    g_pre_orc_out_val.val = '0;
    for (int unsigned i=0; i<BW_IN; ++i) begin
        if (g_ph_2_ohv[i]) begin
            g_pre_orc_out_val.val = BW_OUT'(BW_IN-1-i);
        end
    end
    g_pre_orc_out_val.valid = r_phase_1.valid;
end
// --------------------
endmodule

`default_nettype wire
