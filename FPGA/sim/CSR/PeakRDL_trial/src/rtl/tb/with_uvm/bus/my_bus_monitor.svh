// Verible directive
// verilog_lint: waive-start line-length

//! Some techniques used in this file are based on the following source:
//! - [UVM Register Model Example](https://www.chipverify.com/uvm/uvm-register-model-example)

`ifndef INCLUDED_FROM_MY_VERIF_PKG
    $fatal("include \"my_verif_pkg.svh\" instead of including this file");
    nonexistent_module_to_throw_a_custom_error_message_for invalid_inclusion();
`endif

`include "../../../axi4_lite_if_pkg.svh"

class my_bus_monitor extends uvm_monitor;
    `uvm_component_utils(my_bus_monitor)

    uvm_analysis_imp#(my_bus_collected_item, my_bus_monitor) m_analysis_export;
    uvm_analysis_port#(my_bus_collected_item) m_analysis_port_to_scoreboard;
    uvm_analysis_port#(my_bus_seq_item) m_analysis_port_to_reg_predictor;

    function new(string name, uvm_component parent);
        super.new(name, parent);
        m_analysis_export = new("m_analysis_export", this);
        m_analysis_port_to_scoreboard = new("m_analysis_port_to_scoreboard", this);
        m_analysis_port_to_reg_predictor = new("m_analysis_port_to_reg_predictor", this);
    endfunction

    function void write(my_bus_collected_item item);
        // Create an item for uvm_reg_predictor.
        if (item.data_is_read) begin
            my_bus_seq_item pkt = my_bus_seq_item::type_id::create("pkt");
            pkt.addr = item.rd_addr;
            pkt.data = item.rd_data;
            pkt.status = (item.rresp == axi4_lite_if_pkg::AXI4_RESP_OKAY) ? UVM_IS_OK : UVM_NOT_OK;
            m_analysis_port_to_reg_predictor.write(pkt);
        end
        if (item.data_is_written) begin
            my_bus_seq_item pkt = my_bus_seq_item::type_id::create("pkt");
            pkt.addr = item.wr_addr;
            pkt.data = item.wr_data;
            pkt.write = 1;
            pkt.wstrb = item.wstrb;
            pkt.status = (item.bresp == axi4_lite_if_pkg::AXI4_RESP_OKAY) ? UVM_IS_OK : UVM_NOT_OK;
            m_analysis_port_to_reg_predictor.write(pkt);
        end

        // ---------- Do something in the future. ----------
        // --------------------

        m_analysis_port_to_scoreboard.write(item);
    endfunction
endclass
