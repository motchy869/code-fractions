// Verible directive
// verilog_lint: waive-start parameter-name-style
// verilog_lint: waive-start line-length

`default_nettype none

//! Creates a sawtooth waveform.
//!
//! Features not implemented yet:
//! - convergence rounding of output values
extern module sawtooth_wav_gen #(
    parameter int unsigned BIT_WIDTH__OUTPUT = 8, //! output bit width
    parameter int unsigned BIT_WIDTH__INT_PART__PERIOD = 4, //! bit width of the integer part of the period input
    parameter int unsigned BIT_WIDTH__FRAC_PART__PERIOD = 4, //! bit width of the fractional part of the period input
    parameter int unsigned SSR = 4 //! Super Sample Rate
)(
    input wire logic i_clk, //! input clock
    input wire logic i_sync_rst, //! input reset signal synchronous to the input clock
    //! @virtualbus cfg_if @dir in configuration interface
    input wire logic signed [BIT_WIDTH__OUTPUT-1:0] i_start_val, //! start value
    input wire logic signed [BIT_WIDTH__OUTPUT-1:0] i_end_val, //! end value
    input wire logic [BIT_WIDTH__INT_PART__PERIOD-1:0] i_int_part__period, //! Integer part of the period (relative to sample period).
    input wire logic [BIT_WIDTH__FRAC_PART__PERIOD-1:0] i_frac_part__period, //! Fractional part of the period (relative to sample period). The resulting physical period is ```(i_int_part__period + i_frac_part__period/(1<<B_F))*T_clk/SSR``` where ```T_clk``` is the period in second of the input clock and ```B_F``` is ```BIT_WIDTH__FRAC_PART__PERIOD```.
    //! @end
    //! @virtualbus ds_side_if @dir out downstream side interface
    //! input ready signal which indicates that the downstream side is ready to accept a new chunk
    input wire logic i_ds_ready,
    output wire logic o_chunk_valid, //! output valid signal which indicates that the output chunk is valid
    output wire logic [SSR-1:0][BIT_WIDTH__OUTPUT-1:0] o_chunk_data //! output chunk data
    //! @end
);

`default_nettype wire
