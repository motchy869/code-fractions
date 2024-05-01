// Verible directive
// verilog_lint: waive-start line-length

//! Some techniques used in this file are based on the following source:
//! - [UVM Register Model Example](https://www.chipverify.com/uvm/uvm-register-model-example)
//! - [uvm_reg_file的作用](https://www.cnblogs.com/lanlancky/p/17110187.html)
//! - [Universal Verification Methodology (UVM) 1.2 User’s Guide](https://www.accellera.org/images/downloads/standards/uvm/uvm_users_guide_1.2.pdf)

`ifndef INCLUDED_FROM_MY_VERIF_PKG
    $fatal(2, "compile \"my_verif_pkg.sv\" instead of including this file");
    nonexistent_module_to_throw_a_custom_error_message_for invalid_inclusion();
`endif

class my_reg_model_params;
    localparam int REG_BIT_WIDTH = my_verif_params_pkg::AXI4_LITE_DATA_BIT_WIDTH; //! bit width of the register
    localparam int REG_SIZE_BYTE = REG_BIT_WIDTH / 8; //! size of the register in byte
endclass

//! register definition for the register 0
class my_reg_0 extends uvm_reg;
    uvm_reg_field DATA; // read- & writ-able field

    `uvm_object_utils(my_reg_0)

    function new(string name = "reg_0");
        super.new(name, my_reg_model_params::REG_BIT_WIDTH, build_coverage(UVM_NO_COVERAGE));
    endfunction

    virtual function void build();
        this.DATA = uvm_reg_field::type_id::create("DATA", null, get_full_name());

        this.DATA.configure(.parent(this), .size(32), .lsb_pos(0), .access("RW"), .volatile(0), .reset(32'h0), .has_reset(1), .is_rand(0), .individually_accessible(0));
    endfunction
endclass

//! register definition for the register 1
class my_reg_1 extends uvm_reg;
    uvm_reg_field DATA; // read- & writ-able field

    `uvm_object_utils(my_reg_1)

    function new(string name = "reg_1");
        super.new(name, my_reg_model_params::REG_BIT_WIDTH, build_coverage(UVM_NO_COVERAGE));
    endfunction

    virtual function void build();
        this.DATA = uvm_reg_field::type_id::create("DATA", null, get_full_name());

        this.DATA.configure(.parent(this), .size(32), .lsb_pos(0), .access("RW"), .volatile(0), .reset(32'h0), .has_reset(1), .is_rand(0), .individually_accessible(0));
    endfunction
endclass

//! register definition for the register 2
class my_reg_2 extends uvm_reg;
    uvm_reg_field DATA; // read- & writ-able field

    `uvm_object_utils(my_reg_2)

    function new(string name = "reg_2");
        super.new(name, my_reg_model_params::REG_BIT_WIDTH, build_coverage(UVM_NO_COVERAGE));
    endfunction

    virtual function void build();
        this.DATA = uvm_reg_field::type_id::create("DATA", null, get_full_name());

        this.DATA.configure(.parent(this), .size(32), .lsb_pos(0), .access("RW"), .volatile(0), .reset(32'h0), .has_reset(1), .is_rand(0), .individually_accessible(0));
    endfunction
endclass

//! register definition for the register 3
class my_reg_3 extends uvm_reg;
    uvm_reg_field DATA; // read- & writ-able field

    `uvm_object_utils(my_reg_3)

    function new(string name = "reg_3");
        super.new(name, my_reg_model_params::REG_BIT_WIDTH, build_coverage(UVM_NO_COVERAGE));
    endfunction

    virtual function void build();
        this.DATA = uvm_reg_field::type_id::create("DATA", null, get_full_name());

        this.DATA.configure(.parent(this), .size(32), .lsb_pos(0), .access("RW"), .volatile(0), .reset(32'h0), .has_reset(1), .is_rand(0), .individually_accessible(0));
    endfunction
endclass

//! Register file definition of register file 0.
//! This contains register 0 and 1.
class my_reg_file_0 extends uvm_reg_file;
    my_reg_0 REG_0;
    my_reg_1 REG_1;
    localparam int REG_FILE_SIZE_BYTE = 2*my_reg_model_params::REG_SIZE_BYTE;

    `uvm_object_utils(my_reg_file_0)

    function new(string name = "REG_FILE_0");
        super.new(name);
    endfunction

    virtual function void build();
        this.REG_0 = my_reg_0::type_id::create("REG_0", null, get_full_name());
        this.REG_1 = my_reg_1::type_id::create("REG_1", null, get_full_name());

        this.REG_0.configure(get_block(), this, "REG_0");
        this.REG_1.configure(get_block(), this, "REG_1");

        this.REG_0.build();
        this.REG_1.build();
    endfunction

    virtual function void map(uvm_reg_map mp, uvm_reg_addr_t offset = 0);
        mp.add_reg(REG_0, offset);
        mp.add_reg(REG_1, offset + my_reg_model_params::REG_SIZE_BYTE);
    endfunction

    virtual function void set_offset(uvm_reg_map mp, uvm_reg_addr_t offset = 0);
        REG_0.set_offset(mp, offset);
        REG_1.set_offset(mp, offset + my_reg_model_params::REG_SIZE_BYTE);
    endfunction
endclass

//! Register file definition of register file 1.
//! This contains register 2 and 3.
class my_reg_file_1 extends uvm_reg_file;
    my_reg_2 REG_2;
    my_reg_3 REG_3;
    localparam int REG_FILE_SIZE_BYTE = 2*my_reg_model_params::REG_SIZE_BYTE;

    `uvm_object_utils(my_reg_file_1)

    function new(string name = "REG_FILE_1");
        super.new(name);
    endfunction

    virtual function void build();
        this.REG_2 = my_reg_2::type_id::create("REG_2", null, get_full_name());
        this.REG_3 = my_reg_3::type_id::create("REG_3", null, get_full_name());

        this.REG_2.configure(get_block(), this, "REG_2");
        this.REG_3.configure(get_block(), this, "REG_3");

        this.REG_2.build();
        this.REG_3.build();
    endfunction

    virtual function void map(uvm_reg_map mp, uvm_reg_addr_t offset = 0);
        mp.add_reg(REG_2, offset);
        mp.add_reg(REG_3, offset + my_reg_model_params::REG_SIZE_BYTE);
    endfunction

    virtual function void set_offset(uvm_reg_map mp, uvm_reg_addr_t offset = 0);
        REG_2.set_offset(mp, offset);
        REG_3.set_offset(mp, offset + my_reg_model_params::REG_SIZE_BYTE);
    endfunction
endclass

//! Register block definition.
//! This contains register file 0 and 1.
class my_reg_model extends uvm_reg_block;
    my_reg_file_0 REG_FILE_0;
    my_reg_file_1 REG_FILE_1;

    `uvm_object_utils(my_reg_model)

    function new(string name = "REG_BLOCK");
        super.new(name, build_coverage(UVM_NO_COVERAGE));
    endfunction

    virtual function void build();
        this.default_map = create_map(.name(""), .base_addr(0), .n_bytes(4), .endian(UVM_LITTLE_ENDIAN), .byte_addressing(1));

        this.REG_FILE_0 = my_reg_file_0::type_id::create("REG_FILE_0", null, get_full_name());
        this.REG_FILE_0.configure(this, null, "");
        this.REG_FILE_0.build();
        this.REG_FILE_0.map(this.default_map, 0);

        this.REG_FILE_1 = my_reg_file_1::type_id::create("REG_FILE_1", null, get_full_name());
        this.REG_FILE_1.configure(this, null, "");
        this.REG_FILE_1.build();
        this.REG_FILE_1.map(this.default_map, my_reg_file_1::REG_FILE_SIZE_BYTE);
    endfunction
endclass
