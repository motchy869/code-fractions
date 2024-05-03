`ifndef CSR_TO_RAM_BRIDGE_IF_SVH_INCLUDED
`define CSR_TO_RAM_BRIDGE_IF_SVH_INCLUDED

// Verible directive
// verilog_lint: waive-start parameter-name-style
// verilog_lint: waive-start line-length

`default_nettype none

//! CSR to RAM bridge CSR-side interface.
interface csr_to_ram_bridge_csr_side_if #(
    parameter int WORD_BIT_WIDTH = 32, //! word bit width, **must be power of 2**
    parameter int BYTE_ADDR_BIT_WIDTH = 8 //! byte address bit width
)(
    input wire logic i_clk //! clock signal
);
    logic acc_req; //! access request signal
    logic [BYTE_ADDR_BIT_WIDTH-1:0] byte_addr; //! byte address
    logic acc_req_is_wr; //! Indicates that the access request is write.
    logic [WORD_BIT_WIDTH-1:0] wr_data; //! write data
    logic [WORD_BIT_WIDTH-1:0] wr_bit_en; //! bit enable signal

    logic rd_ack; //! read acknowledge signal
    logic [WORD_BIT_WIDTH-1:0] rd_data; //! read data
    logic wr_ack; //! write acknowledge signal

    //! CSR is master.
    modport mst_port(
        output acc_req, //! access request signal
        output byte_addr, //! byte address
        output acc_req_is_wr, //! Indicates that the access request is write.
        output wr_data, //! write data
        output wr_bit_en, //! bit enable signal

        input rd_ack, //! read acknowledge signal
        input rd_data, //! read data
        input wr_ack //! write acknowledge signal
    );

    //! Bridge is slave.
    modport slv_port(
        input acc_req, //! access request signal
        input byte_addr, //! byte address
        input acc_req_is_wr, //! Indicates that the access request is write.
        input wr_data, //! write data
        input wr_bit_en, //! bit enable signal

        output rd_ack, //! read acknowledge signal
        output rd_data, //! read data
        output wr_ack //! write acknowledge signal
    );
endinterface

//! CSR to RAM bridge RAM-side interface.
interface csr_to_ram_bridge_ram_side_if #(
    parameter int WORD_BIT_WIDTH = 32, //! word bit width, **must be power of 2**
    parameter int WORD_ADDR_BIT_WIDTH = 6 //! word address bit width
)(
    input wire logic i_clk //! clock signal
);
    logic we; //! write enable signal
    logic [WORD_ADDR_BIT_WIDTH-1:0] word_addr; //! word address
    logic [WORD_BIT_WIDTH-1:0] rd_data; //! read back data from RAM
    logic [WORD_BIT_WIDTH/8-1:0] wr_byte_en; //! byte enable signal
    logic [WORD_BIT_WIDTH-1:0] wr_data; //! write data to RAM

    //! Bridge is master.
    modport mst_port (
        output we, //! write enable signal
        output word_addr, //! word address
        input rd_data, //! read back data from RAM
        output wr_byte_en, //! byte enable signal
        output wr_data //! write data to RAM
    );

    //! RAM is slave.
    modport slv_port (
        input we, //! write enable signal
        input word_addr, //! word address
        output rd_data, //! read back data from RAM
        input wr_byte_en, //! byte enable signal
        input wr_data //! write data to RAM
    );
endinterface

`default_nettype wire

`endif
