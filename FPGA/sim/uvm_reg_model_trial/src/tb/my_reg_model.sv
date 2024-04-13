// Verible directive
// verilog_lint: waive-start line-length

//! Some techniques used in this file are based on the following source:
//! [UVM Register Model Example](https://www.chipverify.com/uvm/uvm-register-model-example)

`include "my_verif_pkg.svh"

import uvm_pkg::*;

//! register definition for the register 0
class ral_reg_0 extends uvm_reg;
    uvm_reg_field data; // read- & writ-able field

    `uvm_object_utils(ral_reg_0)

    function new(string name = "register_0");
        super.new(name, 32, build_coverage(UVM_NO_COVERAGE));
    endfunction

    virtual function void build();
        this.data = uvm_reg_field::type_id::create("data", , get_full_name());

        this.data.configure(.parent(this), .size(32), .lsb_pos(0), .access("RW"), .volatile(0), .reset(32'h0), .has_reset(1), .is_rand(0), .individually_accessible(0));
    endfunction
endclass

//! register definition for the register 1
class ral_reg_1 extends uvm_reg;
    uvm_reg_field data; // read- & writ-able field

    `uvm_object_utils(ral_reg_1)

    function new(string name = "register_1");
        super.new(name, 32, build_coverage(UVM_NO_COVERAGE));
    endfunction

    virtual function void build();
        this.data = uvm_reg_field::type_id::create("data", , get_full_name());

        this.data.configure(.parent(this), .size(32), .lsb_pos(0), .access("RW"), .volatile(0), .reset(32'h0), .has_reset(1), .is_rand(0), .individually_accessible(0));
    endfunction
endclass

//! register definition for the register 2
class ral_reg_2 extends uvm_reg;
    uvm_reg_field data; // read- & writ-able field

    `uvm_object_utils(ral_reg_2)

    function new(string name = "register_2");
        super.new(name, 32, build_coverage(UVM_NO_COVERAGE));
    endfunction

    virtual function void build();
        this.data = uvm_reg_field::type_id::create("data", , get_full_name());

        this.data.configure(.parent(this), .size(32), .lsb_pos(0), .access("RW"), .volatile(0), .reset(32'h0), .has_reset(1), .is_rand(0), .individually_accessible(0));
    endfunction
endclass

//! register definition for the register 3
class ral_reg_3 extends uvm_reg;
    uvm_reg_field data; // read- & writ-able field

    `uvm_object_utils(ral_reg_3)

    function new(string name = "register_3");
        super.new(name, 32, build_coverage(UVM_NO_COVERAGE));
    endfunction

    virtual function void build();
        this.data = uvm_reg_field::type_id::create("data", , get_full_name());

        this.data.configure(.parent(this), .size(32), .lsb_pos(0), .access("RW"), .volatile(0), .reset(32'h0), .has_reset(1), .is_rand(0), .individually_accessible(0));
    endfunction
endclass
