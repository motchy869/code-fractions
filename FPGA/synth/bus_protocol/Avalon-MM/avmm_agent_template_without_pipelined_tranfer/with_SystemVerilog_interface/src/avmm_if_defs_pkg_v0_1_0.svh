`ifndef AVMM_IF_DEFS_PKG_V0_1_0_SVH_INCLUDED
`define AVMM_IF_DEFS_PKG_V0_1_0_SVH_INCLUDED

// Verible directive
// verilog_lint: waive-start parameter-name-style
// verilog_lint: waive-start line-length

//! package for definitions used in Avalon Memory-Mapped Interface
package avmm_if_defs_pkg_v0_1_0;
    //! Avalon MM response type
    typedef enum logic [1:0] {
        AVMM_RESP_OKAY = 2'b00,
        AVMM_RESP_RESERVED = 2'b01,
        AVMM_RESP_SLVERR = 2'b10,
        AVMM_RESP_DECODEERROR = 2'b11
    } avmm_resp_t;
endpackage

`endif // AVMM_IF_DEFS_PKG_V0_1_0_SVH_INCLUDED
