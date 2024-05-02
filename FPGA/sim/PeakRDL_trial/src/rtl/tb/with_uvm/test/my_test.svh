// Verible directive
// verilog_lint: waive-start line-length
// verilog_lint: waive-start parameter-name-style

//! Some techniques used in this file are based on the following source:
//! - [UVM Register Model Example](https://www.chipverify.com/uvm/uvm-register-model-example)

`ifndef INCLUDED_FROM_MY_VERIF_PKG
    $fatal(2, "include \"my_verif_pkg.svh\" instead of including this file");
    nonexistent_module_to_throw_a_custom_error_message_for invalid_inclusion();
`endif

class my_test extends my_base_test;
    `uvm_component_utils(my_test)

    localparam int SIM_TIME_LIMIT_NS = 1500; //! simulation time limit in ns

    function new(string name = "my_test", uvm_component parent);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
    endfunction

    virtual function void end_of_elaboration_phase(uvm_phase phase);
        super.end_of_elaboration_phase(phase);
        uvm_factory::get().print();
        uvm_root::get().print_topology();
    endfunction

    virtual function void start_of_simulation_phase(uvm_phase phase);
        super.start_of_simulation_phase(phase);
        uvm_root::get().set_timeout(SIM_TIME_LIMIT_NS, 0);
    endfunction

    //! Note that `main_phase` comes after `reset_phase` in the UVM sequence of phases
    extern virtual task main_phase(uvm_phase phase);
endclass

task my_test::main_phase(uvm_phase phase);
    my_mod_csr_uvm_reg_model_pkg::my_mod_csr reg_model;
    uvm_status_e reg_acc_status;

    phase.raise_objection(this);
    if (!uvm_config_db#(my_mod_csr_uvm_reg_model_pkg::my_mod_csr)::get(null, "uvm_test_top", "g_reg_model", reg_model)) begin
        `uvm_fatal("NO-REG_MODEL", {"register model must be set for: ", "uvm_test_top", ".g_reg_model"})
    end

    // TODO: register operations

    phase.drop_objection(this);
endtask
