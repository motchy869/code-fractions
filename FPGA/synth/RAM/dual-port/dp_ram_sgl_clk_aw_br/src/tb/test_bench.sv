// Verible directive
// verilog_lint: waive-start parameter-name-style
// verilog_lint: waive-start line-length

`include "../dp_ram_sgl_clk_aw_br_v0_1_0.sv"
`include "dut_if.sv"

`default_nettype none

// timescale is defined in Makefile.

//! test bench
module test_bench;
// ---------- parameters ----------
localparam int unsigned CLK_PRD_NS = 8; //! clock period in ns
localparam int unsigned DELTA_T = 1; //! delta time in ns, mainly used for sampling DUT's outputs
localparam int unsigned RST_DUR_CYC = 1; //! reset duration in clock cycle
//localparam int unsigned FRZ_DUR_CYC_AFTER_RST = 1; //! freeze duration in clock cycle after reset

localparam int unsigned WD_SZ_BASE = 16;
localparam int unsigned WD_SZ_A = WD_SZ_BASE;
localparam int unsigned WD_SZ_B = 4*WD_SZ_BASE;
localparam int unsigned WD_CNT = 16;
localparam int unsigned BIT_CNT = WD_CNT*WD_SZ_BASE; //! total number of bits in the RAM
localparam int unsigned WD_CNT_A = BIT_CNT/WD_SZ_A; //! number of A-side words in the RAM
localparam int unsigned WD_CNT_B = BIT_CNT/WD_SZ_B; //! number of B-side words in the RAM
localparam int unsigned NUM_OUT_REG = 1;

localparam int unsigned SIM_TIME_LIMIT_NS = (RST_DUR_CYC + WD_CNT_A + WD_CNT_B + NUM_OUT_REG)*CLK_PRD_NS*15/10; //! simulation time limit in ns
// --------------------

// ---------- parameter validation ----------
// --------------------

// ---------- functions ----------
// --------------------

// ---------- signals and storage ----------
var bit r_clk; //! clock signal
var bit r_sync_rst; //! clock synchronous reset signal

//! virtual interface to DUT
typedef virtual interface dut_if #(
    .WD_SZ_BASE(WD_SZ_BASE),
    .WD_SZ_A(WD_SZ_A),
    .WD_SZ_B(WD_SZ_B),
    .WD_CNT(WD_CNT)
) dut_vif_t;

dut_vif_t dut_vif; //! virtual interface to DUT
// --------------------

// ---------- instances ----------
//! interface to DUT
dut_if #(
    .WD_SZ_BASE(WD_SZ_BASE),
    .WD_SZ_A(WD_SZ_A),
    .WD_SZ_B(WD_SZ_B),
    .WD_CNT(WD_CNT)
) dut_if_0 (
    .i_clk(r_clk),
    .i_sync_rst(r_sync_rst)
);

//! DUT instance
dp_ram_sgl_clk_aw_br_v0_1_0 #(
    .WD_SZ_BASE(WD_SZ_BASE),
    .WD_SZ_A(WD_SZ_A),
    .WD_SZ_B(WD_SZ_B),
    .WD_CNT(WD_CNT),
    .NUM_OUT_REG(NUM_OUT_REG)
) dut (
    .i_clk(dut_if_0.i_clk),
    .i_sync_rst(dut_if_0.i_sync_rst),
    .i_a_wr_en(dut_if_0.a_wr_en),
    .i_a_wr_addr(dut_if_0.a_wr_addr),
    .i_a_wr_data(dut_if_0.a_wr_data),
    .i_b_rd_en(dut_if_0.b_rd_en),
    .i_b_rd_addr(dut_if_0.b_rd_addr),
    .o_b_rd_data(dut_if_0.b_rd_data)
);
// --------------------

// ---------- blocks ----------
//! Drives the clock.
initial forever #(CLK_PRD_NS/2) r_clk = ~r_clk;

//! Drives the reset signal.
task automatic drive_rst(ref dut_vif_t vif);
    // verilator lint_off INITIALDLY
    @(posedge vif.i_clk);
    r_sync_rst <= 1'b1;
    vif.reset_bench_driven_sigs();
    repeat (RST_DUR_CYC) begin
        @(posedge vif.i_clk);
    end
    r_sync_rst <= 1'b0;
    // verilator lint_on INITIALDLY
endtask

// Feeds data to DUT.
task automatic feed_data(ref dut_vif_t vif);
    localparam int unsigned ADDR_SZ_A = $clog2(WD_CNT_A); //! address size for A-side
    localparam int unsigned ADDR_SZ_B = $clog2(WD_CNT_B); //! address size for B-side
    localparam int unsigned RD_LAT_CYC = NUM_OUT_REG; //! read latency in clock cycles
    typedef union packed {
        logic [WD_CNT-1:0][WD_SZ_BASE-1:0] view_base; //! base view
        logic [WD_CNT_A-1:0][WD_SZ_A-1:0] view_a; //! A-side view
        logic [WD_CNT_B-1:0][WD_SZ_B-1:0] view_b; //! B-side view
    } ram_storage_t;
    ram_storage_t test_ram_data;
    ram_storage_t dumped_ram_data;
    bit is_error = 1'b0;

    // Generates test RAM data.
    for (int i=0; i<WD_CNT; ++i) begin
        test_ram_data.view_base[i] = WD_SZ_BASE'(i);
    end

    // verilator lint_off INITIALDLY

    // Fills the RAM with test data.
    for (int unsigned i=0; i<WD_CNT_A; ++i) begin
        @(posedge vif.i_clk);
        vif.a_wr_en <= 1'b1;
        vif.a_wr_addr <= ADDR_SZ_A'(i);
        vif.a_wr_data <= test_ram_data.view_a[i];
    end

    @(posedge vif.i_clk);
    vif.a_wr_en <= 1'b0;
    vif.a_wr_addr <= '0;
    vif.a_wr_data <= '0;

    // Reads the data from the RAM.
    for (int unsigned i=0; i<WD_CNT_B+RD_LAT_CYC; ++i) begin
        @(posedge vif.i_clk);
        vif.b_rd_en <= 1'b1;
        vif.b_rd_addr <= ADDR_SZ_B'(i);
        #DELTA_T; // Wait for the read data to be available.
        dumped_ram_data.view_b[WD_CNT_B'(i-RD_LAT_CYC)] = vif.b_rd_data;
    end

    @(posedge vif.i_clk);
    vif.b_rd_en <= 1'b0;
    vif.b_rd_addr <= '0;

    // verilator lint_on INITIALDLY

    // Checks the read data.
    for (int unsigned i=0; i<WD_CNT_B; ++i) begin
        if (dumped_ram_data.view_b[i] !== test_ram_data.view_b[i]) begin
            $display("Error: read data mismatch at address %0d: expected %0h, got %0h", i, test_ram_data.view_b[i], dumped_ram_data.view_b[i]);
            is_error = 1'b1;
        end
    end


    if (!is_error) begin
        $display("Test passed.");
    end
endtask

task automatic scenario();
    drive_rst(dut_vif);
    feed_data(dut_vif);
    $finish;
endtask

//! Launches scenario and manage time limit.
initial begin
    $timeformat(-9, 3, " ns", 12);
    dut_vif = dut_if_0;
    fork
        scenario();
    join_none
    #SIM_TIME_LIMIT_NS;
    $fatal(2, "Simulation timeout.");
end
// --------------------
endmodule

`default_nettype wire
