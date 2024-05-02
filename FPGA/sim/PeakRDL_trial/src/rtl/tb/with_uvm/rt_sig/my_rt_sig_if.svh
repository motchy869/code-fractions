`ifndef MY_RT_SIG_IF_SVH_INCLUDED
`define MY_RT_SIG_IF_SVH_INCLUDED

// Verible directive
// verilog_lint: waive-start line-length

`default_nettype none

interface my_rt_sig_if (
    input wire logic i_clk //! clock signal
);
    logic sync_rst;

    // There are no modport because neither DUT nor test bench has modport.

    clocking drv_cb @(posedge i_clk); // clocking block for driver
        default input #1 output #1;
            output sync_rst;
    endclocking

    clocking col_cb @(posedge i_clk); // clocking block for collector
        default input #1 output #1;
        input sync_rst;
    endclocking
endinterface

`default_nettype wire

`endif
