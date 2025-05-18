// Verible directive
// verilog_lint: waive-start line-length

//! Some techniques used in this file are based on the following source:
//! - [UVM Register Model Example](https://www.chipverify.com/uvm/uvm-register-model-example)

`ifndef INCLUDED_FROM_MY_VERIF_PKG
    $fatal(2, "include \"my_verif_pkg.svh\" instead of including this file");
    nonexistent_module_to_throw_a_custom_error_message_for_invalid_inclusion inst();
`endif

class my_reset_seq extends uvm_sequence;
    `uvm_object_utils(my_reset_seq)

    function new(string name = "my_reset_seq");
        super.new(name);
    endfunction

    task body();
        my_rt_sig_seq_item req;
        `uvm_create(req)
        req.drv_cmd = my_rt_sig_seq_item::DRV_CMD_RESET;
        `uvm_send(req)
    endtask
endclass
