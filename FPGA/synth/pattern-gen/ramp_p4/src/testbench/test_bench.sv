// Verible directive
// verilog_lint: waive-start parameter-name-style

`default_nettype none

// `timeunit` and `timeprecision` should NOT be placed in the module.
//timeunit 1ns;
//timeprecision 1ps;

module test_bench;
// ---------- parameters ----------
localparam int CLK_PERIOD_NS = 8; //! clock period in ns
localparam int SIM_DURATION_NS = 200; //! simulation duration in ns
localparam int RELEASE_RST_AFTER_CLK = 2; //! Reset signal deasserts right after this clock rising-edge.
localparam int DRIVE_START_REQ_AFTER_CLK = 4; //! Start request pulse rises right after this clock rising-edge.

localparam int RAMP_WAV_BW_VAL = 16; //! bit width of waveform value
localparam int RAMP_WAV_BW_SEQ_CONT = 16; //! bit width of tread length and the number of steps of waveform value
localparam int RAMP_WAV_P = 4; //! parallelism of waveform generator
// --------------------

// ---------- internal signal and storage ----------
typedef struct {
    logic [RAMP_WAV_BW_VAL-1:0] init_val;
    logic [RAMP_WAV_BW_VAL-1:0] inc_val;
    logic [RAMP_WAV_BW_SEQ_CONT-1:0] tread_len;
    logic [RAMP_WAV_BW_SEQ_CONT-1:0] num_treads;
} sim_cfg_t;

//! Simulation configuration. Most easy case.
const sim_cfg_t sim_cfg_0 = '{
    init_val: RAMP_WAV_BW_VAL'(0),
    inc_val: RAMP_WAV_BW_VAL'(3),
    tread_len: RAMP_WAV_BW_SEQ_CONT'(1),
    num_treads: RAMP_WAV_BW_SEQ_CONT'(12)
};

//! Simulation configuration. Easy case.
const sim_cfg_t sim_cfg_1 = '{
    init_val: RAMP_WAV_BW_VAL'(0),
    inc_val: RAMP_WAV_BW_VAL'(3),
    tread_len: RAMP_WAV_BW_SEQ_CONT'(2),
    num_treads: RAMP_WAV_BW_SEQ_CONT'(8)
};

//! Simulation configuration. Easy case.
const sim_cfg_t sim_cfg_2 = '{
    init_val: RAMP_WAV_BW_VAL'(0),
    inc_val: RAMP_WAV_BW_VAL'(3),
    tread_len: RAMP_WAV_BW_SEQ_CONT'(4),
    num_treads: RAMP_WAV_BW_SEQ_CONT'(5)
};

//! Simulation configuration. Hard case.
const sim_cfg_t sim_cfg_3 = '{
    init_val: RAMP_WAV_BW_VAL'(0),
    inc_val: RAMP_WAV_BW_VAL'(3),
    tread_len: RAMP_WAV_BW_SEQ_CONT'(3),
    num_treads: RAMP_WAV_BW_SEQ_CONT'(5)
};

//! Simulation configuration. Hard case.
const sim_cfg_t sim_cfg_4 = '{
    init_val: RAMP_WAV_BW_VAL'(0),
    inc_val: RAMP_WAV_BW_VAL'(3),
    tread_len: RAMP_WAV_BW_SEQ_CONT'(7),
    num_treads: RAMP_WAV_BW_SEQ_CONT'(5)
};

var bit w_ramp_p4_ip_start_req = 1'b0;
const bit [RAMP_WAV_BW_VAL-1:0] w_ramp_p4_init_val = sim_cfg_4.init_val;
const bit [RAMP_WAV_BW_VAL-1:0] w_ramp_p4_inc_val = sim_cfg_4.inc_val;
const bit [RAMP_WAV_BW_SEQ_CONT-1:0] w_ramp_p4_tread_len = sim_cfg_4.tread_len;
const bit [RAMP_WAV_BW_SEQ_CONT-1:0] w_ramp_p4_num_treads = sim_cfg_4.num_treads;
wire logic ramp_p4_idle;

const bit w_ramp_p4_ds_ready = 1'b1;
wire logic w_ramp_p4_chunk_valid;
wire logic [$clog2(RAMP_WAV_P+1)-1:0] w_ramp_p4_chunk_elem_cnt;
wire logic [RAMP_WAV_P-1:0][RAMP_WAV_BW_VAL-1:0] w_ramp_p4_chunk;

var bit r_clk; //! clock signal
var bit r_sync_rst; //! clock synchronous reset signal
// --------------------

//! DUT instance
ramp_p4_v0_1_0#(
    .BW_VAL(RAMP_WAV_BW_VAL),
    .BW_SEQ_CONT(RAMP_WAV_BW_SEQ_CONT)
) ramp_p4 (
    .i_clk(r_clk),
    .i_sync_rst(r_sync_rst),

    .ip_start_req(w_ramp_p4_ip_start_req),
    .i_init_val(w_ramp_p4_init_val),
    .i_inc_val(w_ramp_p4_inc_val),
    .i_tread_len(w_ramp_p4_tread_len),
    .i_num_treads(w_ramp_p4_num_treads),
    .o_idle(ramp_p4_idle),

    .i_ds_ready(w_ramp_p4_ds_ready),
    .o_chunk_valid(w_ramp_p4_chunk_valid),
    .o_chunk_elem_cnt(w_ramp_p4_chunk_elem_cnt),
    .o_chunk(w_ramp_p4_chunk)
);

//! Drive the clock.
initial forever #(CLK_PERIOD_NS/2) r_clk = ~r_clk;

//! Drive the reset signal.
task automatic drive_rst();
    r_sync_rst = 1;
    repeat (RELEASE_RST_AFTER_CLK) begin
        @(posedge r_clk);
    end
    r_sync_rst <= 0;
endtask

//! Drive the start request.
task automatic drive_start_req();
    repeat (DRIVE_START_REQ_AFTER_CLK) begin
        @(posedge r_clk);
    end
    w_ramp_p4_ip_start_req = 1;
    @(posedge r_clk);
    w_ramp_p4_ip_start_req = 0;
endtask

//! main
initial begin
    fork
        drive_rst();
        drive_start_req();
    join_none
    #SIM_DURATION_NS;
    $finish;
end

endmodule

`default_nettype wire
