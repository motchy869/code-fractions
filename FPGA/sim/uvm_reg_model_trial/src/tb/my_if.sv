// Verible directive
// verilog_lint: waive-start line-length

`include "../axi4_lite_if.svh"
`include "my_verif_pkg.svh"

`default_nettype none

interface my_if (
    input wire logic clk
);
    bit sync_rst;
    axi4_lite_if #(
        .ADDR_BIT_WIDTH(my_verif_pkg::AXI4_LITE_ADDR_BIT_WIDTH),
        .DATA_BIT_WIDTH(my_verif_pkg::AXI4_LITE_DATA_BIT_WIDTH)
    ) axi4_lite_if_0();

    clocking drv_cb @(posedge clk); // clocking block for driver
        default input #1 output #1;
        output sync_rst;

        // [SystemVerilog Clocking Blocks in Bi-Directional Interface](https://stackoverflow.com/questions/35185878/systemverilog-clocking-blocks-in-bi-directional-interface)
        inout axi4_lite_if_0;
    endclocking

    clocking col_cb @(posedge clk); // clocking block for collector
        default input #1 output #1;
        input sync_rst;
        input axi4_lite_if_0;
    endclocking
endinterface

`default_nettype wire
