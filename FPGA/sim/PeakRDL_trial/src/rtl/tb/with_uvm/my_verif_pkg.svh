`ifndef MY_VERIF_PKG_SVH_INCLUDED
`define MY_VERIF_PKG_SVH_INCLUDED

// Verible directive
// verilog_lint: waive-start line-length
// verilog_lint: waive-start parameter-name-style

`define INCLUDED_FROM_MY_VERIF_PKG

`include "rt_sig/my_rt_sig_if.svh"
`include "../../axi4_lite_if.svh"
`include "../../csr/my_mod_csr_uvm_reg_model_pkg.svh"
`include "uvm_macros.svh"

package my_verif_pkg;
    localparam int CLK_PERIOD_NS = 8; //! Clock period in ns
    localparam int CLK_PHASE_OFFSET_NS = CLK_PERIOD_NS/2; //! Clock phase offset in ns

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
    `include "./rt_sig/my_rt_sig_seq_item.svh"
    `include "./bus/my_bus_seq_item.svh"
    `include "./bus/my_bus_collected_item.svh"
    `include "./seq/my_reset_seq.svh"
    `include "./seq/my_rt_sig_drv_shutdown_seq.svh"
    `include "./seq/my_bus_drv_shutdown_seq.svh"

    `include "./rt_sig/my_rt_sig_driver.svh"
    `include "./bus/my_bus_driver.svh"
    `include "./bus/my_bus_collector.svh"
    `include "./bus/my_bus_monitor.svh"
    `include "./reg/my_reg_adapter.svh"

    `include "./rt_sig/my_rt_sig_agent.svh"
    `include "./bus/my_bus_agent.svh"
    `include "./reg/my_reg_env.svh"

    `include "my_env.svh"

    `include "./test/my_base_test.svh"

    `include "./test/my_test.svh"
endpackage

`endif
