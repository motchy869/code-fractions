// verilog_lint: waive-start parameter-name-style
// verilog_lint: waive-start line-length

`ifndef MTY_SV_UTIL_FUNCS_PKG_SVH_INCLUDED
`define MTY_SV_UTIL_FUNCS_PKG_SVH_INCLUDED

//! motchy's SystemVerilog utility functions
//!
//! This package includes some classes to realize parametrized functions.
//! Not all synthesis tools are expected to be able to synthesize them, but recent Vivado can.
//! See the following web pages for details:
//! - [Systemverilog synthesis class support](https://support.xilinx.com/s/question/0D52E00006hpQ4oSAE/systemverilog-synthesis-class-support?language=en_US&t=1719056710739)
//! - [VeCheck](https://github.com/saturn77/VeCheck)
package mty_sv_util_funcs_pkg;
    // Provides various math functions.
    class Math #(
        parameter type T = int // data type
    );
        // Calculate the absolute value of a given number.
        // T is assumed to be signed.
        static function automatic T abs(T val);
            return (val < 0) ? -val : val;
        endfunction

        // Clip a given number to a specified range.
        // T is assumed to be signed.
        // Vivado 2024.1.1 SILENTLY fails to synthesize this function (due to class) and generates 0 output!
        static function automatic T clip(T val, T min_val, T max_val);
            return (val < min_val) ? min_val : ((val > max_val) ? max_val : val);
        endfunction

        // A class providing rounding functions.
        // T is assumed to be signed.
        // Vivado 2024.1.1 SILENTLY fails to synthesize this function (due to class) and generates 0 output!
        class Rounding #(
            parameter int N_F = 1 // The number of fractional bits. N_F LSBs are treated as fractional bits.
        );
            // rounding half to even
            static function automatic T round_hf_even(T val);
                localparam int N = $bits(val); // the number of bits of val
                localparam int N_I = N - N_F; // the number of integer bits
                localparam logic [N_F-1:0] FRAC_PART_ZP5 = {1'b1, {(N_F-1){1'b0}}}; // 0.5
                const logic [N_I-1:0] int_part = val[N-1:N_F];
                const logic int_part_is_max = (int_part == {1'b0, {(N_I-1){1'b1}}});
                const logic [N_F-1:0] frac_part = val[N_F-1:0];
                const logic frac_part_is_0 = (frac_part == '0);
                const logic frac_part_is_0p5 = (frac_part == FRAC_PART_ZP5);
                if (N_F < 1) begin
                    $fatal(2, "N_F must be greater than or equal to 1.");
                end
                if (N < N_F+2) begin
                    $fatal(2, "The bit width of val must be greater than or equal to N_F+2.");
                end
                if (frac_part_is_0) begin
                    return val;
                end else begin
                    // Note that the sign doesn't matter (except for clipping).
                    // For example, val = -2.3, the integer and fractional parts obtained from bit slice are -3 and 0.7 respectively.
                    // The fractional part always fall into the range [0, 1).
                    if (frac_part_is_0p5) begin
                        return {int_part + (!int_part_is_max && int_part[0]), {N_F{1'b0}}};
                    end else begin
                        // Note that at this point the fractional part is neither 0 nor 0.5.
                        return {int_part + (!int_part_is_max && frac_part[N_F-1]), {N_F{1'b0}}};
                    end
                end
            endfunction
        endclass
    endclass

    // Provides various data structure operations.
    class DataStructOps #(
        parameter type T = logic // **packed** data type
    );
        class Shift #(
            parameter int unsigned L = 8 // vector length
        );
            // Circular right shift
            static function automatic T [L-1:0] circ_right_shift(
                input T [L-1:0] vec, // input vector
                input logic [$clog2(L+1)-1:0] s // shift amount, clipped to [0, L-1]
            );
                localparam int unsigned BIT_WIDTH_S = $clog2(L+1);
                localparam int unsigned BIT_WIDTH_IDX = $clog2(L);
                automatic logic [BIT_WIDTH_S-1:0] s_clp = (s < L) ? s : BIT_WIDTH_S'(L-1);
                automatic T [L-1:0] result;

                for (int unsigned i=0; i<L; i++) begin
                    localparam int unsigned BIT_WIDTH_NAIVE_IDX = BIT_WIDTH_IDX+1;
                    automatic logic [BIT_WIDTH_NAIVE_IDX-1:0] naive_idx = BIT_WIDTH_NAIVE_IDX'(i) + BIT_WIDTH_NAIVE_IDX'(s_clp);
                    if (naive_idx < BIT_WIDTH_NAIVE_IDX'(L)) begin
                        result[i] = vec[BIT_WIDTH_IDX'(naive_idx)];
                    end else begin
                        result[i] = vec[BIT_WIDTH_IDX'(naive_idx - BIT_WIDTH_NAIVE_IDX'(L))];
                    end
                end
                return result;
            endfunction
        endclass
    endclass

    // Calculate the number of bits required to represent a given number.
    function automatic int bitWidthOfSignedInt(int n);
        const int abs_n = (n < 0) ? -n : n;
        return $clog2(abs_n) + int'($onehot(abs_n)) + 1; // +1 is for positive number case
    endfunction
endpackage

`endif // MTY_SV_UTIL_FUNCS_PKG_SVH_INCLUDED
