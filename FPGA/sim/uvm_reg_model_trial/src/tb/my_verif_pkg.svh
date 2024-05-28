// Verible directive
// verilog_lint: waive-start parameter-name-style
// verilog_lint: waive-start line-length

`define INCLUDED_FROM_MY_VERIF_PKG

`include "my_verif_params_pkg.svh"
`include "rt_sig/my_rt_sig_if.svh"
`include "../axi4_lite_if.svh"
`include "../axi4_lite_if_pkg.svh"
`include "uvm_macros.svh"

package my_verif_pkg;
    import uvm_pkg::*;

    typedef virtual axi4_lite_if #(
        .ADDR_BIT_WIDTH(my_verif_params_pkg::AXI4_LITE_ADDR_BIT_WIDTH),
        .DATA_BIT_WIDTH(my_verif_params_pkg::AXI4_LITE_DATA_BIT_WIDTH)
    ) bus_vif_t;

    // Line blocks with no blank lines indicates there is no dependency.
    // Blank lines indicates dependency.
    `include "./rt_sig/my_rt_sig_seq_item.svh"
    `include "./bus/my_bus_seq_item.svh"
    `include "./rt_sig/my_rt_sig_collected_item.svh"
    `include "./bus/my_bus_collected_item.svh"
    `include "./seq/my_reset_seq.svh"
    `include "./seq/my_rt_sig_seq.svh"
    `include "./seq/my_rt_sig_drv_shutdown_seq.svh"
    `include "./seq/my_bus_drv_shutdown_seq.svh"
    `include "./reg/my_reg_model.svh"

    `include "./rt_sig/my_rt_sig_driver.svh"
    `include "./bus/my_bus_driver.svh"
    `include "./rt_sig/my_rt_sig_collector.svh"
    `include "./bus/my_bus_collector.svh"
    `include "./rt_sig/my_rt_sig_monitor.svh"
    `include "./bus/my_bus_monitor.svh"
    `include "./reg/my_reg_adapter.svh"

    `include "./rt_sig/my_rt_sig_agent.svh"
    `include "./bus/my_bus_agent.svh"
    `include "./reg/my_reg_env.svh"

    `include "my_env.svh"

    `include "./test/my_base_test.svh"

    `include "./test/my_test.svh"
endpackage
