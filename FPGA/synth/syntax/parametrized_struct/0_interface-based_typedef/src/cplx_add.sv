// Verible directive
// verilog_lint: waive-start parameter-name-style
// verilog_lint: waive-start line-length

`include "cplx_num_if.svh"

`default_nettype none

//! Complex number adder/subtractor
module cplx_add (
    input wire logic i_clk, //! clock signal
    input wire logic i_sync_rst, //! reset signal synchronous to clock

    output wire logic o_ready, //! ready signal to upstream side which indicates that the upstream side is allowed to update input data (to this module) right AFTER the next rising edge of the clock
    input wire logic i_input_valid, //! Valid signal from upstream side. This is also used as freezing signal like clock-enable deassertion. When this is low, the module internal state is frozen.
    cplx_num_if.agt_pt agt_pt_cplx_a, //! first complex number a
    cplx_num_if.agt_pt agt_pt_cplx_b, //! second complex number b
    input wire logic i_sub, //! Add/subtract dynamic control signal. 0/1: add/subtract. If this signal is compile-time constant, the synthesis tool will optimize-out the unused logics.

    input wire logic i_ds_ready, //! ready signal from downstream side which indicates that this module is allowed to update output data (to downstream side) right AFTER the next rising edge of the clock
    output wire logic o_output_valid, //! output valid signal
    cplx_num_if.hst_pt hst_pt_cplx_c //! a+b or a-b
);
// ---------- parameters ----------
localparam int unsigned CYCLE_LAT = 1;
// --------------------

// ---------- parameter validation ----------
generate
    if ($bits(agt_pt_cplx_a.complex_t.re) != $bits(agt_pt_cplx_b.complex_t.re)) begin: gen_validate_real_part_bit_width
        nonexistent_module_to_throw_a_custom_error_message_for_invalid_real_part_bit_width inst();
    end

    if ($bits(agt_pt_cplx_a.complex_t.im) != $bits(agt_pt_cplx_b.complex_t.im)) begin: gen_validate_imaginary_part_bit_width
        nonexistent_module_to_throw_a_custom_error_message_for_invalid_imaginary_part_bit_width inst();
    end
endgenerate
// --------------------

// ---------- functions ----------
// --------------------

// ---------- signals and storage ----------
typedef agt_pt_cplx_a.complex_t in_complex_t;
typedef hst_pt_cplx_c.complex_t out_complex_t;

var logic [CYCLE_LAT-1:0] r_vld_dly_line; //! delay line for the output valid signal
wire g_can_adv_pip_ln; //! signal indicating that the pipeline can advance
assign g_can_adv_pip_ln = !r_vld_dly_line[CYCLE_LAT-1] || i_ds_ready;
wire g_adv_pip_ln; //! signal indicating that the pipeline should advance
assign g_adv_pip_ln = i_input_valid & g_can_adv_pip_ln;

var out_complex_t r_c; //! a+b or a-b
// --------------------

// ---------- instances ----------
// --------------------

// ---------- Drives output signals. ----------
assign o_ready = g_can_adv_pip_ln;
assign o_output_valid = i_input_valid & r_vld_dly_line[CYCLE_LAT-1];
assign hst_pt_cplx_c.num = r_c;
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
            r_c.re <= agt_pt_cplx_a.num.re - agt_pt_cplx_b.num.re;
            r_c.im <= agt_pt_cplx_a.num.im - agt_pt_cplx_b.num.im;
        end else begin
            r_c.re <= agt_pt_cplx_a.num.re + agt_pt_cplx_b.num.re;
            r_c.im <= agt_pt_cplx_a.num.im + agt_pt_cplx_b.num.im;
        end
    end
end
// --------------------
endmodule

`default_nettype wire
