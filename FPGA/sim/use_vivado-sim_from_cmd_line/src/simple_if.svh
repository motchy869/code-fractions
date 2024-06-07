`ifndef SIMPLE_IF_SVH_INCLUDED
`define SIMPLE_IF_SVH_INCLUDED

`default_nettype none

interface simple_if#(
    parameter int ADDR_BIT_WIDTH = 2, //! address bit width
    parameter int DATA_BIT_WIDTH = 8 //! data bit width
);
    wire logic [ADDR_BIT_WIDTH-1:0] addr; //! address
    wire logic rd_req; //! read request
    wire logic wr_req; //! write request
    wire logic rd_data_vld; //! read back data valid
    wire logic [DATA_BIT_WIDTH-1:0] rd_data; //! read back data
    wire logic [DATA_BIT_WIDTH-1:0] wr_data; //! write data

    modport mst_port (
        output addr, //! address
        output rd_req, //! read request
        output wr_req, //! write request
        input rd_data_vld, //! read back data valid
        input rd_data, //! read back data
        output wr_data //! write data
    );
    modport slv_port (
        input addr, //! address
        input rd_req, //! read request
        input wr_req, //! write request
        output rd_data_vld, //! read back data valid
        output rd_data, //! read back data
        input wr_data //! write data
    );
endinterface

`default_nettype wire

`endif
