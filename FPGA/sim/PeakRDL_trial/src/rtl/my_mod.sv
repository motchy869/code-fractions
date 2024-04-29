// Verible directive
// verilog_lint: waive-start parameter-name-style
// verilog_lint: waive-start line-length

`include "ram_sp_wf.svh"
`include "axi4_lite_if_pkg.svh"
`include "axi4_lite_if.svh"
`include "csr/my_mod_csr_pkg.svh"
`include "csr/my_mod_csr.svh"

`default_nettype none

//! simple DUT to test my_mod_csr
module my_mod (
    input wire i_clk, //! clock signal
    input wire i_sync_rst, //! synchronous reset signal
    axi4_lite_if.slv_port if_s_axi4_lite //! AXI4-Lite slave interface
);
// ---------- parameters ----------
// --------------------

// ---------- internal signal and storage ----------
wire my_mod_csr_pkg::my_mod_csr__in_t w_csr_hw_if_in; //! input to CSR module
wire my_mod_csr_pkg::my_mod_csr__out_t w_csr_hw_if_out; //! output from CSR module
// --------------------

// ---------- instances ----------
//! CSR module
my_mod_csr my_mod_csr_inst (
    .clk(i_clk),
    .rst(i_sync_rst),

    .s_axi4lite_awready(if_s_axi4_lite.awready),
    .s_axi4lite_awvalid(if_s_axi4_lite.awvalid),
    .s_axi4lite_awaddr(if_s_axi4_lite.awaddr),
    .s_axi4lite_awprot(if_s_axi4_lite.awprot),
    .s_axi4lite_wready(if_s_axi4_lite.wready),
    .s_axi4lite_wvalid(if_s_axi4_lite.wvalid),
    .s_axi4lite_wdata(if_s_axi4_lite.wdata),
    .s_axi4lite_wstrb(if_s_axi4_lite.wstrb),
    .s_axi4lite_bready(if_s_axi4_lite.bready),
    .s_axi4lite_bvalid(if_s_axi4_lite.bvalid),
    .s_axi4lite_bresp(if_s_axi4_lite.bresp),
    .s_axi4lite_arready(if_s_axi4_lite.arready),
    .s_axi4lite_arvalid(if_s_axi4_lite.arvalid),
    .s_axi4lite_araddr(if_s_axi4_lite.araddr),
    .s_axi4lite_arprot(if_s_axi4_lite.arprot),
    .s_axi4lite_rready(if_s_axi4_lite.rready),
    .s_axi4lite_rvalid(if_s_axi4_lite.rvalid),
    .s_axi4lite_rdata(if_s_axi4_lite.rdata),
    .s_axi4lite_rresp(if_s_axi4_lite.rresp),

    .hw_if_in(w_csr_hw_if_in),
    .hw_if_out(w_csr_hw_if_out)
);
// --------------------

// ---------- Drive output signals. ----------
// --------------------


endmodule

`default_nettype wire
