// Verible directive
// verilog_lint: waive-start parameter-name-style
// verilog_lint: waive-start line-length

`default_nettype none

//! Complex number adder/subtractor
module cplx_add #(
    parameter type in_cplx_t, //! input complex number type
    parameter type out_cplx_t //! output complex number type
)(
    input wire logic i_clk, //! clock signal
    input wire logic i_sync_rst, //! reset signal synchronous to clock

    output wire logic o_ready, //! ready signal to upstream side which indicates that the upstream side is allowed to update input data (to this module) right AFTER the next rising edge of the clock
    input wire logic i_input_valid, //! Valid signal from upstream side. This is also used as freezing signal like clock-enable deassertion. When this is low, the module internal state is frozen.
    input in_cplx_t i_a, //! first complex number a
    input in_cplx_t i_b, //! second complex number b
    input wire logic i_sub, //! Add/subtract dynamic control signal. 0/1: add/subtract. If this signal is compile-time constant, the synthesis tool will optimize-out the unused logics.

    input wire logic i_ds_ready, //! ready signal from downstream side which indicates that this module is allowed to update input data (to downstream side) right AFTER the next rising edge of the clock
    output wire logic o_output_valid, //! output valid signal
    output out_cplx_t o_c //! a+b or a-b
);
// ---------- parameters ----------
localparam int unsigned CYCLE_LAT = 1;
// --------------------

// ---------- parameter validation ----------
// --------------------

// ---------- functions ----------
// --------------------

// ---------- signals and storage ----------
var logic [CYCLE_LAT-1:0] r_vld_dly_line; //! delay line for the output valid signal
wire g_can_adv_pip_ln; //! signal indicating that the pipeline can advance
assign g_can_adv_pip_ln = !r_vld_dly_line[CYCLE_LAT-1] || i_ds_ready;
wire g_adv_pip_ln; //! signal indicating that the pipeline should advance
assign g_adv_pip_ln = i_input_valid & g_can_adv_pip_ln;

var out_cplx_t r_c; //! a+b or a-b
// --------------------

// ---------- instances ----------
// --------------------

// ---------- Drives output signals. ----------
assign o_ready = g_can_adv_pip_ln;
assign o_output_valid = i_input_valid & r_vld_dly_line[CYCLE_LAT-1];
assign o_c = r_c;
// --------------------

// ---------- blocks ----------
//! Updates valid delay line.
always_ff @(posedge i_clk) begin: blk_update_vld_dly_line
    if (i_sync_rst) begin
        r_vld_dly_line <= '0;
    end else if (g_adv_pip_ln) begin
        r_vld_dly_line <= {r_vld_dly_line[CYCLE_LAT-1:0], 1'b1};
    end
end

//! Updates the output complex number.
always_ff @(posedge i_clk) begin: blk_update_output
    if (i_sync_rst) begin
        r_c.re <= '0;
        r_c.im <= '0;
    end else if (g_adv_pip_ln) begin
        if (i_sub) begin
            r_c.re <= i_a.re - i_b.re;
            r_c.im <= i_a.im - i_b.im;
        end else begin
            r_c.re <= i_a.re + i_b.re;
            r_c.im <= i_a.im + i_b.im;
        end
    end
end
// --------------------
endmodule

`default_nettype wire
