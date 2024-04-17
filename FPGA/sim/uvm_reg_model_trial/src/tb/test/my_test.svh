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

    function new (string name = "my_test", uvm_component parent);
        super.new(name, parent);
    endfunction

    //! Note that `main_phase` comes after `reset_phase` in the UVM sequence of phases
    extern virtual task main_phase(uvm_phase phase);
endclass

task my_test::main_phase(uvm_phase phase);
    phase.raise_objection(this);
    phase.drop_objection(this);
endtask
