// Verible directive
// verilog_lint: waive-start parameter-name-style
// verilog_lint: waive-start line-length

`default_nettype none

//! interface to DUT
interface dut_if #(
    parameter type T_ELEM = logic [7:0]
)(
    input wire logic i_clk //! clock signal
);
    // signals for DUT's upstream-side interface
    logic wr_en;
    T_ELEM in_elem;
    logic full;

    // signals for DUT's downstream-side interface
    logic rd_en;
    T_ELEM out_elem;
    logic empty;
endinterface

//! top module
module top (
    input wire logic CLK, //! clock input
    input wire logic RST, //! reset input
    output reg [2:0] LED_RGB //! RGB LED output
);
// ---------- imports ----------
// --------------------

// ---------- parameters ----------
localparam int unsigned BW_ELEM = 8; //! bit width of FIFO element
localparam int unsigned FIFO_DEPTH = 16; //! FIFO depth
// --------------------

// ---------- parameter validation ----------
// --------------------

// ---------- functions ----------
// --------------------

// ---------- signals and storage ----------
wire logic i_clk = CLK; //! clock input
var logic [1:0] r_rst_cdc; //! 2 FFs for reset signal
wire logic g_sync_rst = r_rst_cdc[1]; //! synchronized reset signal
typedef logic [BW_ELEM-1:0] elem_t; //! element data type
// --------------------

// ---------- instances ----------
//! interface to DUT
(* keep = "true" *) dut_if #(
    .T_ELEM(elem_t)
) dut_if (.i_clk(i_clk));

//! DUT instance
(* keep = "true" *) sgl_clk_pipe_fifo_v0_1_0 #(
    .T_ELEM(elem_t),
    .DEPTH(FIFO_DEPTH)
) dut (
    .i_clk(i_clk),
    .i_sync_rst(g_sync_rst),
    .i_wr_en(dut_if.wr_en),
    .i_in_elem(dut_if.in_elem),
    .o_full(dut_if.full),
    .i_rd_en(dut_if.rd_en),
    .o_out_elem(dut_if.out_elem),
    .o_empty(dut_if.empty)
);

//! upstream
(* keep = "true" *) upstream #(.T_ELEM(elem_t)) upstream_0 (
    .i_clk(i_clk),
    .i_sync_rst(g_sync_rst),
    .o_wr_en(dut_if.wr_en),
    .o_out_elem(dut_if.in_elem),
    .i_full(dut_if.full)
);

//! downstream
(* keep = "true" *) downstream #(.T_ELEM(elem_t)) downstream_0 (
    .i_clk(i_clk),
    .i_sync_rst(g_sync_rst),
    .o_rd_en(dut_if.rd_en),
    .i_in_elem(dut_if.out_elem),
    .i_empty(dut_if.empty)
);
// --------------------

// ---------- Drives output signals. ----------
assign LED_RGB[0] = dut_if.wr_en;
assign LED_RGB[1] = dut_if.rd_en;
assign LED_RGB[2] = dut_if.empty;
// --------------------

// ---------- blocks ----------
//! Synchronize reset signal
always_ff @(posedge i_clk) begin: blk_rst_cdc
    r_rst_cdc <= {r_rst_cdc[0], RST};
end
// --------------------
endmodule

`default_nettype wire
