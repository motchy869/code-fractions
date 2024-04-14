// Verible directive
// verilog_lint: waive-start parameter-name-style
// verilog_lint: waive-start line-length

`ifndef MY_VERIF_PKG_SVH_INCLUDED
`define MY_VERIF_PKG_SVH_INCLUDED

`include "uvm_macros.svh"

package my_verif_pkg;
    import uvm_pkg::*;

    localparam int AXI4_LITE_ADDR_BIT_WIDTH = 32; //! bit width of AXI4-Lite address bus
    localparam int AXI4_LITE_DATA_BIT_WIDTH = 32; //! bit width of AXI4-Lite data bus

    `include "my_bus_seq_item.svh"
    `include "my_reg_model.svh"

    `include "my_reg_adapter.svh"
    `include "my_reg_env.svh"
endpackage

`endif
