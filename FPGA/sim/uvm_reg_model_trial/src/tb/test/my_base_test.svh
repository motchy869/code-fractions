// Verible directive
// verilog_lint: waive-start line-length
// verilog_lint: waive-start parameter-name-style

//! Some techniques used in this file are based on the following source:
//! - [UVM Register Model Example](https://www.chipverify.com/uvm/uvm-register-model-example)

`ifndef MY_VERIF_PKG_SVH_INCLUDED
    $fatal("compile \"my_verif_pkg.sv\" instead of including this file");
`endif

virtual class my_base_test extends uvm_test;
    const static string type_name = "my_base_test";
    my_env m_env;
    my_reset_seq m_reset_seq;

    virtual function string get_type_name();
        return type_name;
    endfunction

    function new (string name = "my_base_test", uvm_component parent);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        m_env = my_env::type_id::create("m_env", this);
        m_reset_seq = my_reset_seq::type_id::create("m_reset_seq", this);
    endfunction

    virtual task reset_phase(uvm_phase phase);
        super.reset_phase(phase);
        phase.raise_objection(this);
        m_reset_seq.start(m_env.m_rt_sig_agent.m_sequencer);
        phase.drop_objection(this);
    endtask
endclass
