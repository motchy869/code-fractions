// Verible directive
// verilog_lint: waive-start parameter-name-style
// verilog_lint: waive-start line-length

`include "mty_sv_macros.svh"

`default_nettype none

//! Creates a sawtooth waveform with SSR >= 1.
//! The period can be specified in fixed-point number format.
//!
//! Features not implemented yet:
//! - convergence rounding of output values
module sawtooth_wav_gen #(
    parameter int unsigned BIT_WIDTH__OUTPUT = 8, //! output bit width
    parameter int unsigned BIT_WIDTH__INT_PART__PERIOD = 4, //! bit width of the integer part of the period input
    parameter int unsigned BIT_WIDTH__FRAC_PART__PERIOD = 4, //! bit width of the fractional part of the period input
    parameter int unsigned SSR = 4 //! Super Sample Rate
)(
    input wire logic i_clk, //! input clock
    input wire logic i_sync_rst, //! input reset synchronous to the input clock
    //! @virtualbus cfg_if @dir in configuration interface
    input wire logic signed [BIT_WIDTH__OUTPUT-1:0] i_start_val, //! the value at the start of the period (inclusive)
    input wire logic signed [BIT_WIDTH__OUTPUT-1:0] i_end_val, //! the value at the end of the period (**exclusive**)
    input wire logic [BIT_WIDTH__INT_PART__PERIOD-1:0] i_int_part__period, //! Integer part of the period (relative to sample period).
    input wire logic [BIT_WIDTH__FRAC_PART__PERIOD-1:0] i_frac_part__period, //! Fractional part of the period. The resulting physical period is ```(i_int_part__period + i_frac_part__period/(1<<B_F))*T_clk/SSR``` where ```T_clk``` is the period in second of the input clock and ```B_F``` is ```BIT_WIDTH__FRAC_PART__PERIOD```.
    //! @end
    //! @virtualbus ds_side_if @dir out downstream side interface
    //! input ready signal which indicates that the downstream side is ready to accept a new chunk
    input wire logic i_ds_ready,
    output wire logic o_chunk_valid, //! output valid signal which indicates that the output chunk is valid
    output wire logic [SSR-1:0][BIT_WIDTH__OUTPUT-1:0] o_chunk_data //! output chunk data
    //! @end
);
// ---------- parameters ----------
localparam int unsigned LEN__PIPELINE__MODULO = 4; //! length of pipeline stages for modulo operation
localparam int unsigned UPPER_LIM__INT_PART__PERIOD = 1 << BIT_WIDTH__INT_PART__PERIOD; //! upper limit of the integer part of the period
localparam int unsigned MAX__INT_PART__ELEM_EPHEMERAL_IDX = `LARGER_ONE(SSR, (UPPER_LIM__INT_PART__PERIOD + SSR - 1)/SSR*SSR) + (LEN__PIPELINE__MODULO+1)*SSR; //! maximum of the integer part of element ephemeral index. This is enough to utilize the modulo operation result.
localparam int unsigned WRAP_THRESHOLD__INT_PART__ELEM_EPHEMERAL_IDX = MAX__INT_PART__ELEM_EPHEMERAL_IDX - SSR; //! threshold to wrap the element ephemeral index
localparam int unsigned BIT_WIDTH__MAX__INT_PART__ELEM_EPHEMERAL_IDX = $clog2(MAX__INT_PART__ELEM_EPHEMERAL_IDX); //! bit width of the capacity of the integer part of element ephemeral index

localparam int unsigned LEN__PIPELINE__MULT__BETA = 2; //! length of pipeline stages for multiplication operation of beta (described later in the DSP pipeline flow)
localparam int unsigned LEN__PIPELINE__DIV__GAMMA = 4; //! length of pipeline stages for division operation of gamma (described later in the DSP pipeline flow)
localparam int unsigned CYCLE_LATENCY = LEN__PIPELINE__MODULO + LEN__PIPELINE__MULT__BETA + LEN__PIPELINE__DIV__GAMMA; //! cycle latency of this module
// --------------------

// ---------- parameter validation ----------
// --------------------

// ---------- functions ----------
// --------------------

// ---------- signals and storage ----------
// fixed-point number type mainly used for element ephemeral indexes
typedef struct packed {
    logic [BIT_WIDTH__MAX__INT_PART__ELEM_EPHEMERAL_IDX-1:0] int_part;
    logic [BIT_WIDTH__FRAC_PART__PERIOD-1:0] frac_part;
} fxd_pnt_t;

var fxd_pnt_t [SSR-1:0] r_elem_ephemeral_idxes; //! Element ephemeral indexes. Each index wraps to the remainder of the itself divided by the period before overflow occurs.
var fxd_pnt_t [LEN__PIPELINE__MODULO-1:0][SSR-1:0] r_rem__elem_ephemeral_idxes; //! remainders of the element ephemeral indexes divided by the period

// DSP pipeline flow:
// for i = 0 to SSR-1:
//   r_alpha <= (i_end_val - i_start_val)
//   r_beta[0][i] <= r_alpha*r_rem__elem_ephemeral_idxes[LEN__PIPELINE__MODULO-1][i]
//   r_beta[$left(r_beta):1] <= {r_beta[$left(r_beta)-1:0], r_beta[0]}
//   r_gamma[0][i] <= r_beta[r_beta[$left(r_beta)][i]/{i_int_part__period, i_frac_part__period}
//   r_gamma[$left(r_gamma):1] <= {r_gamma[$left(r_gamma)-1:0], r_gamma[0]}

var logic signed [BIT_WIDTH__OUTPUT-1:0] r_alpha; //! difference between the start and end values
var logic [LEN__PIPELINE__MULT__BETA-1:0][SSR-1:0][BIT_WIDTH__OUTPUT + BIT_WIDTH__MAX__INT_PART__ELEM_EPHEMERAL_IDX + BIT_WIDTH__FRAC_PART__PERIOD - 1:0] r_beta; //! intermediate values for multiplication operation
var logic [LEN__PIPELINE__DIV__GAMMA-1:0][SSR-1:0][BIT_WIDTH__OUTPUT + BIT_WIDTH__MAX__INT_PART__ELEM_EPHEMERAL_IDX + BIT_WIDTH__FRAC_PART__PERIOD - 1:0] r_gamma; //! intermediate values for division operation

var logic [CYCLE_LATENCY-1:0] r_vld_dly_line; //! delay line for the output valid signal
// --------------------

// ---------- instances ----------
// --------------------

// ---------- Drive output signals. ----------
assign o_chunk_valid = r_vld_dly_line[CYCLE_LATENCY-1];
generate
    genvar i;
    for (i=0; i<SSR; ++i) begin: gen_assign_output_chunk_data
        assign o_chunk_data[i] = r_gamma[LEN__PIPELINE__DIV__GAMMA-1][i][BIT_WIDTH__OUTPUT-1:0];
    end
endgenerate
// --------------------

// ---------- blocks ----------
//! Updates the remainders of the element ephemeral indexes divided by the period.
always_ff @(posedge i_clk) begin: blk_update_rem__elem_ephemeral_idxes
    if (i_sync_rst) begin
        r_rem__elem_ephemeral_idxes <= '0;
    end else if (i_ds_ready) begin
        // modulo operation
        for (int unsigned i=0; i<SSR; ++i) begin
            r_rem__elem_ephemeral_idxes[0][i] <= r_elem_ephemeral_idxes[i] % {i_int_part__period, i_frac_part__period};
        end

        // pipeline update
        for (int unsigned i=1; i<LEN__PIPELINE__MODULO; ++i) begin
            r_rem__elem_ephemeral_idxes[i] <= r_rem__elem_ephemeral_idxes[i-1];
        end
    end
end

//! Updates the element ephemeral indexes.
always_ff @(posedge i_clk) begin: blk_update_elem_ephemeral_idxes
    if (i_sync_rst) begin
        for (int unsigned i=0; i<SSR; ++i) begin
            r_elem_ephemeral_idxes[i].int_part <= BIT_WIDTH__MAX__INT_PART__ELEM_EPHEMERAL_IDX'(i);
            r_elem_ephemeral_idxes[i].frac_part <= '0;
        end
    end else if (i_ds_ready) begin
        for (int unsigned i=0; i<SSR; ++i) begin
            if (r_elem_ephemeral_idxes[i].int_part < WRAP_THRESHOLD__INT_PART__ELEM_EPHEMERAL_IDX) begin
                r_elem_ephemeral_idxes[i].int_part <= r_elem_ephemeral_idxes[i].int_part + BIT_WIDTH__MAX__INT_PART__ELEM_EPHEMERAL_IDX'(SSR);
            end else begin
                r_elem_ephemeral_idxes[i] <= r_rem__elem_ephemeral_idxes[LEN__PIPELINE__MODULO-1][i] + (BIT_WIDTH__MAX__INT_PART__ELEM_EPHEMERAL_IDX + BIT_WIDTH__FRAC_PART__PERIOD)'((LEN__PIPELINE__MODULO*SSR) << BIT_WIDTH__FRAC_PART__PERIOD);
            end
        end
    end
end

//! Updates alpha.
always_ff @(posedge i_clk) begin: blk_update_alpha
    if (i_sync_rst) begin
        r_alpha <= '0;
    end else if (i_ds_ready) begin
        r_alpha <= i_end_val - i_start_val;
    end
end

//! Updates beta.
always_ff @(posedge i_clk) begin: blk_update_beta
    if (i_sync_rst) begin
        r_beta <= '0;
    end else if (i_ds_ready) begin
        // multiplication operation
        for (int unsigned i=0; i<SSR; ++i) begin
            r_beta[0][i] <= r_alpha * r_rem__elem_ephemeral_idxes[LEN__PIPELINE__MODULO-1][i];
        end

        // pipeline update
        for (int unsigned i=1; i<LEN__PIPELINE__MULT__BETA; ++i) begin
            r_beta[i] <= r_beta[i-1];
        end
    end
end

//! Updates gamma.
always_ff @(posedge i_clk) begin: blk_update_gamma
    if (i_sync_rst) begin
        r_gamma <= '0;
    end else if (i_ds_ready) begin
        // division operation
        for (int unsigned i=0; i<SSR; ++i) begin
            r_gamma[0][i] <= r_beta[LEN__PIPELINE__MULT__BETA-1][i] / {i_int_part__period, i_frac_part__period};
        end

        // pipeline update
        for (int unsigned i=1; i<LEN__PIPELINE__DIV__GAMMA; ++i) begin
            r_gamma[i] <= r_gamma[i-1];
        end
    end
end

//! Updates the valid delay line.
always_ff @(posedge i_clk) begin: blk_update_vld_dly_line
    if (i_sync_rst) begin
        r_vld_dly_line <= '0;
    end else if (i_ds_ready) begin
        r_vld_dly_line <= {r_vld_dly_line[CYCLE_LATENCY-2:0], 1'b1};
    end
end
// --------------------
endmodule

`default_nettype wire
