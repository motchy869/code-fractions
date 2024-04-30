// Verible directive
// verilog_lint: waive-start line-length

//! Some techniques used in this file are based on the following source:
//! - [UVM Register Model Example](https://www.chipverify.com/uvm/uvm-register-model-example)

`ifndef INCLUDED_FROM_MY_VERIF_PKG
    $fatal("compile \"my_verif_pkg.sv\" instead of including this file");
`endif

`include "../../axi4_lite_if_pkg.svh"

class my_bus_driver extends uvm_driver#(my_bus_seq_item);
    `uvm_component_utils(my_bus_driver)

    virtual axi4_lite_if m_vif;

    function new(string name = "my_bus_driver", uvm_component parent);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual axi4_lite_if)::get(null, "uvm_test_top", "g_bus_vif", m_vif)) begin
            `uvm_fatal("NO-VIF", {"virtual interface must be set for: ", "uvm_test_top", ".g_bus_vif"})
        end
    endfunction

    extern virtual task read_access(
        input bit [my_verif_params_pkg::AXI4_LITE_ADDR_BIT_WIDTH-1:0] addr,
        ref bit [my_verif_params_pkg::AXI4_LITE_DATA_BIT_WIDTH-1:0] data,
        ref uvm_status_e status
    );

    extern virtual task write_access(
        input bit [my_verif_params_pkg::AXI4_LITE_ADDR_BIT_WIDTH-1:0] addr,
        input bit [my_verif_params_pkg::AXI4_LITE_DATA_BIT_WIDTH-1:0] data,
        input bit [my_verif_params_pkg::AXI4_LITE_DATA_BIT_WIDTH/8-1:0] wstrb,
        ref uvm_status_e status
    );

    extern virtual task run_phase(uvm_phase phase);
endclass

`ifdef XILINX_SIMULATOR // Vivado 2023.2 crushes with SIGSEGV when clocking block is used.
    `define WAIT_CLK_POSEDGE @(posedge m_vif.clk)
`else
    `define WAIT_CLK_POSEDGE @m_vif.mst_cb
`endif

task my_bus_driver::read_access(
    input bit [my_verif_params_pkg::AXI4_LITE_ADDR_BIT_WIDTH-1:0] addr,
    ref bit [my_verif_params_pkg::AXI4_LITE_DATA_BIT_WIDTH-1:0] data,
    ref uvm_status_e status
);
    axi4_lite_if_pkg::axi4_resp_t resp;

    axi4_lite_if_pkg::axi4_lite_access#(
        .AXI4_LITE_ADDR_BIT_WIDTH(my_verif_params_pkg::AXI4_LITE_ADDR_BIT_WIDTH),
        .AXI4_LITE_DATA_BIT_WIDTH(my_verif_params_pkg::AXI4_LITE_DATA_BIT_WIDTH)
    )::axi4_lite_read(m_vif, addr, data, resp);
    status = (resp == axi4_lite_if_pkg::AXI4_RESP_OKAY) ? UVM_IS_OK : UVM_NOT_OK;
endtask

task my_bus_driver::write_access(
    input bit [my_verif_params_pkg::AXI4_LITE_ADDR_BIT_WIDTH-1:0] addr,
    input bit [my_verif_params_pkg::AXI4_LITE_DATA_BIT_WIDTH-1:0] data,
    input bit [my_verif_params_pkg::AXI4_LITE_DATA_BIT_WIDTH/8-1:0] wstrb,
    ref uvm_status_e status
);
    axi4_lite_if_pkg::axi4_resp_t resp;

    axi4_lite_if_pkg::axi4_lite_access#(
        .AXI4_LITE_ADDR_BIT_WIDTH(my_verif_params_pkg::AXI4_LITE_ADDR_BIT_WIDTH),
        .AXI4_LITE_DATA_BIT_WIDTH(my_verif_params_pkg::AXI4_LITE_DATA_BIT_WIDTH)
    )::axi4_lite_write(m_vif, addr, data, wstrb, resp);
    status = (resp == axi4_lite_if_pkg::AXI4_RESP_OKAY) ? UVM_IS_OK : UVM_NOT_OK;
endtask

task my_bus_driver::run_phase(uvm_phase phase);
    my_bus_seq_item pkt;

    phase.raise_objection(this);
    m_vif.reset_mst_port();

    forever begin
        // `uvm_info("INFO", "Waiting for a packet", UVM_DEBUG);
        seq_item_port.get_next_item(pkt);
        // `uvm_info("INFO", "Got a packet", UVM_DEBUG);
        unique case (pkt.cmd)
            my_bus_seq_item::CMD_NOP:
                ; // nothing to do
            my_bus_seq_item::CMD_NORMAL: begin
                if (pkt.write) begin
                    write_access(pkt.addr, pkt.data, pkt.wstrb, pkt.status);
                end else begin
                    read_access(pkt.addr, pkt.data, pkt.status);
                end
            end
        endcase
        // If `provides_responses` is set to 1 in `uvm_adapter` (or its child) class, `item_done` method in `uvm_driver` (or its child) must return an `uvm_sequence_item`, otherwise `uvm_reg.read` and `uvm_reg.write` method get stuck.
        seq_item_port.item_done(pkt);

        if (pkt.is_last_item) begin
            `uvm_info("INFO", "Got last item in the sequence.", UVM_MEDIUM);
            phase.drop_objection(this);
            break;
        end
    end
endtask

`undef WAIT_CLK_POSEDGE
