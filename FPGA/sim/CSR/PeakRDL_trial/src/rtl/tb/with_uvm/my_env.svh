// Verible directive
// verilog_lint: waive-start line-length

//! Some techniques used in this file are based on the following source:
//! - [UVM Register Model Example](https://www.chipverify.com/uvm/uvm-register-model-example)

`ifndef INCLUDED_FROM_MY_VERIF_PKG
    $fatal(2, "include \"my_verif_pkg.svh\" instead of including this file");
    nonexistent_module_to_throw_a_custom_error_message_for invalid_inclusion();
`endif

//! Top-level environment
class my_env extends uvm_env;
    my_rt_sig_agent m_rt_sig_agent;
    my_bus_agent m_bus_agent;
    my_reg_env m_reg_env;

    `uvm_component_utils(my_env)

    function new(string name = "my_env", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        m_rt_sig_agent = my_rt_sig_agent::type_id::create("m_rt_sig_agent", this);
        m_bus_agent = my_bus_agent::type_id::create("m_bus_agent", this);
        m_reg_env = my_reg_env::type_id::create("m_reg_env", this);
        uvm_reg::include_coverage("*", UVM_CVR_ALL); // This will also work: `uvm_reg::include_coverage({this.get_full_name(), ".m_reg_env.m_reg_model"}, UVM_CVR_ALL);`
    endfunction

    virtual function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        m_bus_agent.m_monitor.m_analysis_port_to_reg_predictor.connect(m_reg_env.m_reg_predictor.bus_in);
        m_reg_env.m_reg_model.default_map.set_sequencer(m_bus_agent.m_sequencer, m_reg_env.m_reg_adapter);
    endfunction
endclass
