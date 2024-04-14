// Verible directive
// verilog_lint: waive-start line-length
// verilog_lint: waive-start parameter-name-style

`ifndef MY_REG_MODEL_PKG_SVH_INCLUDED
`define MY_REG_MODEL_PKG_SVH_INCLUDED

`include "my_verif_pkg.svh"

package my_reg_model_pkg;
    localparam int REG_BIT_WIDTH = my_verif_pkg::AXI4_LITE_DATA_BIT_WIDTH; //! bit width of the register
    localparam int REG_SIZE_BYTE = REG_BIT_WIDTH / 8; //! size of the register in byte
endpackage

`endif
