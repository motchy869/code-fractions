// Verible directive
// verilog_lint: waive-start parameter-name-style
// verilog_lint: waive-start line-length

`include "../fxd_pt2flt_pt_v0_1_0_pkg.svh"

`default_nettype none

// timescale is defined in Makefile.

module test_bench;
// ---------- parameters ----------
typedef int unsigned uint_t;

localparam uint_t CLK_PERIOD_NS = 8; //! clock period in ns
localparam uint_t SIM_TIME_LIMIT_NS = 400; //! simulation time limit in ns
localparam uint_t RST_DURATION_CYCLE = 1; //! reset duration in cycles

uint_t BW_IN_INT = 4;
uint_t BW_IN_FRAC = 12;
uint_t BW_OUT_EXP = 8;
uint_t BW_OUT_FRAC = 23;
uint_t DUT_CYCLE_LAT = fxd_pt2flt_pt_v0_1_0_pkg::CYC_LAT;
// --------------------

// ---------- parameter validation ----------
// --------------------

// ---------- functions ----------
// --------------------

// ---------- signals and storage ----------
// --------------------

// ---------- instances ----------
// --------------------

// ---------- blocks ----------
// --------------------
endmodule

`default_nettype wire
