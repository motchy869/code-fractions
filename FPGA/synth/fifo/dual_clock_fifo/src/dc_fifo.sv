// Verible directives
// verilog_lint: waive-start parameter-name-style
// verilog_lint: waive-start line-length

`default_nettype none

//! FWFT dual-clock FIFO
//! THIS MODULE IS NOT COMPLETED.
module dc_fifo #(
    parameter type T = logic, //! data type
    parameter int unsigned EXP_DEPTH = 3 //! The exponential part of the depth of the FIFO. The depth is 2^EXP_DEPTH.
)(
    //! @virtualbus us_side_if @dir in upstream-side interface
    input wire logic i_us_clk, //! upstream-side clock signal
    input wire logic i_us_sync_rst, //! upstream-side synchronous reset signal
    input wire logic i_us_data_valid, //! upstream-side data valid signal
    input wire T i_us_data, //! upstream-side input data
    output wire logic o_us_ready, //! A ready signal to upstream. **masked by** `i_us_sync_rst` (to avoid losing data at transition to reset state).
    //! @end
    //! @virtualbus ds_side_if @dir in downstream-side interface
    input wire logic i_ds_clk, //! downstream-side clock signal
    input wire logic i_ds_sync_rst, //! downstream-side synchronous reset signal
    input wire logic i_ds_ready, //! ready signal from downstream
    output wire T o_ds_data, //! data to downstream
    output wire logic o_ds_valid //! valid signal to downstream
    //! @end
);
// ---------- parameters ----------
typedef int unsigned uint_t;

localparam uint_t DEPTH = 1 << EXP_DEPTH; //! depth of the FIFO
localparam uint_t BW_PTR = EXP_DEPTH+1; //! Bit width of read and write pointers. MSB is used for the cyclic phase to distinguish between empty and full states.
// --------------------

// ---------- parameter validation ----------
// TODO: Maybe the check for EXP_DEPTH is needed.
// --------------------

// ---------- functions ----------
// --------------------

// ---------- signals and storage ----------
var T r_mam[DEPTH]; //! FIFO storage
// --------------------

// ---------- instances ----------
// --------------------

// ---------- Drives output signals. ----------
// --------------------

// ---------- blocks ----------
// --------------------
endmodule

`default_nettype wire
