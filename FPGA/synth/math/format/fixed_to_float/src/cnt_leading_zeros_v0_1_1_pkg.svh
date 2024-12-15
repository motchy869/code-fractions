`ifndef CNT_LEADING_ZEROS_V0_1_1_PKG_SVH_INCLUDED
`define CNT_LEADING_ZEROS_V0_1_1_PKG_SVH_INCLUDED

// Verible directive
// verilog_lint: waive-start parameter-name-style
// verilog_lint: waive-start line-length

//! utility functions for cnt_leading_zeros_v0_1_1 module
package cnt_leading_zeros_v0_1_1_pkg;
    // Calculates the module's cycle latency according to the given parameters.
    function automatic int unsigned cycle_latency(
        input int unsigned INPUT_REG_CHAIN_LEN, // shown in the module document
        input int unsigned OUTPUT_REG_CHAIN_LEN // shown in the module document
    );
        return INPUT_REG_CHAIN_LEN + 1 + OUTPUT_REG_CHAIN_LEN;
    endfunction
endpackage

`endif
