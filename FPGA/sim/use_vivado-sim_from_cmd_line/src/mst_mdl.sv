// Verible directive
// verilog_lint: waive-start parameter-name-style

`include "simple_if.svh"
`include "macros_def.svh"

`default_nettype none

//! A master module simply accesses the slave memory.
//! This module writes all address with incremental data (0,1,2, ...), then reads back.
//! This cycle is repeated endlessly.
module mst_mdl #(
    parameter int ADDR_BIT_WIDTH = 2, //! address bit width
    parameter int DATA_BIT_WIDTH = 8 //! data bit width
) (
    input wire logic i_clk, //! clock
    input wire logic i_sync_rst, //! reset
    simple_if.mst_port if_bus //! bus interface to the slave
);
// ---------- parameters ----------
localparam int MAX_ADDR = 2**ADDR_BIT_WIDTH-1; //! maximum address
// --------------------

// ---------- internal signal and storage ----------
typedef enum {
    OP_STATE_RST,
    OP_STATE_WRITE,
    OP_STATE_READ
} op_state_e;

var op_state_e r_curr_state; //! current operation state
op_state_e g_next_state; //! operation state right after the next clock rising-edge
wire logic g_state_trans_evt; //! State transition event signal indicating that the operation state changes at next clock rising-edge.
assign g_state_trans_evt = g_next_state != r_curr_state;
var logic [ADDR_BIT_WIDTH-1:0] r_addr; //! R/W address
var logic [DATA_BIT_WIDTH-1:0] r_wr_data; //! write data
// --------------------

// ---------- Drive output signals. ----------
assign if_bus.addr = r_addr;
assign if_bus.rd_req = (r_curr_state == OP_STATE_READ);
assign if_bus.wr_req = (r_curr_state == OP_STATE_WRITE);
assign if_bus.wr_data = r_wr_data;
// --------------------

//! Decide next operation state.
always_comb begin: next_op_state_decision
    g_next_state = r_curr_state;

    case (r_curr_state)
        OP_STATE_RST: begin
            if (i_sync_rst) begin
                g_next_state = OP_STATE_RST;
            end else begin
                g_next_state = OP_STATE_WRITE;
            end
        end
        OP_STATE_WRITE: begin
            if (i_sync_rst) begin
                g_next_state = OP_STATE_RST;
            end else if (r_addr == MAX_ADDR) begin
                g_next_state = OP_STATE_READ;
            end
        end
        OP_STATE_READ: begin
            if (i_sync_rst) begin
                g_next_state = OP_STATE_RST;
            end else if (r_addr == MAX_ADDR) begin
                g_next_state = OP_STATE_WRITE;
            end
        end
        default: begin
            $error("unexpected state");
        end
    endcase
end

//! Update operation state.
always_ff @(posedge i_clk) begin: op_state_update
    if (i_sync_rst) begin
        r_curr_state <= OP_STATE_RST;
    end else begin
        r_curr_state <= g_next_state;
    end
end

//! Control address.
always_ff @(posedge i_clk) begin: addr_control
    if (i_sync_rst || g_state_trans_evt) begin
        r_addr <= '0;
    end else begin
        `INCR_NON_BLK(r_addr)
    end
end

//! Control write data.
always_ff @(posedge i_clk) begin: wr_data_control
    if (i_sync_rst || g_state_trans_evt) begin
        r_wr_data <= '0;
    end else if (g_next_state == OP_STATE_WRITE) begin
        `INCR_NON_BLK(r_wr_data)
    end
end

endmodule

`default_nettype wire

`include "macros_undef.svh"
