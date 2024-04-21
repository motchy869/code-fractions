// Verible directive
// verilog_lint: waive-start parameter-name-style

`ifndef AXI4_LITE_IF_PKG_SVH_INCLUDED
`define AXI4_LITE_IF_PKG_SVH_INCLUDED

package axi4_lite_if_pkg;
    typedef enum bit [1:0] {
        AXI4_RESP_OKAY = 2'b00,
        AXI4_RESP_EXOKAY = 2'b01,
        AXI4_RESP_SLVERR = 2'b10,
        AXI4_RESP_DECERR = 2'b11
    } axi4_resp_t;
endpackage

`endif
