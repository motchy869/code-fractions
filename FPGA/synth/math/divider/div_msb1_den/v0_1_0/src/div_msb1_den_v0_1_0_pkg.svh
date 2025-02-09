// Verible directive
// verilog_lint: waive-start parameter-name-style
// verilog_lint: waive-start line-length

`ifndef DIV_MSB1_DEN_V0_1_0_SVH_INCLUDED
`define DIV_MSB1_DEN_V0_1_0_SVH_INCLUDED

package div_msb1_den_v0_1_0_pkg;
    //! Calculates the latency in clock cycle
    function automatic int unsigned lat_cyc(
        input int unsigned BW_NUM, //! bit width of the numerator
        input int unsigned BW_DEN //! bit width of the denominator
    );
        return BW_NUM - BW_DEN + 1;
    endfunction
endpackage

`endif // DIV_MSB1_DEN_V0_1_0_SVH_INCLUDED
