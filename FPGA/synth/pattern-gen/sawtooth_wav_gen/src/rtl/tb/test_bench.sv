// Verible directive
// verilog_lint: waive-start parameter-name-style
// verilog_lint: waive-start line-length

`include "../sawtooth_wav_gen.svh"

`default_nettype none

// timescale is defined in Makefile.

module test_bench;
// ---------- parameters ----------
localparam int unsigned CLK_PERIOD_NS = 8; //! clock period in ns
localparam int unsigned SIM_TIME_LIMIT_NS = 300; //! simulation time limit in ns
localparam int unsigned RELEASE_RST_AFTER_CLK = 2; //! Reset signal deasserts right after this clock rising-edge. For AMD FIFO Generator, **>= 100 ns reset duration is needed.**
localparam int unsigned POST_RELEASING_RST_WAIT = 0; //! Wait for this clock cycles after releasing the reset signal to make sure some vendor IPs are ready to work.

localparam int unsigned BIT_WIDTH__OUTPUT = 8;
localparam int unsigned BIT_WIDTH__INT_PART__PERIOD = 4;
localparam int unsigned BIT_WIDTH__FRAC_PART__PERIOD = 4;
localparam int unsigned SSR = 4;
localparam int unsigned CYCLE_LATENCY = 9;
// --------------------

// ---------- types ----------
typedef virtual interface sawtooth_wav_gen_if #(
    .BIT_WIDTH__OUTPUT(BIT_WIDTH__OUTPUT),
    .BIT_WIDTH__INT_PART__PERIOD(BIT_WIDTH__INT_PART__PERIOD),
    .BIT_WIDTH__FRAC_PART__PERIOD(BIT_WIDTH__FRAC_PART__PERIOD),
    .SSR(SSR)
) dut_vif_t;
// --------------------

// ---------- functions ----------
// --------------------

// ---------- signal and storage ----------
interface sawtooth_wav_gen_if #(
    parameter int unsigned BIT_WIDTH__OUTPUT = 8,
    parameter int unsigned BIT_WIDTH__INT_PART__PERIOD = 4,
    parameter int unsigned BIT_WIDTH__FRAC_PART__PERIOD = 4,
    parameter int unsigned SSR = 4
)(
    input wire logic i_clk
);
    logic signed [BIT_WIDTH__OUTPUT-1:0] start_val;
    logic signed [BIT_WIDTH__OUTPUT-1:0] end_val;
    logic [BIT_WIDTH__INT_PART__PERIOD-1:0] int_part__period;
    logic [BIT_WIDTH__FRAC_PART__PERIOD-1:0] frac_part__period;

    logic ds_ready;
    logic chunk_valid;
    logic [SSR-1:0][BIT_WIDTH__OUTPUT-1:0] chunk_data;
endinterface

var bit r_clk; //! clock signal
var bit r_sync_rst; //! clock synchronous reset signal

//! virtual interface to the DUT
dut_vif_t dut_vif;
// --------------------

// ---------- instances ----------
//! interface to the DUT
sawtooth_wav_gen_if #(
    .BIT_WIDTH__OUTPUT(BIT_WIDTH__OUTPUT),
    .BIT_WIDTH__INT_PART__PERIOD(BIT_WIDTH__INT_PART__PERIOD),
    .BIT_WIDTH__FRAC_PART__PERIOD(BIT_WIDTH__FRAC_PART__PERIOD),
    .SSR(SSR)
) dut_if (.i_clk(r_clk));

//! DUT instance
sawtooth_wav_gen #(
    .BIT_WIDTH__OUTPUT(BIT_WIDTH__OUTPUT),
    .BIT_WIDTH__INT_PART__PERIOD(BIT_WIDTH__INT_PART__PERIOD),
    .BIT_WIDTH__FRAC_PART__PERIOD(BIT_WIDTH__FRAC_PART__PERIOD),
    .SSR(SSR)
) dut (
    .i_clk(r_clk),
    .i_sync_rst(r_sync_rst),

    .i_start_val(dut_if.start_val),
    .i_end_val(dut_if.end_val),
    .i_int_part__period(dut_if.int_part__period),
    .i_frac_part__period(dut_if.frac_part__period),

    .i_ds_ready(dut_if.ds_ready),
    .o_chunk_valid(dut_if.chunk_valid),
    .o_chunk_data(dut_if.chunk_data)
);
// --------------------

// ---------- blocks ----------
//! Drive the clock.
initial forever #(CLK_PERIOD_NS/2) r_clk = ~r_clk;

//! Reset all the bench-driven signals.
task automatic rst_bench_driven_sigs();
    dut_vif.start_val <= 1'b0;
    dut_vif.end_val <= '0;
    dut_vif.int_part__period <= '0;
    dut_vif.frac_part__period <= '0;
    dut_vif.ds_ready <= 1'b0;
endtask

//! Drive the reset signal.
task automatic drive_rst();
    rst_bench_driven_sigs();
    r_sync_rst <= 1'b1;
    repeat (RELEASE_RST_AFTER_CLK) begin
        @(posedge r_clk);
    end
    r_sync_rst <= 1'b0;
    repeat (POST_RELEASING_RST_WAIT) begin
        @(posedge r_clk);
    end
endtask

task automatic configure_dut(ref dut_vif_t vif);
    localparam int unsigned END_VAL = 127;
    localparam int unsigned INT_PART__PERIOD = 12;
    localparam int unsigned FRAC_PART__PERIOD = 4;

    r_sync_rst <= 1'b1;
    vif.start_val <= '0;
    vif.end_val <= BIT_WIDTH__OUTPUT'(END_VAL);
    vif.int_part__period <= BIT_WIDTH__INT_PART__PERIOD'(INT_PART__PERIOD);
    vif.frac_part__period <= BIT_WIDTH__FRAC_PART__PERIOD'(FRAC_PART__PERIOD);

    @(posedge r_clk);
    r_sync_rst <= 1'b0;
    vif.ds_ready <= 1'b1;

    repeat ((INT_PART__PERIOD + SSR - 1)/SSR + CYCLE_LATENCY + 5) begin
        @(posedge r_clk);
    end
endtask

task automatic scenario();
    drive_rst();
    @(posedge r_clk);
    configure_dut(dut_vif);
    @(posedge r_clk);
    $finish;
endtask

//! Launch scenario and manage time limit.
initial begin
    dut_vif = dut_if;
    fork
        scenario();
    join_none
    #SIM_TIME_LIMIT_NS;
    $fatal(2, "Simulation timeout.");
end
// --------------------
endmodule

`default_nettype wire
