// Verible directive
// verilog_lint: waive-start line-length

`ifndef INCLUDED_FROM_MY_VERIF_PKG
    $fatal(2, "include \"my_verif_pkg.svh\" instead of including this file");
    nonexistent_module_to_throw_a_custom_error_message_for invalid_inclusion();
`endif

// Shutdown real-time signal driver.
class my_rt_sig_drv_shutdown_seq extends uvm_sequence;
    `uvm_object_utils(my_rt_sig_drv_shutdown_seq)

    function new(string name = "my_rt_sig_drv_shutdown_seq");
        super.new(name);
    endfunction

    task body();
        my_rt_sig_seq_item req;

        `uvm_create(req)
        req.drv_cmd = my_rt_sig_seq_item::DRV_CMD_NOP;
        req.is_last_item = 1;
        `uvm_send(req)
    endtask
endclass
