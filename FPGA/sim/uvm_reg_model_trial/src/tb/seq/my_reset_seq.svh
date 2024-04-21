// Verible directive
// verilog_lint: waive-start line-length

//! Some techniques used in this file are based on the following source:
//! - [UVM Register Model Example](https://www.chipverify.com/uvm/uvm-register-model-example)

`ifndef MY_VERIF_PKG_SVH_INCLUDED
    $fatal("compile \"my_verif_pkg.sv\" instead of including this file");
`endif

class my_reset_seq extends uvm_sequence;
    `uvm_object_utils(my_reset_seq)

    function new(string name = "my_reset_seq");
        super.new(name);
    endfunction

    task body();
        my_rt_sig_seq_item req;
        `uvm_create(req)
        req.cmd = my_rt_sig_seq_item::CMD_RESET;
        `uvm_send(req)
    endtask
endclass
