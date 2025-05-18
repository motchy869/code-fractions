// Verible directive
// verilog_lint: waive-start parameter-name-style
// verilog_lint: waive-start line-length

`ifndef SFT_REG_SLC_V0_2_0_SV_INCLUDED
`define SFT_REG_SLC_V0_2_0_SV_INCLUDED

`default_nettype none

//! A slicer based on shift register.
//! This can save a lot of combinational logic compared to a normal combinational slicer in exchange for additional flip-flops and latency.
//!
//! This module receives a vector of length ```W_I``` and outputs a sub-vector of length ```W_O``` with fixed latency, ```W_I - W_O + 1``` cycles.
//! There is **no handshake** function, so a parent module must handle the flow control.
module sft_reg_slc_v0_2_0 #(
    `ifndef COMPILER_MATURITY_LEVEL_0 // This macro should be set MANUALLY in the project settings if needed.
        parameter type T_ELEM = logic [7:0], //! element data type
    `else
        parameter int unsigned BW_ELEM = 8, //! element data bit width (>=1)
    `endif
    parameter int unsigned W_I = 8, //! input width measured in elements
    parameter int unsigned W_O = 4 //! output width measured in elements, must be in the range of [1, W_I-1]
)(
    //! @virtualbus cont_if @dir in control interface
    //! input clock
    input wire logic i_clk,
    input wire logic i_sync_rst, //! input reset signal synchronous to the input clock
    input wire logic i_freeze, //! Freeze directive, which stops all state transitions except for the reset. this signal can be used to flow control by the parent module.
    //! @end
    //! @virtualbus us_side_if @dir in upstream-side interface
    `ifndef COMPILER_MATURITY_LEVEL_0
        input wire T_ELEM [W_I-1:0] i_in_vct, //! input vector
    `else
        input wire logic [W_I-1:0][BW_ELEM-1:0] i_in_vct, //! input vector
    `endif
    input wire logic [$clog2(W_I-W_O+1)-1:0] i_slc_idx, //! Slice index (=: index of slice's first element). This must be in the range of [0, ```W_I-W_O```], otherwise the output will be undefined.
    //! @end
    //! @virtualbus ds_side_if @dir out downstream-side interface
    output wire logic o_out_vld, //! Signal indicating that the output vector is valid. This is **ONLY** for initial garbage data skipping, **NOT** for flow control.
    `ifndef COMPILER_MATURITY_LEVEL_0
        output wire T_ELEM [W_O-1:0] o_out_vct //! output vector
    `else
        output wire logic [W_O-1:0][BW_ELEM-1:0] o_out_vct //! output vector
    `endif
    //! @end
);
// ---------- imports ----------
// --------------------

// ---------- parameters ----------
localparam int unsigned MAX_SHIFT_TIMES = W_I - W_O; //! maximum number of shift times
localparam int unsigned N_SFT_REGS = MAX_SHIFT_TIMES + 1; //! number of shift registers (= latency in cycles)
// --------------------

// ---------- parameter validation ----------
generate
    if (W_O < 1) begin: gen_too_small_W_O
        nonexistent_module_to_throw_a_custom_error_message_for_too_small_W_O inst();
    end
    if (W_I <= W_O) begin: gen_too_large_W_O
        nonexistent_module_to_throw_a_custom_error_message_for_too_large_W_O inst();
    end
endgenerate
// --------------------

// ---------- brief sketch ----------
// --------------------

// ---------- functions ----------
// --------------------

// ---------- signals and storage ----------
`ifdef COMPILER_MATURITY_LEVEL_0
    typedef logic [BW_ELEM-1:0] T_ELEM; //! element data type
`endif

//! shift register element data type
typedef struct packed {
    logic [$clog2(N_SFT_REGS)-1:0] rem_sft; //! remaining shift count
    T_ELEM [W_I-1:0] vec; //! vector of elements
    logic vld; //! valid flag
} sft_reg_elem_t;

var sft_reg_elem_t [N_SFT_REGS-1:0] r_sft_reg; //! shift registers
// --------------------

// ---------- instances ----------
// --------------------

// ---------- Drives output signals. ----------
assign o_out_vld = r_sft_reg[N_SFT_REGS-1].vld;
assign o_out_vct = r_sft_reg[N_SFT_REGS-1].vec[0+:W_O];
// --------------------

// ---------- blocks ----------
//! Updates the 1st shift register.
always_ff @(posedge i_clk) begin: blk_update_1st_sft_reg
    if (i_sync_rst) begin
        r_sft_reg[0] <= '{default:'0};
    end else if (!i_freeze) begin
        r_sft_reg[0].vld <= 1'b1;
        r_sft_reg[0].vec <= i_in_vct;
        r_sft_reg[0].rem_sft <= i_slc_idx;
    end
end

generate
    for (genvar i=1; i<N_SFT_REGS; ++i) begin: gen_update_sft_regs
        //! Updates other shift registers.
        always_ff @(posedge i_clk) begin: blk_update_other_sft_regs
            if (i_sync_rst) begin
                r_sft_reg[i] <= '{default:'0};
            end else if (!i_freeze) begin
                if (r_sft_reg[i-1].rem_sft == '0) begin
                    r_sft_reg[i] <= r_sft_reg[i-1];
                end else begin
                    r_sft_reg[i].vld <= r_sft_reg[i-1].vld;
                    r_sft_reg[i].vec[0+:W_I-1] <= r_sft_reg[i-1].vec[1+:W_I-1];
                    r_sft_reg[i].vec[W_I-1] <= '{default:'0};
                    r_sft_reg[i].rem_sft <= r_sft_reg[i-1].rem_sft - $clog2(N_SFT_REGS)'(1);
                end
            end
        end
    end
endgenerate
// --------------------
endmodule

`default_nettype wire

`endif // SFT_REG_SLC_V0_2_0_SV_INCLUDED
