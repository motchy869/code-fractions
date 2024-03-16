// Verible directive
// verilog_lint: waive-start parameter-name-style

`include "simple_if.svh"

`default_nettype none

module top (
    input wire logic i_clk, //! clock
    input wire logic i_sync_rst //! reset
);

// ---------- parameters ----------
localparam int ADDR_BIT_WIDTH = 2; //! address bit width
localparam int DATA_BIT_WIDTH = 8; //! data bit width
// --------------------

// ---------- internal signal and storage ----------
//! interface instance
simple_if #(
    .ADDR_BIT_WIDTH(ADDR_BIT_WIDTH),
    .DATA_BIT_WIDTH(DATA_BIT_WIDTH)
) test_if_0 ();
wire logic [ADDR_BIT_WIDTH-1:0] w_monit_addr; //! monitored address between master and slave
wire logic [DATA_BIT_WIDTH-1:0] w_monit_rd_data; //! monitored read back data between master and slave
//assign w_monit_addr = test_if_0.slv_port.addr; //! NOT ALLOWED! (Vivado 2023.2)
assign w_monit_addr = test_if_0.addr; //! OK (Vivado 2023.2)
assign w_monit_rd_data = test_if_0.rd_data;
// --------------------

//! master module
mst_mdl #(
    .ADDR_BIT_WIDTH(ADDR_BIT_WIDTH),
    .DATA_BIT_WIDTH(DATA_BIT_WIDTH)
) mst_mdl_0 (
    .i_clk(i_clk),
    .i_sync_rst(i_sync_rst),
    .if_bus(test_if_0.mst_port)
);

//! slave module
slv_mdl #(
    .ADDR_BIT_WIDTH(ADDR_BIT_WIDTH),
    .DATA_BIT_WIDTH(DATA_BIT_WIDTH)
) slv_mdl_0 (
    .i_clk(i_clk),
    .i_sync_rst(i_sync_rst),
    .if_bus(test_if_0.slv_port)
);

endmodule

`default_nettype wire
