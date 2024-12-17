// Verible directive
// verilog_lint: waive-start parameter-name-style
// verilog_lint: waive-start line-length

`default_nettype none

// timescale is defined in Makefile.

module test_bench;
// ---------- parameters ----------
typedef int unsigned uint_t;

localparam uint_t US_CLK_PERIOD_NS = 5; //! upstream-side clock period in ns
localparam uint_t DS_CLK_PERIOD_NS = 8; //! downstream-side clock period in ns
localparam uint_t US_RST_DURATION_CYCLE = 1; //! upstream-side reset duration in cycles
localparam uint_t DS_RST_DURATION_CYCLE = 1; //! downstream-side reset duration in cycles
localparam uint_t SIM_TIME_LIMIT_NS = 200; //! simulation time limit in ns

localparam uint_t US_ADD_DELAY = 1;
localparam uint_t DS_ADD_DELAY = 1;
// --------------------

// ---------- parameter validation ----------
// --------------------

// ---------- functions ----------
// --------------------

// ---------- signals and storage ----------
var bit r_us_clk; //! upstream-side clock signal
var bit r_ds_clk; //! downstream-side clock signal

interface dut_if #(
    parameter int unsigned US_ADD_DELAY = 0,
    parameter int unsigned DS_ADD_DELAY = 0
)(
    input wire logic us_clk,
    input wire logic ds_clk
);
    // signals between upstream-side and DUT
    logic us_sync_rst;
    logic us_pulse;

    // signals between downstream-side and DUT
    logic ds_sync_rst;
    logic ds_pulse;

    task automatic reset_us_bench_driven_sigs();
        us_pulse <= 1'b0;
    endtask
endinterface

typedef virtual interface dut_if #(
    .US_ADD_DELAY(US_ADD_DELAY),
    .DS_ADD_DELAY(DS_ADD_DELAY)
) dut_vif_t;

dut_vif_t dut_vif; //! virtual interface to DUT
// --------------------

// ---------- instances ----------
//! interface to DUT
dut_if #(
    .US_ADD_DELAY(US_ADD_DELAY),
    .DS_ADD_DELAY(DS_ADD_DELAY)
) dut_if_0 (
    .us_clk(r_us_clk),
    .ds_clk(r_ds_clk)
);

//! DUT instance
pulse_cdc_v0_1_0 #(
    .US_ADD_DELAY(US_ADD_DELAY),
    .DS_ADD_DELAY(DS_ADD_DELAY)
) dut (
    .i_us_clk(dut_if_0.us_clk),
    .i_us_sync_rst(dut_if_0.us_sync_rst),
    .i_us_pulse(dut_if_0.us_pulse),
    .i_ds_clk(dut_if_0.ds_clk),
    .i_ds_sync_rst(dut_if_0.ds_sync_rst),
    .o_ds_pulse(dut_if_0.ds_pulse)
);
// --------------------

// ---------- blocks ----------
//! Drives the clock.
initial forever #(US_CLK_PERIOD_NS/2) r_us_clk = ~r_us_clk;
initial forever #(DS_CLK_PERIOD_NS/2) r_ds_clk = ~r_ds_clk;

//! Drives the upstream-side reset signal.
task automatic drive_us_rst(ref dut_vif_t vif);
    @(posedge r_us_clk);
    vif.us_sync_rst <= 1'b1;
    vif.reset_us_bench_driven_sigs();
    repeat (US_RST_DURATION_CYCLE) begin
        @(posedge r_us_clk);
    end
    vif.us_sync_rst <= 1'b0;
endtask

//! Drives the downstream-side reset signal.
task automatic drive_ds_rst(ref dut_vif_t vif);
    @(posedge r_ds_clk);
    vif.ds_sync_rst <= 1'b1;
    repeat (DS_RST_DURATION_CYCLE) begin
        @(posedge r_ds_clk);
    end
    vif.ds_sync_rst <= 1'b0;
endtask

// Feeds pulse to DUT.
task automatic feed_pulse(ref dut_vif_t vif);
    localparam uint_t INTER_PULSE_GAP_CYC = ((6+US_ADD_DELAY)*US_CLK_PERIOD_NS + (3+DS_ADD_DELAY)*DS_CLK_PERIOD_NS + (US_CLK_PERIOD_NS-1))/US_CLK_PERIOD_NS;
    // 1st pulse
    @(posedge r_us_clk);
    vif.us_pulse <= 1'b1;
    @(posedge r_us_clk);
    vif.us_pulse <= 1'b0;

    for (int unsigned i=0; i<INTER_PULSE_GAP_CYC; ++i) begin
        @(posedge r_us_clk);
    end

    // 2nd pulse
    @(posedge r_us_clk);
    vif.us_pulse <= 1'b1;
    @(posedge r_us_clk);
    vif.us_pulse <= 1'b0;
endtask

task automatic scenario();
    fork
        drive_us_rst(dut_vif);
        drive_ds_rst(dut_vif);
    join
    @(posedge r_us_clk);
    feed_pulse(dut_vif);
    @(posedge r_us_clk);
endtask

//! Launches scenario and manage time limit.
initial begin
    dut_vif = dut_if_0;
    fork
        scenario();
    join_none
    #SIM_TIME_LIMIT_NS;
    $info("Simulation ended.");
    $finish;
end
// --------------------
endmodule

`default_nettype wire
