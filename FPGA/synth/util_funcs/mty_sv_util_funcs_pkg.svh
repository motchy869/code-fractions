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
        parameter type T // data type
    );
        // Calculate the absolute value of a given number.
        static function automatic T abs(T val);
            return (val < 0) ? -val : val;
        endfunction

        // Clip a given number to a specified range.
        static function automatic T clip(T val, T min_val, T max_val);
            return (val < min_val) ? min_val : ((val > max_val) ? max_val : val);
        endfunction
    endclass

    // Calculate the number of bits required to represent a given number.
    function automatic int bitWidthOfSignedInt(int n);
        const int abs_n = (n < 0) ? -n : n;
        return $clog2(abs_n) + $onehot(abs_n) + 1; // +1 is for positive number case
    endfunction
endpackage

`endif // MTY_SV_UTIL_FUNCS_PKG_SVH_INCLUDED
