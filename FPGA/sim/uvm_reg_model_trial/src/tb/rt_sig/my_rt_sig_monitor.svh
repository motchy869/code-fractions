// Verible directive
// verilog_lint: waive-start line-length

//! Some techniques used in this file are based on the following source:
//! - [UVM Register Model Example](https://www.chipverify.com/uvm/uvm-register-model-example)

`ifndef INCLUDED_FROM_MY_VERIF_PKG
    $fatal(2, "include \"my_verif_pkg.svh\" instead of including this file");
    nonexistent_module_to_throw_a_custom_error_message_for invalid_inclusion();
`endif

class my_rt_sig_monitor extends uvm_monitor;
    `uvm_component_utils(my_rt_sig_monitor)

    uvm_analysis_imp#(my_rt_sig_collected_item, my_rt_sig_monitor) m_analysis_export;
    uvm_analysis_port#(my_rt_sig_collected_item) m_analysis_port;

    function new(string name, uvm_component parent);
        super.new(name, parent);
        m_analysis_export = new("m_analysis_export", this);
        m_analysis_port = new("m_analysis_port", this);
    endfunction

    function void write(my_rt_sig_collected_item item);
        `uvm_info("INFO", $sformatf("Got a inner_prod: %08h", item.inner_prod), UVM_MEDIUM)
        // Do something in the future.

        m_analysis_port.write(item);
    endfunction
endclass
