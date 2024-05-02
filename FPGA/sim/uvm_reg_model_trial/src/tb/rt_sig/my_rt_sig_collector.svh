// Verible directive
// verilog_lint: waive-start line-length

//! Some techniques used in this file are based on the following source:
//! - [UVM Register Model Example](https://www.chipverify.com/uvm/uvm-register-model-example)

`ifndef INCLUDED_FROM_MY_VERIF_PKG
    $fatal(2, "include \"my_verif_pkg.svh\" instead of including this file");
    nonexistent_module_to_throw_a_custom_error_message_for invalid_inclusion();
`endif

class my_rt_sig_collector extends uvm_component;
    `uvm_component_utils(my_rt_sig_collector)

    virtual my_rt_sig_if m_vif;
    uvm_analysis_port#(my_rt_sig_collected_item) m_analysis_port;

    function new(string name, uvm_component parent);
        super.new(name, parent);
        m_analysis_port = new("m_analysis_port", this);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual my_rt_sig_if)::get(null, "uvm_test_top", "g_rt_sig_vif", m_vif)) begin
            `uvm_fatal("NO-VIF", {"virtual interface must be set for: ", "uvm_test_top", ".g_rt_sig_vif"})
        end
    endfunction

    extern virtual task get_response();

    virtual task run_phase(uvm_phase phase);
        forever begin
            get_response();
        end
    endtask
endclass

task my_rt_sig_collector::get_response();
    forever begin
        `ifdef XILINX_SIMULATOR // Vivado 2023.2 crushes with SIGSEGV when clocking block is used.
            `define WAIT_CLK_POSEDGE @(posedge m_vif.i_clk)
        `else
            `define WAIT_CLK_POSEDGE @m_vif.col_cb
        `endif

        `WAIT_CLK_POSEDGE begin
            if (m_vif.inner_prod_valid) begin
                my_rt_sig_collected_item item = my_rt_sig_collected_item::type_id::create("item");
                item.inner_prod = m_vif.inner_prod;
                m_analysis_port.write(item);
            end
        end

        `undef WAIT_CLK_POSEDGE
    end
endtask
