// Verible directive
// verilog_lint: waive-start parameter-name-style

`ifndef MY_VERIF_PARAMS_PKG_SVH_INCLUDED
`define MY_VERIF_PARAMS_PKG_SVH_INCLUDED

package my_verif_params_pkg;
    localparam int AXI4_LITE_ADDR_BIT_WIDTH = 32; //! bit width of AXI4-Lite address bus
    localparam int AXI4_LITE_DATA_BIT_WIDTH = 32; //! bit width of AXI4-Lite data bus
endpackage

`endif
