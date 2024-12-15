// Verible directive
// verilog_lint: waive-start parameter-name-style
// verilog_lint: waive-start line-length

`default_nettype none

//! AXI4-Lite read-transaction CDC.
//! No outstanding transactions are supported.
//! ## changelog
//! ### [0.1.0] - 2024-12-xx
//! - initial release
module a4l_rd_cdc_v0_1_0 #(
    parameter int AXI4_LITE_ADDR_BIT_WIDTH = 32, //! bit width of AXI4-Lite address bus
    parameter int AXI4_LITE_DATA_BIT_WIDTH = 32 //! bit width of AXI4-Lite data bus
)(
    //! @virtualbus s_if @dir in AXI4 subordinate interface, through which the manager-side frontend (MS-FE) receives read request form the manager.
    input wire logic s00_sync_rst, //! synchronous reset signal
    input wire logic s00_aclk, //! subordinate-side clock
    input wire logic [AXI4_LITE_ADDR_BIT_WIDTH-1:0] s00_araddr, //! read address
    input wire logic [2:0] s00_arprot, //! protection type
    input wire logic s00_arvalid, //! read address valid
    output logic s00_arready, //! read address ready
    output logic [AXI4_LITE_DATA_BIT_WIDTH-1:0] s00_rdata, //! read data
    output logic [1:0] s00_rresp, //! read response
    output logic s00_rvalid, //! read data valid
    input logic s00_rready, //! read data ready
    //! @end
    //! @virtualbus m_if @dir out AXI4 manager interface, through which the subordinate-side frontend (SS-FE) sends read request to the subordinate.
    input wire logic m00_sync_rst, //! synchronous reset signal
    input wire logic m00_aclk, //! manager-side clock
    output wire logic [AXI4_LITE_ADDR_BIT_WIDTH-1:0] m00_araddr, //! read address
    output wire logic [2:0] m00_arprot, //! protection type
    output wire logic m00_arvalid, //! read address valid
    input wire logic m00_arready, //! read address ready
    input wire logic [AXI4_LITE_DATA_BIT_WIDTH-1:0] m00_rdata, //! read data
    input wire logic [1:0] m00_rresp, //! read response
    input wire logic m00_rvalid, //! read data valid
    output wire logic m00_rready //! read data ready
    //! @end
);
// ---------- parameters ----------
//! depth-0 state type
typedef enum logic [1:0] {
    D0_IDLE,
    D0_WAITING_RESP,
    D0_RESPONDING
} d0_state_t;

//! depth-1 state type
typedef enum logic {
    D1_SENDING_ARADDR,
    D1_WAITING_RVALID
} d1_state_t;
// --------------------

// ---------- parameter validation ----------
// --------------------

// ---------- functions ----------
// --------------------

// ---------- signals and storage ----------
var d0_state_t r_ms_fe_stat; //! MS-FE state
var d0_state_t r_ss_fe_stat; //! SS-FE state
var d0_state_t g_next_ms_fe_stat; //! MS-FE state right after the next clock rising edge
var d0_state_t g_next_ss_fe_stat; //! SS-FE state right after the next clock rising edge

//! latched request
typedef struct packed {
    logic [AXI4_LITE_ADDR_BIT_WIDTH-1:0] araddr;
    logic [2:0] arprot;
} req_latch_t;

var req_latch_t r_ms_fe__latched_req; //! Latched request in MS-FE. clock domain = MS-FE
var req_latch_t [1:0] r_ss_fe__latched_req_cdc_ff; //! Synchronization FFs for latched request from MS-FE to SS-FE. clock domain = SS-FE
wire g_ss_fe__req_pulse_from_ms_fe; //! Pulse indicating that MS-FE received a request from the manager, and the content of ```r_ss_fe__latched_req_cdc_ff[1]``` is ready to use. Clock domain = SS-FE

//! latched response
typedef struct packed {
    logic [AXI4_LITE_DATA_BIT_WIDTH-1:0] rdata;
    logic [1:0] rresp;
} resp_latch_t;

var resp_latch_t r_ss_fe__latched_resp; //! Latched response in SS-FE. clock domain = SS-FE
var resp_latch_t [1:0] r_ms_fe__latched_resp_cdc_ff; //! Synchronization FFs for latched response from SS-FE to MS-FE. clock domain = MS-FE
wire g_ms_fe__resp_pulse_from_ss_fe; //! Pulse indicating that SS-FE received a response from the subordinate, and the content of ```r_ms_fe__latched_resp_cdc_ff[1]``` is ready to use. Clock domain = MS-FE
// --------------------

// ---------- instances ----------
// --------------------

// --------------------

// ---------- Drives output signals. ----------
// --------------------

// ---------- blocks ----------
// --------------------
endmodule

`default_nettype wire
