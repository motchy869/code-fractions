// Verible directive
// verilog_lint: waive-start parameter-name-style
// verilog_lint: waive-start line-length

`include "my_mod.svh"

`default_nettype none

//! wrapper module for `my_mod`
//! - Convert from SystemVerilog interface ports to Verilog ports.
module my_mod_wrap_sv#(
    localparam int MY_MOD_ADDR_SPACE_SIZE_BYTE = 'h40, //! size of `my_mod` address space in byte
    localparam int AXI4_LITE_ADDR_BIT_WIDTH = $clog2(MY_MOD_ADDR_SPACE_SIZE_BYTE), //! bit width of AXI4-Lite address bus of `my_mod`
    localparam int AXI4_LITE_DATA_BIT_WIDTH = 32 // bit width of AXI4-Lite data bus
)(
    (* X_INTERFACE_INFO = "xilinx.com:signal:clock:1.0 i_clk CLK" *)
    (* X_INTERFACE_PARAMETER = "ASSOCIATED_BUSIF s_axi4_lite, ASSOCIATED_RESET i_sync_rst, FREQ_HZ 125000000" *)
    input wire logic i_clk, //! clock signal
    (* X_INTERFACE_INFO = "xilinx.com:signal:reset:1.0 i_sync_rst RST" *)
    (* X_INTERFACE_PARAMETER = "POLARITY ACTIVE_HIGH" *)
    input wire logic i_sync_rst, //! synchronous reset signal

    //! @virtualbus s_axi4_lite @dir in
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi4_lite AWADDR" *)
    input wire logic [AXI4_LITE_ADDR_BIT_WIDTH-1:0] s_axi4_lite_awaddr, //! write address
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi4_lite AWPROT" *)
    input wire logic [2:0] s_axi4_lite_awprot, //! write channel Protection type
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi4_lite AWVALID" *)
    input wire logic s_axi4_lite_awvalid, //! write address valid
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi4_lite AWREADY" *)
    output wire logic s_axi4_lite_awready, //! write address ready
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi4_lite WDATA" *)
    input wire logic [AXI4_LITE_DATA_BIT_WIDTH-1:0] s_axi4_lite_wdata, //! write data
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi4_lite WSTRB" *)
    input wire logic [(AXI4_LITE_DATA_BIT_WIDTH/8)-1:0] s_axi4_lite_wstrb, //! write strobes
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi4_lite WVALID" *)
    input wire logic s_axi4_lite_wvalid, //! write valid
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi4_lite WREADY" *)
    output wire logic s_axi4_lite_wready, //! write ready
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi4_lite BRESP" *)
    output wire logic [1:0] s_axi4_lite_bresp, //! write response
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi4_lite BVALID" *)
    output wire logic s_axi4_lite_bvalid, //! write response valid
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi4_lite BREADY" *)
    input wire logic s_axi4_lite_bready, //! response ready
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi4_lite ARADDR" *)
    input wire logic [AXI4_LITE_ADDR_BIT_WIDTH-1:0] s_axi4_lite_araddr, //! read address
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi4_lite ARPROT" *)
    input wire logic [2:0] s_axi4_lite_arprot, //! Protection type
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi4_lite ARVALID" *)
    input wire logic s_axi4_lite_arvalid, //! read address valid
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi4_lite ARREADY" *)
    output wire logic s_axi4_lite_arready, //! read address ready
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi4_lite RDATA" *)
    output wire logic [AXI4_LITE_DATA_BIT_WIDTH-1:0] s_axi4_lite_rdata, //! read data
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi4_lite RRESP" *)
    output wire logic [1:0] s_axi4_lite_rresp, //! read response
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi4_lite RVALID" *)
    output wire logic s_axi4_lite_rvalid, //! read valid
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi4_lite RREADY" *)
    input wire logic s_axi4_lite_rready //! read ready
    //! @end
);

// ---------- parameters ----------
// --------------------

// ---------- internal signal and storage ----------
// --------------------

// ---------- instances ----------
//! AXI4-Lite interface for DUT
axi4_lite_if#(
    .ADDR_BIT_WIDTH(AXI4_LITE_ADDR_BIT_WIDTH),
    .DATA_BIT_WIDTH(AXI4_LITE_DATA_BIT_WIDTH)
) axi4_lite_if_0 (
    .i_clk(i_clk)
);

assign axi4_lite_if_0.awaddr = s_axi4_lite_awaddr;
assign axi4_lite_if_0.awprot = s_axi4_lite_awprot;
assign axi4_lite_if_0.awvalid = s_axi4_lite_awvalid;
assign axi4_lite_if_0.wdata = s_axi4_lite_wdata;
assign axi4_lite_if_0.wstrb = s_axi4_lite_wstrb;
assign axi4_lite_if_0.wvalid = s_axi4_lite_wvalid;
assign axi4_lite_if_0.bready = s_axi4_lite_bready;
assign axi4_lite_if_0.araddr = s_axi4_lite_araddr;
assign axi4_lite_if_0.arprot = s_axi4_lite_arprot;
assign axi4_lite_if_0.arvalid = s_axi4_lite_arvalid;
assign axi4_lite_if_0.rready = s_axi4_lite_rready;

//! DUT instance
my_mod my_mod_0 (
    .i_clk(i_clk),
    .i_sync_rst(i_sync_rst),
    .if_s_axi4_lite(axi4_lite_if_0)
);
// --------------------

// ---------- Drives output signals. ----------
assign s_axi4_lite_awready = axi4_lite_if_0.awready;
assign s_axi4_lite_wready = axi4_lite_if_0.wready;
assign s_axi4_lite_bresp = axi4_lite_if_0.bresp;
assign s_axi4_lite_bvalid = axi4_lite_if_0.bvalid;
assign s_axi4_lite_arready = axi4_lite_if_0.arready;
assign s_axi4_lite_rdata = axi4_lite_if_0.rdata;
assign s_axi4_lite_rresp = axi4_lite_if_0.rresp;
assign s_axi4_lite_rvalid = axi4_lite_if_0.rvalid;
// --------------------
endmodule

`default_nettype wire
