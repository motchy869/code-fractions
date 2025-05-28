// Verible directive
// verilog_lint: waive-start parameter-name-style
// verilog_lint: waive-start line-length

`include "../sgl_clk_ring_fifo.svh"

`default_nettype none

// timescale is defined in Makefile.

//! A test bench for sgl_clk_ring_fifo.
module test_bench;
// ---------- parameters ----------
localparam int CLK_PERIOD_NS = 8; //! clock period in ns
localparam int SIM_TIME_LIMIT_NS = 1000; //! simulation time limit in ns
localparam int RELEASE_RST_AFTER_CLK = 2; //! Reset signal deasserts right after this clock rising-edge.

parameter int DATA_BIT_WIDTH = 8; //! data bit width
parameter int DEPTH = 4; //! FIFO depth
// --------------------

// ---------- types ----------
typedef virtual interface sgl_clk_ring_fifo_if#(
    .DATA_BIT_WIDTH(DATA_BIT_WIDTH),
    .DEPTH(DEPTH)
) dut_vif_t;
// --------------------

// ---------- internal signal and storage ----------
interface sgl_clk_ring_fifo_if#(
    parameter int DATA_BIT_WIDTH = 8, //! data bit width
    parameter int DEPTH = 16 //! FIFO depth
)(
    input wire logic i_clk //! clock signal
);
    logic we; //! write enable
    logic [DATA_BIT_WIDTH-1:0] data_in; //! input data
    logic full; //! full flag
    logic re; //! read enable
    logic [DATA_BIT_WIDTH-1:0] data_out; //! output data
    logic empty; //! empty flag
endinterface

var bit r_clk; //! clock signal
var bit r_sync_rst; //! clock synchronous reset signal

//! virtual interface to the DUT
dut_vif_t dut_vif;
// --------------------

// ---------- instances ----------
//! interface to the DUT
sgl_clk_ring_fifo_if#(
    .DATA_BIT_WIDTH(DATA_BIT_WIDTH),
    .DEPTH(DEPTH)
) dut_if (.i_clk(r_clk));

//! DUT instance
sgl_clk_ring_fifo#(
    .DATA_BIT_WIDTH(DATA_BIT_WIDTH),
    .DEPTH(DEPTH)
) dut (
    .i_clk(r_clk),
    .i_sync_rst(r_sync_rst),
    .i_we(dut_if.we),
    .i_data(dut_if.data_in),
    .o_full(dut_if.full),
    .i_re(dut_if.re),
    .o_data(dut_if.data_out),
    .o_empty(dut_if.empty)
);
// --------------------

// ---------- procedures ----------
//! Drive the clock.
initial forever #(CLK_PERIOD_NS/2) r_clk = ~r_clk;

//! Reset all the bench-driven signals.
task automatic rst_bench_driven_sigs();
    dut_vif.we <= 1'b0;
    dut_vif.data_in <= '0;
    dut_vif.re <= 1'b0;
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
    logic next_we;
    logic [DATA_BIT_WIDTH-1:0] input_data = DATA_BIT_WIDTH'('hC001CAFE);

    // write throughput > read throughput
    for (int feed_cnt=0; feed_cnt<3*DEPTH;) begin
        @(posedge vif.i_clk);
        next_we = $urandom_range(0, 99) / 50;
        if (vif.we && !vif.full) begin
            input_data = $urandom_range(0, (1<<DATA_BIT_WIDTH)-1);
            ++feed_cnt;
            if (feed_cnt == 3*DEPTH) begin
                break;
            end
        end
        vif.we <= next_we;
        vif.data_in <= input_data;
        vif.re <= $urandom_range(0, 74) / 50;
    end

    // write throughput < read throughput
    for (int feed_cnt=0; feed_cnt<3*DEPTH;) begin
        @(posedge vif.i_clk);
        next_we = $urandom_range(0, 99) / 50;
        if (vif.we && !vif.full) begin
            input_data = $urandom_range(0, (1<<DATA_BIT_WIDTH)-1);
            ++feed_cnt;
            if (feed_cnt == 3*DEPTH) begin
                break;
            end
        end
        vif.we <= next_we;
        vif.data_in <= input_data;
        vif.re <= $urandom_range(0, 74) / 50;
    end
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
