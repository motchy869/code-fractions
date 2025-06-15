// Verible directive
// verilog_lint: waive-start parameter-name-style
// verilog_lint: waive-start line-length

`ifndef DUT_IF_DEFINED
`define DUT_IF_DEFINED

//! interface to DUT
interface dut_if #(
    parameter int unsigned WD_SZ_BASE = 16,
    parameter int unsigned WD_SZ_A = WD_SZ_BASE,
    parameter int unsigned WD_SZ_B = 4*WD_SZ_BASE,
    parameter int unsigned WD_CNT = 16
)(
    input wire logic i_clk,
    logic i_sync_rst
);
    // signals between bench and DUT's control interface

    // signals between bench and DUT's upstream-side interface
    logic a_wr_en;
    logic [$clog2(WD_CNT*WD_SZ_BASE/WD_SZ_A)-1:0] a_wr_addr;
    logic [WD_SZ_A-1:0] a_wr_data;

    // signals between bench and DUT's downstream-side interface
    logic b_rd_en;
    logic [$clog2(WD_CNT*WD_SZ_BASE/WD_SZ_B)-1:0] b_rd_addr;
    logic [WD_SZ_B-1:0] b_rd_data;

    task automatic reset_bench_driven_sigs();
        // verilator lint_off INITIALDLY
        a_wr_en <= 1'b0;
        a_wr_addr <= '0;
        a_wr_data <= '0;
        b_rd_en <= 1'b0;
        b_rd_addr <= '0;
        // verilator lint_on INITIALDLY
    endtask
endinterface

`endif // DUT_IF_DEFINED
