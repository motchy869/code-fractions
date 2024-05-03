// Verible directive
// verilog_lint: waive-start parameter-name-style
// verilog_lint: waive-start line-length

`default_nettype none

//! wrapper module for `my_mod_wrap_sv`
//! - Eliminate SystemVerilog code so that this module can be used in Block Design in Vivado.
module my_mod_wrap #(
    parameter integer MY_MOD_ADDR_SPACE_SIZE_BYTE = 'h40, //! size of `my_mod` address space in byte
    parameter integer AXI4_LITE_ADDR_BIT_WIDTH = $clog2(MY_MOD_ADDR_SPACE_SIZE_BYTE), //! bit width of AXI4-Lite address bus of `my_mod`
    parameter integer AXI4_LITE_DATA_BIT_WIDTH = 32 // bit width of AXI4-Lite data bus
)(
    (* X_INTERFACE_INFO = "xilinx.com:signal:clock:1.0 i_clk CLK" *)
    (* X_INTERFACE_PARAMETER = "ASSOCIATED_BUSIF s_axi4_lite, ASSOCIATED_RESET i_sync_rst, FREQ_HZ 125000000" *)
    input wire i_clk, //! clock signal
    (* X_INTERFACE_INFO = "xilinx.com:signal:reset:1.0 i_sync_rst RST" *)
    (* X_INTERFACE_PARAMETER = "POLARITY ACTIVE_HIGH" *)
    input wire i_sync_rst, //! synchronous reset signal

    //! @virtualbus s_axi4_lite @dir in
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi4_lite AWADDR" *)
    input wire [AXI4_LITE_ADDR_BIT_WIDTH-1:0] s_axi4_lite_awaddr, //! write address
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi4_lite AWPROT" *)
    input wire [2:0] s_axi4_lite_awprot, //! write channel Protection type
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi4_lite AWVALID" *)
    input wire s_axi4_lite_awvalid, //! write address valid
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi4_lite AWREADY" *)
    output wire s_axi4_lite_awready, //! write address ready
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi4_lite WDATA" *)
    input wire [AXI4_LITE_DATA_BIT_WIDTH-1:0] s_axi4_lite_wdata, //! write data
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi4_lite WSTRB" *)
    input wire [(AXI4_LITE_DATA_BIT_WIDTH/8)-1:0] s_axi4_lite_wstrb, //! write strobes
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi4_lite WVALID" *)
    input wire s_axi4_lite_wvalid, //! write valid
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi4_lite WREADY" *)
    output wire s_axi4_lite_wready, //! write ready
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi4_lite BRESP" *)
    output wire [1:0] s_axi4_lite_bresp, //! write response
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi4_lite BVALID" *)
    output wire s_axi4_lite_bvalid, //! write response valid
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi4_lite BREADY" *)
    input wire s_axi4_lite_bready, //! response ready
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi4_lite ARADDR" *)
    input wire [AXI4_LITE_ADDR_BIT_WIDTH-1:0] s_axi4_lite_araddr, //! read address
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi4_lite ARPROT" *)
    input wire [2:0] s_axi4_lite_arprot, //! Protection type
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi4_lite ARVALID" *)
    input wire s_axi4_lite_arvalid, //! read address valid
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi4_lite ARREADY" *)
    output wire s_axi4_lite_arready, //! read address ready
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi4_lite RDATA" *)
    output wire [AXI4_LITE_DATA_BIT_WIDTH-1:0] s_axi4_lite_rdata, //! read data
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi4_lite RRESP" *)
    output wire [1:0] s_axi4_lite_rresp, //! read response
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi4_lite RVALID" *)
    output wire s_axi4_lite_rvalid, //! read valid
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi4_lite RREADY" *)
    input wire s_axi4_lite_rready //! read ready
    //! @end
);

my_mod_wrap_sv my_mod_wrap_sv_0 (
    .i_clk(i_clk),
    .i_sync_rst(i_sync_rst),

    .s_axi4_lite_awaddr(s_axi4_lite_awaddr),
    .s_axi4_lite_awprot(s_axi4_lite_awprot),
    .s_axi4_lite_awvalid(s_axi4_lite_awvalid),
    .s_axi4_lite_awready(s_axi4_lite_awready),
    .s_axi4_lite_wdata(s_axi4_lite_wdata),
    .s_axi4_lite_wstrb(s_axi4_lite_wstrb),
    .s_axi4_lite_wvalid(s_axi4_lite_wvalid),
    .s_axi4_lite_wready(s_axi4_lite_wready),
    .s_axi4_lite_bresp(s_axi4_lite_bresp),
    .s_axi4_lite_bvalid(s_axi4_lite_bvalid),
    .s_axi4_lite_bready(s_axi4_lite_bready),
    .s_axi4_lite_araddr(s_axi4_lite_araddr),
    .s_axi4_lite_arprot(s_axi4_lite_arprot),
    .s_axi4_lite_arvalid(s_axi4_lite_arvalid),
    .s_axi4_lite_arready(s_axi4_lite_arready),
    .s_axi4_lite_rdata(s_axi4_lite_rdata),
    .s_axi4_lite_rresp(s_axi4_lite_rresp),
    .s_axi4_lite_rvalid(s_axi4_lite_rvalid),
    .s_axi4_lite_rready(s_axi4_lite_rready)
);

endmodule

`default_nettype wire
