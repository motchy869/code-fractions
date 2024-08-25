// Verible directive
// verilog_lint: waive-start parameter-name-style
// verilog_lint: waive-start line-length

`include "avmm_if_pkg_v0_1_0.svh"
`include "my_avmm_agt_template_v0_1_0.svh"

`default_nettype none

timeunit 1ns;
timeprecision 1ps;

//! A test bench for my_avmm_agt_template.
module test_bench;
// ---------- parameters ----------
localparam int CLK_PERIOD_NS = 8; //! clock period in ns
localparam int SIM_TIME_LIMIT_NS = 300; //! simulation time limit in ns
localparam int RST_DURATION_CYCLE = 1; //! reset duration in cycles

localparam int AVMM_ADDR_BIT_WIDTH = 2; //! bit width of Avalon-MM address bus
localparam int AVMM_DATA_BIT_WIDTH = 32; //! bit width of Avalon-MM data bus
// --------------------

// ---------- parameter validation ----------
// --------------------

// ---------- functions ----------
// --------------------

// ---------- signals and storage ----------
typedef avmm_if_pkg_v0_1_0::avmm_access #(
    .AVMM_ADDR_BIT_WIDTH(AVMM_ADDR_BIT_WIDTH),
    .AVMM_DATA_BIT_WIDTH(AVMM_DATA_BIT_WIDTH)
) avmm_access_t;

typedef virtual interface avmm_if_v0_1_0 #(
    .AVMM_ADDR_BIT_WIDTH(AVMM_ADDR_BIT_WIDTH),
    .AVMM_DATA_BIT_WIDTH(AVMM_DATA_BIT_WIDTH)
) vif_t;

var bit r_clk; //! clock signal
var bit r_sync_rst; //! clock synchronous reset signal

vif_t dut_vif; //! virtual interface to DUT
// --------------------

// ---------- instances ----------
//! interface to DUT
avmm_if_v0_1_0 #(
    .AVMM_ADDR_BIT_WIDTH(AVMM_ADDR_BIT_WIDTH),
    .AVMM_DATA_BIT_WIDTH(AVMM_DATA_BIT_WIDTH)
) dut_if (.i_clk(r_clk));

//! DUT instance
my_avmm_agt_template_v0_1_0 #(
    .AVMM_ADDR_BIT_WIDTH(AVMM_ADDR_BIT_WIDTH),
    .AVMM_DATA_BIT_WIDTH(AVMM_DATA_BIT_WIDTH)
) dut (
    .i_clk(r_clk),
    .i_sync_rst(r_sync_rst),
    .if_agt_avmm(dut_if)
);
// --------------------

// ---------- blocks ----------
//! Drive the clock.
initial forever #(CLK_PERIOD_NS/2) r_clk = ~r_clk;

//! Drive the reset signal.
task automatic drive_rst();
    r_sync_rst <= 1'b1;
    repeat (RST_DURATION_CYCLE) begin
        @(posedge r_clk);
    end
    r_sync_rst <= 1'b0;
endtask

task automatic reg_check();
    const var bit [AVMM_DATA_BIT_WIDTH-1:0] write_data[4] = {'h12345678, 'h87654321, 'hABCDEF01, 'h10FEDCBA};
    var bit [AVMM_DATA_BIT_WIDTH-1:0] read_back_data;
    var avmm_if_pkg_v0_1_0::avmm_resp_t resp;

    for (int i=0; i<4; ++i) begin
        avmm_access_t::write(dut_vif, AVMM_ADDR_BIT_WIDTH'(i), write_data[i], '1, resp);
        $info("Write data 0x%h to word address 0x%h, response: %p", write_data[i], i, resp);
        if (resp != avmm_if_pkg_v0_1_0::AVMM_RESP_OKAY) begin
            $fatal(2, "Write failed.");
        end
        @(posedge r_clk);
    end

    for (int i=0; i<4; ++i) begin
        avmm_access_t::read(dut_vif, AVMM_ADDR_BIT_WIDTH'(i), read_back_data, resp);
        $info("Read back data from word address 0x%h: 0x%h, response: %p", i, read_back_data, resp);
        if (resp != avmm_if_pkg_v0_1_0::AVMM_RESP_OKAY || read_back_data != write_data[i]) begin
            $fatal(2, "Read failed.");
        end
        @(posedge r_clk);
    end
endtask

task automatic scenario();
    drive_rst();
    @(posedge r_clk);
    reg_check();
    @(posedge r_clk);
    $finish;
endtask

//! Launch scenario and manage time limit.
initial begin
    dut_vif = dut_if;
    avmm_access_t::reset_hst_out_sigs(dut_vif, 1'b1);
    fork
        scenario();
    join_none
    #SIM_TIME_LIMIT_NS;
    $fatal(2, "Simulation timeout.");
end
// --------------------
endmodule

`default_nettype wire
