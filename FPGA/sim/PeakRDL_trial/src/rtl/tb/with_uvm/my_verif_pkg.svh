`ifndef MY_VERIF_PKG_SVH_INCLUDED
`define MY_VERIF_PKG_SVH_INCLUDED

// Verible directive
// verilog_lint: waive-start line-length
// verilog_lint: waive-start parameter-name-style

`define INCLUDED_FROM_MY_VERIF_PKG

`include "../../axi4_lite_if.svh"
`include "uvm_macros.svh"

package my_verif_pkg;
    parameter int CLK_PERIOD_NS = 8; //! Clock period in ns

    localparam int CSR_ADDR_SPACE_SIZE_BYTE = 'h40; //! size of CSR address space in byte
    localparam int AXI4_LITE_ADDR_BIT_WIDTH = $clog2(CSR_ADDR_SPACE_SIZE_BYTE); //! bit width of AXI4-Lite address bus
    localparam int AXI4_LITE_DATA_BIT_WIDTH = 32; //! bit width of AXI4-Lite data bus

    typedef virtual axi4_lite_if #(
        .ADDR_BIT_WIDTH(my_verif_pkg::AXI4_LITE_ADDR_BIT_WIDTH),
        .DATA_BIT_WIDTH(my_verif_pkg::AXI4_LITE_DATA_BIT_WIDTH)
    ) bus_vif_t;

    import uvm_pkg::*;

    // Line blocks with no blank lines indicates there is no dependency.
    // Blank lines indicates dependency.
    `include "./bus/my_bus_seq_item.svh"
    `include "./bus/my_bus_collected_item.svh"

    `include "./bus/my_bus_driver.svh"
    `include "./bus/my_bus_collector.svh"
    `include "./bus/my_bus_monitor.svh"

    `include "./bus/my_bus_agent.svh"
endpackage

`endif
