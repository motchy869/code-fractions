// Verible directive
// verilog_lint: waive-start parameter-name-style
// verilog_lint: waive-start line-length

`ifndef MY_VERIF_PKG_SVH_INCLUDED
`define MY_VERIF_PKG_SVH_INCLUDED

`include "uvm_macros.svh"

package my_verif_pkg;
    import uvm_pkg::*;

    // Line blocks with no blank lines indicates there is no dependency.
    // Blank lines indicates dependency.
    `include "./rt_sig/my_rt_sig_seq_item.svh"
    `include "./reg/my_reg_model.svh"
    `include "./bus/my_bus_seq_item.svh"

    `include "./rt_sig/my_rt_sig_driver.svh"
    `include "./reg/my_reg_adapter.svh"
    `include "./bus/my_bus_driver.svh"
    `include "./rt_sig/my_rt_sig_collected_item.svh"
    `include "./bus/my_bus_collected_item.svh"

    `include "./rt_sig/my_rt_sig_collector.svh"
    `include "./reg/my_reg_env.svh"
    `include "./bus/my_bus_collector.svh"

    `include "./rt_sig/my_rt_sig_monitor.svh"
    `include "./bus/my_bus_monitor.svh"

    `include "./rt_sig/my_rt_sig_agent.svh"
    `include "./bus/my_bus_agent.svh"

    `include "my_env.svh"
endpackage

`endif
