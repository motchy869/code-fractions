// Verible directive
// verilog_lint: waive-start line-length

//! Some techniques used in this file are based on the following source:
//! - [UVM Register Model Example](https://www.chipverify.com/uvm/uvm-register-model-example)

`ifndef INCLUDED_FROM_MY_VERIF_PKG
    $fatal("include \"my_verif_pkg.svh\" instead of including this file");
    nonexistent_module_to_throw_a_custom_error_message_for invalid_inclusion();
`endif

`include "../../../axi4_lite_if.svh"

class my_bus_collector extends uvm_component;
    bus_vif_t m_vif;
    uvm_analysis_port#(my_bus_collected_item) m_analysis_port;
    my_bus_collected_item m_collected_item_queue[$];

    `uvm_component_utils_begin(my_bus_collector)
        `uvm_field_queue_object(m_collected_item_queue, UVM_DEFAULT | UVM_NOCOMPARE | UVM_NOPRINT | UVM_NOPACK)
    `uvm_component_utils_end

    function new(string name, uvm_component parent);
        super.new(name, parent);
        m_analysis_port = new("m_analysis_port", this);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(bus_vif_t)::get(null, "uvm_test_top", "g_bus_vif", m_vif)) begin
            `uvm_fatal("NO-VIF", {"virtual interface must be set for: ", "uvm_test_top", ".g_bus_vif"})
        end
    endfunction

    extern virtual task task_monitor_read_access();
    extern virtual task task_monitor_write_access();
    extern virtual task run_phase(uvm_phase phase);
endclass

// (1)
// `ifdef XILINX_SIMULATOR // Vivado 2023.2 crashes with SIGSEGV when clocking block is used.
//     `define WAIT_CLK_POSEDGE @(posedge m_vif.i_clk)
// `else
//     `define WAIT_CLK_POSEDGE @vif.mst_cb
// `endif
// (2) Clocking block is buggy in Xcelium, so we decided to simply use `@(posedge m_vif.i_clk)`
`define WAIT_CLK_POSEDGE @(posedge m_vif.i_clk)

task my_bus_collector::task_monitor_read_access();
    forever begin
        `WAIT_CLK_POSEDGE begin
            if (m_vif.rready && m_vif.rvalid) begin
                my_bus_collected_item item = my_bus_collected_item::type_id::create("item");
                item.data_is_read = 1'b1;
                item.rd_addr = m_vif.araddr;
                item.rd_data = m_vif.rdata;
                item.rresp = m_vif.rresp;
                `uvm_info("INFO", $sformatf("data is read: addr=%h, data=%h, rresp=%h", item.rd_addr, item.rd_data, item.rresp), UVM_MEDIUM);
                m_collected_item_queue.push_back(item);
            end
        end
    end
endtask

task my_bus_collector::task_monitor_write_access();
    forever begin
        `WAIT_CLK_POSEDGE begin
            if (m_vif.awvalid && m_vif.wvalid && m_vif.bready && m_vif.awready && m_vif.wready) begin
                my_bus_collected_item item = my_bus_collected_item::type_id::create("item");
                item.data_is_written = 1'b1;
                item.wr_addr = m_vif.awaddr;
                item.wr_data = m_vif.wdata;
                item.wstrb = m_vif.wstrb;

                // Note that BRESP can comes after WREADY.
                if (!(m_vif.bready && m_vif.bvalid)) begin
                    wait(m_vif.bready && m_vif.bvalid);
                    `WAIT_CLK_POSEDGE;
                end

                item.bresp = m_vif.bresp;
                `uvm_info("INFO", $sformatf("data is written: addr=%h, data=%h, wstrb=%h, bresp=%h", item.wr_addr, item.wr_data, item.wstrb, item.bresp), UVM_MEDIUM);
                m_collected_item_queue.push_back(item);
            end
        end
    end
endtask

task my_bus_collector::run_phase(uvm_phase phase);
    fork
        task_monitor_read_access();
        task_monitor_write_access();
    join_none

    forever begin
        wait(m_collected_item_queue.size() > 0);
        m_analysis_port.write(m_collected_item_queue.pop_front());
    end
endtask

`undef WAIT_CLK_POSEDGE
