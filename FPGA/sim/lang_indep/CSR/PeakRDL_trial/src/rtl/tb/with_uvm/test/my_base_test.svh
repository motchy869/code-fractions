// Verible directive
// verilog_lint: waive-start line-length
// verilog_lint: waive-start parameter-name-style

//! Some techniques used in this file are based on the following source:
//! - [UVM Register Model Example](https://www.chipverify.com/uvm/uvm-register-model-example)

`ifndef INCLUDED_FROM_MY_VERIF_PKG
    $fatal(2, "include \"my_verif_pkg.svh\" instead of including this file");
    nonexistent_module_to_throw_a_custom_error_message_for_invalid_inclusion inst();
`endif

virtual class my_base_test extends uvm_test;
    const static string type_name = "my_base_test";
    my_env m_env;
    my_reset_seq m_reset_seq;
    my_rt_sig_drv_shutdown_seq m_rt_sig_drv_shutdown_seq;
    my_bus_drv_shutdown_seq m_bus_drv_shutdown_seq;

    virtual function string get_type_name();
        return type_name;
    endfunction

    function new(string name = "my_base_test", uvm_component parent);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        m_env = my_env::type_id::create("m_env", this);
        m_reset_seq = my_reset_seq::type_id::create("m_reset_seq", this);
        m_rt_sig_drv_shutdown_seq = my_rt_sig_drv_shutdown_seq::type_id::create("m_rt_sig_drv_shutdown_seq", this);
        m_bus_drv_shutdown_seq = my_bus_drv_shutdown_seq::type_id::create("m_bus_drv_shutdown_seq", this);
    endfunction

    virtual task reset_phase(uvm_phase phase);
        super.reset_phase(phase);
        phase.raise_objection(this);
        m_reset_seq.start(m_env.m_rt_sig_agent.m_sequencer);
        phase.drop_objection(this);
    endtask

    virtual task shutdown_phase(uvm_phase phase);
        super.shutdown_phase(phase);
        phase.raise_objection(this);
        m_rt_sig_drv_shutdown_seq.start(m_env.m_rt_sig_agent.m_sequencer);
        m_bus_drv_shutdown_seq.start(m_env.m_bus_agent.m_sequencer);
        phase.drop_objection(this);
    endtask
endclass
