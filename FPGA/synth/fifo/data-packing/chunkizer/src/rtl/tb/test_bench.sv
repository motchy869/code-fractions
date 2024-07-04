// Verible directive
// verilog_lint: waive-start parameter-name-style
// verilog_lint: waive-start line-length

`include "../chunkizer.sv"

`default_nettype none

timeunit 1ns;
timeprecision 1ps;

//! A test bench for ```chunkizer```.
module test_bench;
// ---------- parameters ----------
localparam int unsigned CLK_PERIOD_NS = 8; //! clock period in ns
localparam int unsigned SIM_TIME_LIMIT_NS = 500; //! simulation time limit in ns
localparam int unsigned RELEASE_RST_AFTER_CLK = 2; //! Reset signal deasserts right after this clock rising-edge. For AMD FIFO Generator, **>= 100 ns reset duration is needed.**
localparam int unsigned POST_RELEASING_RST_WAIT = 1; //! Wait for this clock cycles after releasing the reset signal to make sure some vendor IPs are ready to work.

parameter int unsigned SZ_MAX_IN = 8;//! max size of the input fragment
parameter int unsigned SZ_OUT = 4;//! The size of the output chunk.
parameter int unsigned FRAG_ELEM_BIT_WIDTH = 8; //! the bit width of the fragment's element
// --------------------

// ---------- types ----------
typedef virtual interface chunkizer_if #(
    .SZ_MAX_IN(SZ_MAX_IN),
    .SZ_OUT(SZ_OUT)
) dut_vif_t;
// --------------------

// ---------- functions ----------
// --------------------

// ---------- signal and storage ----------
interface chunkizer_if #(
    parameter int unsigned SZ_MAX_IN = 8,
    parameter int unsigned SZ_OUT = 4,
    localparam int unsigned BIT_WIDTH__SZ_MAX_IN = $clog2(SZ_MAX_IN+1)
)(
    input wire logic i_clk
);
    logic frag_valid;
    logic [BIT_WIDTH__SZ_MAX_IN-1:0] frag_size;

    logic flush;
    logic [SZ_MAX_IN-1:0][FRAG_ELEM_BIT_WIDTH-1:0] frag;
    logic next_frag_ready;

    logic ds_ready;
    logic chunk_valid;
    logic [SZ_OUT-1:0][FRAG_ELEM_BIT_WIDTH-1:0] chunk;
endinterface

var bit r_clk; //! clock signal
var bit r_sync_rst; //! clock synchronous reset signal

//! virtual interface to the DUT
dut_vif_t dut_vif;
// --------------------

// ---------- instances ----------
//! interface to the DUT
chunkizer_if #(
    .SZ_MAX_IN(SZ_MAX_IN),
    .SZ_OUT(SZ_OUT)
) dut_if (.i_clk(r_clk));

//! DUT instance
chunkizer #(
    .SZ_MAX_IN(SZ_MAX_IN),
    .SZ_OUT(SZ_OUT)
) dut (
    .i_clk(r_clk),
    .i_sync_rst(r_sync_rst),

    .i_frag_valid(dut_if.frag_valid),
    .i_frag_size(dut_if.frag_size),
    .i_flush(dut_if.flush),
    .i_frag(dut_if.frag),
    .o_next_frag_ready(dut_if.next_frag_ready),

    .i_ds_ready(dut_if.ds_ready),
    .o_chunk_valid(dut_if.chunk_valid),
    .o_chunk(dut_if.chunk)
);
// --------------------

// ---------- blocks ----------
//! Drive the clock.
initial forever #(CLK_PERIOD_NS/2) r_clk = ~r_clk;

//! Reset all the bench-driven signals.
task automatic rst_bench_driven_sigs();
    dut_vif.frag_valid <= 1'b0;
    dut_vif.frag_size <= '0;
    dut_vif.flush <= 1'b0;
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
    repeat (POST_RELEASING_RST_WAIT) begin
        @(posedge r_clk);
    end
endtask

task automatic feed_data(ref dut_vif_t vif);
    localparam int unsigned BIT_WIDTH__SZ_MAX_IN = $clog2(SZ_MAX_IN+1);

    logic next_frag_valid;
    logic [BIT_WIDTH__SZ_MAX_IN-1:0] next_frag_size = '0;
    logic [SZ_MAX_IN-1:0][FRAG_ELEM_BIT_WIDTH-1:0] next_frag = '0;
    logic [FRAG_ELEM_BIT_WIDTH-1:0] elems_pushed[$]; // elements pushed into the DUT
    logic [FRAG_ELEM_BIT_WIDTH-1:0] elems_popped[$]; // elements popped from the DUT

    for (int unsigned feed_cnt=0; feed_cnt<16;) begin
        @(posedge vif.i_clk);
        next_frag_valid = $urandom_range(0, 74) / 50;

        if (vif.frag_valid && vif.next_frag_ready) begin
            // Records the pushed elements.
            for (int unsigned i=0; i<vif.frag_size; ++i) begin
                elems_pushed.push_back(vif.frag[i]);
            end
            ++feed_cnt;
        end

        if (feed_cnt == '0 || (vif.frag_valid && vif.next_frag_ready)) begin
            // Determines the next feeding data.
            next_frag_size = $urandom_range(1, SZ_MAX_IN);
            for (int unsigned i=0; i<SZ_MAX_IN; ++i) begin
                next_frag[i] = $urandom_range(0, (1<<FRAG_ELEM_BIT_WIDTH)-1);
            end
        end

        // Records the popped elements.
        if (vif.chunk_valid && vif.ds_ready) begin
            for (int unsigned i=0; i<SZ_OUT; ++i) begin
                elems_popped.push_back(vif.chunk[i]);
            end
        end

        vif.frag_valid <= next_frag_valid;
        vif.frag_size <= next_frag_size;
        for (int unsigned i=0; i<SZ_MAX_IN; ++i) begin
            vif.frag[i] <= next_frag[i];
        end
        vif.ds_ready <= $urandom_range(0, 99) / 50;
    end

    // Show recorded elements.
    $display("%3d elements are pushed.", elems_pushed.size());
    for (int unsigned i=0; i<elems_pushed.size(); ++i) begin
        $display("[%3d]: 8'%b", i, elems_pushed[i]);
    end
    $display("%3d elements are popped.", elems_popped.size());
    for (int unsigned i=0; i<elems_popped.size(); ++i) begin
        $display("[%3d]: 8'%b", i, elems_popped[i]);
    end

    // Make sure all popped elements are the same as the pushed ones.
    for (int unsigned i=0; i<elems_popped.size(); ++i) begin
        if (elems_pushed[i] != elems_popped[i]) begin
            $fatal(2, "The %d-th pushed element is different from the %d-th popped one.", i, i);
        end
    end
    $display("All popped elements are the same as the pushed ones.");
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
