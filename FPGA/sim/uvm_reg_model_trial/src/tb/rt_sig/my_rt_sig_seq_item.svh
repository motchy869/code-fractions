// Verible directive
// verilog_lint: waive-start line-length

//! Some techniques used in this file are based on the following source:
//! - [UVM Register Model Example](https://www.chipverify.com/uvm/uvm-register-model-example)

`ifndef MY_VERIF_PKG_SVH_INCLUDED
    $fatal("compile \"my_verif_pkg.sv\" instead of including this file");
`endif

class my_rt_sig_seq_item extends uvm_sequence_item;
    typedef enum bit {
        CMD_RESET,
        CMD_INPUT_VEC
    } cmd_e;
    cmd_e cmd;
    bit is_last_item; // Indicates the last item in the sequence
    bit [3:0][my_verif_params_pkg::AXI4_LITE_ADDR_BIT_WIDTH-1:0] input_vec;

    `uvm_object_utils_begin(my_rt_sig_seq_item)
        `uvm_field_enum(cmd_e, cmd, UVM_DEFAULT | UVM_BIN)
        `uvm_field_int(is_last_item, UVM_DEFAULT | UVM_BIN)
        `uvm_field_int(input_vec, UVM_DEFAULT | UVM_NOCOMPARE | UVM_HEX)
    `uvm_object_utils_end

    function new(string name = "my_rt_sig_seq_item");
        super.new(name);
    endfunction
endclass
