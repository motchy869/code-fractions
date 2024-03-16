// Verible directive
// verilog_lint: waive-start parameter-name-style

`include "../simple_if.svh"

`default_nettype none

// `timeunit` and `timeprecision` should NOT be placed in the module.
timeunit 1ns;
timeprecision 1ps;

module test_bench;
// ---------- parameters ----------
localparam int CLK_PERIOD_NS = 8; //! clock period in ns
localparam int SIM_DURATION_NS = 200; //! simulation duration in ns
localparam int RELEASE_RST_AT_CLK = 2; //! Reset signal deasserts right after this clock rising-edge.
// --------------------

// ---------- internal signal and storage ----------
var bit r_clk; //! clock signal
var bit r_sync_rst; //! clock synchronous reset signal
// --------------------

//! top module instance
top top_0 (
    .i_clk(r_clk),
    .i_sync_rst(r_sync_rst)
);

//! Drive the clock.
initial forever #(CLK_PERIOD_NS/2) r_clk = ~r_clk;

//! Drive the reset signal.
task automatic drive_rst();
    int clk_cnt;

    r_sync_rst = 1;
    repeat (RELEASE_RST_AT_CLK) begin
        @(posedge r_clk);
    end
    r_sync_rst <= 0;
endtask

initial begin
    fork drive_rst(); join_none
    #SIM_DURATION_NS;
    $finish;
end

endmodule

`default_nettype wire
