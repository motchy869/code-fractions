// Verible directive
// verilog_lint: waive-start line-length

//! Some techniques used in this file are based on the following source:
//! - [UVM Register Model Example](https://www.chipverify.com/uvm/uvm-register-model-example)

`ifndef INCLUDED_FROM_MY_VERIF_PKG
    $fatal(2, "include \"my_verif_pkg.svh\" instead of including this file");
    nonexistent_module_to_throw_a_custom_error_message_for invalid_inclusion();
`endif

class my_rt_sig_seq_item extends uvm_sequence_item;
    typedef enum logic [1:0] {
        DRV_CMD_NOP,
        DRV_CMD_RESET
    } drv_cmd_e;
    bit is_last_item; // Indicates the last item in the sequence
    drv_cmd_e drv_cmd; // command to the driver

    `uvm_object_utils_begin(my_rt_sig_seq_item)
        `uvm_field_int(is_last_item, UVM_DEFAULT | UVM_BIN)
        `uvm_field_enum(drv_cmd_e, drv_cmd, UVM_DEFAULT | UVM_HEX)
    `uvm_object_utils_end

    function new(string name = "my_rt_sig_seq_item");
        super.new(name);
    endfunction
endclass
