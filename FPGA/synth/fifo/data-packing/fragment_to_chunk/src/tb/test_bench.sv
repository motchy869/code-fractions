// Verible directive
// verilog_lint: waive-start parameter-name-style
// verilog_lint: waive-start line-length

`include "../frag_to_chunk.svh"

`default_nettype none

// timescale is defined in Makefile.

//! A test bench for sgl_clk_fifo.
module test_bench;
// ---------- parameters ----------
// If enabled, `frag_to_chunk_fr` is used instead of `frag_to_chunk`.
`define TEST_FULLY_REGISTERED_VERSION
// --------------------

// ---------- parameters ----------
localparam int CLK_PERIOD_NS = 8; //! clock period in ns
localparam int SIM_TIME_LIMIT_NS = 1000; //! simulation time limit in ns
localparam int RELEASE_RST_AFTER_CLK = 2; //! Reset signal deasserts right after this clock rising-edge.

parameter int S_MAX_IN = 8;//! max size of the input fragment
parameter int S_OUT = 4;//! The size of the output chunk. **Recommended to be power of 2**. Other large numbers may lead to timing closure failure due to costly modulus operation.
parameter int FRAG_ELEM_BIT_WIDTH = 8; //! the bit width of the fragment's element
parameter type T = logic [FRAG_ELEM_BIT_WIDTH-1:0];//! data type of the elements
// --------------------

// ---------- types ----------
typedef virtual interface frag_to_chunk_if #(
    .S_MAX_IN(S_MAX_IN),
    .S_OUT(S_OUT),
    .T(T)
) dut_vif_t;
// --------------------

// ---------- internal signal and storage ----------
interface frag_to_chunk_if #(
    parameter int S_MAX_IN = 16,
    parameter int S_OUT = 8,
    parameter type T = logic,
    localparam int BIT_WIDTH__S_MAX_IN = $clog2(S_MAX_IN+1)
)(
    input wire i_clk
);
    logic frag_valid;
    logic [BIT_WIDTH__S_MAX_IN-1:0] frag_size;

    logic pad_tail;
    T frag[S_MAX_IN];
    logic next_frag_ready;

    logic ds_ready;
    logic chunk_valid;
    T chunk[S_OUT];
endinterface

var bit r_clk; //! clock signal
var bit r_sync_rst; //! clock synchronous reset signal

//! virtual interface to the DUT
dut_vif_t dut_vif;
// --------------------

// ---------- instances ----------
//! interface to the DUT
frag_to_chunk_if #(
    .S_MAX_IN(S_MAX_IN),
    .S_OUT(S_OUT),
    .T(T)
) dut_if (.i_clk(r_clk));

//! DUT instance
`ifdef TEST_FULLY_REGISTERED_VERSION
    frag_to_chunk_fr
`else
    frag_to_chunk
`endif
#(
    .S_MAX_IN(S_MAX_IN),
    .S_OUT(S_OUT),
    .T(T)
) dut (
    .i_clk(r_clk),
    .i_sync_rst(r_sync_rst),

    .i_frag_valid(dut_if.frag_valid),
    .i_frag_size(dut_if.frag_size),
    .i_pad_tail(dut_if.pad_tail),
    .i_frag(dut_if.frag),
    .o_next_frag_ready(dut_if.next_frag_ready),

    .i_ds_ready(dut_if.ds_ready),
    .o_chunk_valid(dut_if.chunk_valid),
    .o_chunk(dut_if.chunk)
);
// --------------------

// ---------- procedures ----------
//! Drive the clock.
initial forever #(CLK_PERIOD_NS/2) r_clk = ~r_clk;

//! Reset all the bench-driven signals.
task automatic rst_bench_driven_sigs();
    dut_vif.frag_valid <= 1'b0;
    dut_vif.frag_size <= '0;
    dut_vif.pad_tail <= 1'b0;
    dut_vif.frag <= '{default:'0};
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
    localparam int BIT_WIDTH__S_MAX_IN = $clog2(S_MAX_IN+1);

    logic next_frag_valid;
    logic [BIT_WIDTH__S_MAX_IN-1:0] frag_size = '0;
    logic [S_MAX_IN-1:0][FRAG_ELEM_BIT_WIDTH-1:0] frag = '0;

    for (int feed_cnt=0; feed_cnt<16;) begin
        @(posedge vif.i_clk);
        next_frag_valid = $urandom_range(0, 74) / 50;
        if (vif.frag_valid && vif.next_frag_ready) begin
            frag_size = $urandom_range(0, S_MAX_IN);
            for (int i=0; i<S_MAX_IN; ++i) begin
                frag[i] = $urandom_range(0, (1<<FRAG_ELEM_BIT_WIDTH)-1);
            end
            ++feed_cnt;
        end
        vif.frag_valid <= next_frag_valid;
        vif.frag_size <= frag_size;
        for (int i=0; i<S_MAX_IN; ++i) begin
            vif.frag[i] <= frag[i];
        end
        vif.ds_ready <= $urandom_range(0, 99) / 50;
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
