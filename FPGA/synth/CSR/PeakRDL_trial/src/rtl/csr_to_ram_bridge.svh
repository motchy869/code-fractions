`ifndef CSR_TO_RAM_BRIDGE_IF_SVH_INCLUDED
`define CSR_TO_RAM_BRIDGE_IF_SVH_INCLUDED

//! Translate access from CSR to RAM operation.
extern module csr_to_ram_bridge #(
    parameter int WORD_BIT_WIDTH = 32, //! word bit width, **must be power of 2**
    parameter int BYTE_ADDR_BIT_WIDTH = 8, //! byte address bit width
    parameter int WORD_ADDR_BIT_WIDTH = BYTE_ADDR_BIT_WIDTH - $clog2(WORD_BIT_WIDTH/8), //! word address bit width
    parameter bit OUTPUT_REG_IS_USED_IN_RAM = 0 //! RAM output register option, 0/1: use/not use
)(
    input wire logic i_clk, //! clock signal
    input wire logic i_sync_rst, //! synchronous reset signal

    csr_to_ram_bridge_csr_side_if.slv_port if_csr_side, //! CSR-side slave interface
    csr_to_ram_bridge_ram_side_if.mst_port if_ram_side //! RAM-side master interface
);

`endif
