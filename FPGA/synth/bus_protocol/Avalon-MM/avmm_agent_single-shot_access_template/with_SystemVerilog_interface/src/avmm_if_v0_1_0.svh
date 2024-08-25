`ifndef AVMM_IF_V0_1_0_SVH_INCLUDED
`define AVMM_IF_V0_1_0_SVH_INCLUDED

// Verible directive
// verilog_lint: waive-start parameter-name-style
// verilog_lint: waive-start line-length
// verilog_lint: waive-start interface-name-style

//! Avalon Memory-Mapped Interface.
//!
//! Statements in modport's descriptions are quoted from Table 9. "Avalon Memory Mapped Signal Roles" in "Avalon Interface Specifications".
//!
//! This is a slightly-modified version of the original file published on the following web page:
//!
//! [https://peakrdl-regblock.readthedocs.io/en/latest/cpuif/avalon.html](https://peakrdl-regblock.readthedocs.io/en/latest/cpuif/avalon.html)
//!
//! Features currently not supported:
//!
//! 1. ```lock``` signal
//!
//! 2. burst access
interface avmm_if_v0_1_0 #(
    parameter int unsigned AVMM_ADDR_BIT_WIDTH = 32, //! Address bit width. Note that in default Avalon uses **byte** addressing in hosts and **word** addressing in agents.
    parameter int unsigned AVMM_DATA_BIT_WIDTH = 32 //! data bit width
)(
    input wire i_clk //! clock
);
    // To avoid circular dependency, put the definition of avmm_resp_t which is the same as the one in avmm_if_pkg_v0_1_0.
    typedef enum logic [1:0] {
        AVMM_RESP_OKAY = 2'b00,
        AVMM_RESP_RESERVED = 2'b01,
        AVMM_RESP_SLVERR = 2'b10,
        AVMM_RESP_DECODEERROR = 2'b11
    } avmm_resp_t;

    // command
    logic read;
    logic write;
    logic waitrequest;
    logic [AVMM_ADDR_BIT_WIDTH-1:0] address;
    logic [AVMM_DATA_BIT_WIDTH-1:0] writedata;
    logic [AVMM_DATA_BIT_WIDTH/8-1:0] byteenable;

    // response
    logic readdatavalid;
    logic writeresponsevalid;
    logic [AVMM_DATA_BIT_WIDTH-1:0] readdata;
    avmm_resp_t [1:0] response;

    // parameter validation
    generate
        if ((AVMM_DATA_BIT_WIDTH > 8) && !($bits(byteenable) inside {2, 4, 8, 16, 32, 64, 128})) begin: gen_byteenable_bit_width_validation
            nonexistent_module_to_throw_a_custom_error_message_for invalid_byteenable_bit_width();
        end

        if (!($bits(readdata) inside {8, 16, 32, 64, 128, 256, 512, 1024})) begin: gen_readdata_bit_width_validation
            nonexistent_module_to_throw_a_custom_error_message_for invalid_readdata_bit_width();
        end

        if (!($bits(writedata) inside {8, 16, 32, 64, 128, 256, 512, 1024})) begin: gen_writedata_bit_width_validation
            nonexistent_module_to_throw_a_custom_error_message_for invalid_writedata_bit_width();
        end
    endgenerate

    modport hst_pt (
        output read, //! Asserted to indicate a read transfer.
        output write, //! Asserted to indicate a write transfer.
        input waitrequest, //! An agent asserts waitrequest when unable to respond to a read or write request.
        output address, //! By default, the address signal represents a byte address.
        output writedata, //! data for write transfers
        output byteenable, //! Enables one or more specific byte lanes during transfers on interfaces of width greater than 8 bits.

        input readdatavalid, //! Used for variable-latency, pipelined read transfers. When asserted, indicates that the readdata signal contains valid data.
        input writeresponsevalid, //! When asserted, the value on the response signal is a valid write response.
        input readdata, //! The readdata driven from the agent to the host in response to a read transfer.
        input response //! The signal that carries the response status.
    );

    modport agt_pt (
        input read, //! Refer to the description of the host interface.
        input write, //! Refer to the description of the host interface.
        output waitrequest, //! Refer to the description of the host interface.
        input address, //! Refer to the description of the host interface.
        input writedata, //! Refer to the description of the host interface.
        input byteenable, //! Refer to the description of the host interface.

        output readdatavalid, //! Refer to the description of the host interface.
        output writeresponsevalid, //! Refer to the description of the host interface.
        output readdata, //! Refer to the description of the host interface.
        output response //! Refer to the description of the host interface.
    );
endinterface

`endif // AVMM_IF_V0_1_0_SVH_INCLUDED
