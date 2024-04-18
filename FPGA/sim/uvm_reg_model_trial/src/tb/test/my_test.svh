// Verible directive
// verilog_lint: waive-start line-length
// verilog_lint: waive-start parameter-name-style

//! Some techniques used in this file are based on the following source:
//! - [UVM Register Model Example](https://www.chipverify.com/uvm/uvm-register-model-example)

`ifndef MY_VERIF_PKG_SVH_INCLUDED
    $fatal("compile \"my_verif_pkg.sv\" instead of including this file");
`endif

class my_test extends my_base_test;
    `uvm_component_utils(my_test)

    localparam int SIM_TIME_LIMIT_NS = 500; //! simulation time limit in ns

    function new(string name = "my_test", uvm_component parent);
        super.new(name, parent);
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
    my_reg_model reg_model;
    uvm_status_e reg_acc_status;

    phase.raise_objection(this);
    if (!uvm_config_db#(my_reg_model)::get(null, "uvm_test_top", "g_reg_model", reg_model)) begin
        `uvm_fatal("NO-REG_MODEL", {"register model must be set for: ", "uvm_test_top", ".g_reg_model"})
    end

    reg_model.REG_FILE_0.REG_0.write(reg_acc_status, 32'h12345678);
    reg_model.REG_FILE_0.REG_1.write(reg_acc_status, 32'h87654321);
    phase.drop_objection(this);
endtask
