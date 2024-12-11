// Verible directive
// verilog_lint: waive-start parameter-name-style
// verilog_lint: waive-start line-length

`include "../skid_buf_v0_1_0.svh"

`default_nettype none

// timescale is defined in Makefile.

//! A test bench for skid_buf.
module test_bench;
// ---------- parameters ----------
localparam int CLK_PERIOD_NS = 8; //! clock period in ns
localparam int SIM_TIME_LIMIT_NS = 500; //! simulation time limit in ns
localparam int RELEASE_RST_AFTER_CLK = 2; //! Reset signal deasserts right after this clock rising-edge.

parameter int DATA_BIT_WIDTH = 8; //! data bit width
parameter type T = logic [DATA_BIT_WIDTH-1:0]; //! data type
// --------------------

// ---------- types ----------
typedef virtual interface skid_buf_if#(
    .T(T)
) dut_vif_t;
// --------------------

// ---------- signal and storage ----------
interface skid_buf_if #(
    parameter type T = logic //! data type
)(
    input wire logic i_clk //! clock signal
);
    logic us_valid; //! valid signal from upstream
    T us_data; //! data from upstream
    logic us_ready; //! ready signal to upstream

    logic ds_ready; //! ready signal from downstream
    T ds_data; //! data to downstream
    logic ds_valid; //! valid signal to downstream
endinterface

var bit r_clk; //! clock signal
var bit r_sync_rst; //! clock synchronous reset signal

//! virtual interface to the DUT
dut_vif_t dut_vif;
// --------------------

// ---------- instances ----------
//! interface to the DUT
skid_buf_if #(
    .T(T)
) dut_if (.i_clk(r_clk));

//! DUT instance
skid_buf_v0_1_0 #(
    .T(T)
) dut (
    .i_clk(r_clk),
    .i_sync_rst(r_sync_rst),
    .i_freeze(1'b0),
    .i_us_valid(dut_if.us_valid),
    .i_us_data(dut_if.us_data),
    .o_us_ready(dut_if.us_ready),
    .i_ds_ready(dut_if.ds_ready),
    .o_ds_data(dut_if.ds_data),
    .o_ds_valid(dut_if.ds_valid)
);
// --------------------

// ---------- procedures ----------
//! Drive the clock.
initial forever #(CLK_PERIOD_NS/2) r_clk = ~r_clk;

//! Reset all the bench-driven signals.
task automatic rst_bench_driven_sigs();
    dut_vif.us_valid <= 1'b0;
    dut_vif.us_data <= '0;
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
endtask

task automatic feed_data(ref dut_vif_t vif);
    localparam int NUM_DATA = 16;

    T us_data[NUM_DATA] = {
        'h00, 'h01, 'h02, 'h03, 'h04, 'h05, 'h06, 'h07,
        'h08, 'h09, 'h0a, 'h0b, 'h0c, 'h0d, 'h0e, 'h0f
    };
    logic next_us_valid;
    logic next_ds_ready;
    T ds_data[NUM_DATA] = '{default:'0};

    @(posedge vif.i_clk);
    vif.us_valid <= 1'b0;
    vif.us_data <= us_data[0];
    vif.ds_ready <= 1'b0;

    for (int push_cnt=0, pop_cnt=0; pop_cnt<NUM_DATA;) begin
        @(posedge vif.i_clk);
        if (vif.us_valid && vif.us_ready) begin
            ++push_cnt;
        end

        if (vif.ds_valid && vif.ds_ready) begin
            ds_data[pop_cnt] = vif.ds_data;
            ++pop_cnt;
        end

        vif.us_valid <= (push_cnt < NUM_DATA) ? $urandom_range(0, 99) / 50 : 1'b0;
        vif.us_data <= (push_cnt < NUM_DATA) ? us_data[push_cnt] : '0;
        vif.ds_ready <= (pop_cnt < NUM_DATA) ? $urandom_range(0, 99) / 50 : 1'b0;
    end

    // Validate the data.
    for (int i=0; i<NUM_DATA; ++i) begin
        if (us_data[i] !== ds_data[i]) begin
            $fatal(2, $sformatf("Data mismatch at index %0d: expected 8'h%02h, got 8'h%02h", i, us_data[i], ds_data[i]));
        end
    end

    $display("Data validation passed.");
endtask

task automatic scenario();
    drive_rst();
    @(posedge r_clk);
    feed_data(dut_vif);
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
