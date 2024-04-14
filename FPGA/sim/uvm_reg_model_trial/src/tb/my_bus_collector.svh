// Verible directive
// verilog_lint: waive-start line-length

//! Some techniques used in this file are based on the following source:
//! - [UVM Register Model Example](https://www.chipverify.com/uvm/uvm-register-model-example)

`ifndef MY_VERIF_PKG_SVH_INCLUDED
    $fatal("compile \"my_verif_pkg.sv\" instead of including this file");
`endif

`include "../axi4_lite_if.svh"

class my_bus_collector extends uvm_component;
    `uvm_component_utils(my_bus_collector)

    virtual axi4_lite_if m_vif;
    uvm_analysis_port#(my_bus_collected_item) m_analysis_port;

    function new(string name, uvm_component parent);
        super.new(name, parent);
        m_analysis_port = new("m_analysis_port", this);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual axi4_lite_if)::get(uvm_root::get(), "uvm_test_top", "bus_vif", m_vif)) begin
            `uvm_fatal("NO-VIF", {"virtual interface must be set for: ", get_full_name(), ".bus_vif"})
        end
    endfunction

    extern virtual task get_response();

    virtual task run_phase(uvm_phase phase);
        forever begin
            get_response();
        end
    endtask
endclass

task my_bus_collector::get_response();
    bit data_is_read;
    bit data_is_written;
    my_bus_collected_item item;

    forever begin
        `ifdef XILINX_SIMULATOR // Vivado 2023.2 crushes with SIGSEGV when clocking block is used.
            `define WAIT_CLK_POSEDGE @(posedge m_vif.clk)
        `else
            `define WAIT_CLK_POSEDGE @m_vif.mst_cb
        `endif

        `WAIT_CLK_POSEDGE begin
            data_is_read = 1'b0;
            data_is_written = 1'b0;

            if (m_vif.rready && m_vif.rvalid) begin
                data_is_read = 1'b1;
                item.rd_addr = m_vif.araddr;
                item.rd_data = m_vif.rdata;
                item.rresp = m_vif.rresp;
                `uvm_info("INFO", $sformatf("data is read: addr=%h, data=%h, rresp=%h", item.rd_addr, item.rd_data, item.rresp), UVM_MEDIUM);
            end

            if (m_vif.awvalid && m_vif.wvalid && m_vif.bready && m_vif.awready && m_vif.wready && m_vif.bready) begin
                data_is_written = 1'b1;
                item.wr_addr = m_vif.awaddr;
                item.wr_data = m_vif.wdata;
                item.wstrb = m_vif.wstrb;
                item.bresp = m_vif.bresp;
                `uvm_info("INFO", $sformatf("data is written: addr=%h, data=%h, wstrb=%h, bresp=%h", item.wr_addr, item.wr_data, item.wstrb, item.bresp), UVM_MEDIUM);
            end
        end

        if (data_is_read || data_is_written) begin
            m_analysis_port.write(item);
        end

        `undef WAIT_CLK_POSEDGE
    end
endtask
