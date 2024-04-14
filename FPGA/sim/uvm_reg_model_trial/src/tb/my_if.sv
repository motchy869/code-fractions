// Verible directive
// verilog_lint: waive-start line-length

`ifndef MY_VERIF_PKG_SVH_INCLUDED
    $fatal("compile \"my_verif_pkg.sv\" instead of including this file");
`endif

`include "../axi4_lite_if.svh"

`default_nettype none

interface my_if (
    input wire logic clk
);
    logic sync_rst;
    axi4_lite_if #(
        .ADDR_BIT_WIDTH(my_verif_pkg::AXI4_LITE_ADDR_BIT_WIDTH),
        .DATA_BIT_WIDTH(my_verif_pkg::AXI4_LITE_DATA_BIT_WIDTH)
    ) axi4_lite_if_0(.clk(clk));
    logic reg_0_or_reduc;
    logic reg_1_and_reduc;
    logic reg_2_xor_reduc;
    logic [$clog2(my_verif_pkg::AXI4_LITE_DATA_BIT_WIDTH):0] reg_3_bit_cnt;

    clocking drv_cb @(posedge clk); // clocking block for driver
        default input #1 output #1;
        output sync_rst;

        // [SystemVerilog Clocking Blocks in Bi-Directional Interface](https://stackoverflow.com/questions/35185878/systemverilog-clocking-blocks-in-bi-directional-interface)
        // inout axi4_lite_if_0;

        input reg_0_or_reduc;
        input reg_1_and_reduc;
        input reg_2_xor_reduc;
        input reg_3_bit_cnt;
    endclocking

    clocking col_cb @(posedge clk); // clocking block for collector
        default input #1 output #1;
        input sync_rst;
        //input axi4_lite_if_0;
        input reg_0_or_reduc;
        input reg_1_and_reduc;
        input reg_2_xor_reduc;
        input reg_3_bit_cnt;
    endclocking
endinterface

`default_nettype wire
