`include "simple_if.svh"

`default_nettype none

//! slave module simply implements a memory
module slv_mdl #(
    parameter int ADDR_BIT_WIDTH = 2, //! address bit width
    parameter int DATA_BIT_WIDTH = 8 //! data bit width
) (
    input wire logic i_clk, //! clock
    input wire logic i_sync_rst, //! reset
    simple_if.slv_port if_bus //! bus interface to the master
);
// ---------- internal signal and storage ----------
var logic [DATA_BIT_WIDTH-1:0] r_mem [2**ADDR_BIT_WIDTH]; //! memory
var logic r_rd_data_vld; //! read back data valid
var logic [DATA_BIT_WIDTH-1:0] r_rd_data; //! read back data
// --------------------

// ---------- Drive output signals. ----------
assign if_bus.rd_data_vld = r_rd_data_vld;
assign if_bus.rd_data = r_rd_data;
// --------------------

//! Read memory data.
always_ff @(posedge i_clk or posedge i_sync_rst) begin
    if (i_sync_rst) begin
        r_rd_data_vld <= 1'b0;
        r_rd_data <= '{default:'0};
    end else if (if_bus.rd_req) begin
        r_rd_data_vld <= 1'b1;
        r_rd_data <= r_mem[if_bus.addr];
    end else if (!if_bus.rd_req) begin
        r_rd_data_vld <= 1'b0;
    end
end

//! Reset/Write memory data.
always_ff @(posedge i_clk or posedge i_sync_rst)
    if (i_sync_rst) begin
        r_mem <= '{default:'0};
    end else if (if_bus.wr_req) begin
        r_mem[if_bus.addr] <= if_bus.wr_data;
    end
endmodule

`default_nettype wire
