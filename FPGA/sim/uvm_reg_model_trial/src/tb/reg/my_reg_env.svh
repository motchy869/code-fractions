// Verible directive
// verilog_lint: waive-start line-length

//! Some techniques used in this file are based on the following source:
//! - [UVM Register Model Example](https://www.chipverify.com/uvm/uvm-register-model-example)

`ifndef INCLUDED_FROM_MY_VERIF_PKG
    $fatal(2, "include \"my_verif_pkg.svh\" instead of including this file");
    nonexistent_module_to_throw_a_custom_error_message_for invalid_inclusion();
`endif

//! Put top-level register block, register adapter, and register predictor together.
//! Note that bus agent is not included (because bus agent should not be dedicated to register operation), unlike the configuration in the "UVM Register Model Example" in aforementioned Web page.
class my_reg_env extends uvm_env;
    my_reg_model m_reg_model; // register model
    my_reg_adapter m_reg_adapter; // register adapter
    uvm_reg_predictor#(my_bus_seq_item) m_reg_predictor; // register predictor

    `uvm_component_utils(my_reg_env)

    function new(string name = "my_reg_env", uvm_component parent);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        m_reg_model = my_reg_model::type_id::create("m_reg_model", this);
        m_reg_adapter = my_reg_adapter::type_id::create("m_reg_adapter", this);
        m_reg_predictor = uvm_reg_predictor#(my_bus_seq_item)::type_id::create("m_reg_predictor", this);

        m_reg_model.build();
        m_reg_model.lock_model();

        // 'uvm_test_top' is top layer created by `uvm_root`.
        // [uvm_componentの階層構造について](https://qiita.com/triggerfish/items/1856a13422a8f08c7dbf)
        uvm_config_db#(my_reg_model)::set(null, "uvm_test_top", "g_reg_model", m_reg_model);
    endfunction

    virtual function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        m_reg_predictor.map = m_reg_model.default_map;
        m_reg_predictor.adapter = m_reg_adapter;
    endfunction
endclass
