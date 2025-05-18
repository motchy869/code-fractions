// Verible directive
// verilog_lint: waive-start line-length

`ifndef INCLUDED_FROM_MY_VERIF_PKG
    $fatal(2, "include \"my_verif_pkg.svh\" instead of including this file");
    nonexistent_module_to_throw_a_custom_error_message_for_invalid_inclusion inst();
`endif

// Shutdown bus driver.
class my_bus_drv_shutdown_seq extends uvm_sequence;
    `uvm_object_utils(my_bus_drv_shutdown_seq)

    function new(string name = "my_bus_drv_shutdown_seq");
        super.new(name);
    endfunction

    task body();
        my_bus_seq_item req;

        `uvm_create(req)
        req.drv_cmd = my_bus_seq_item::DRV_CMD_NOP;
        req.is_last_item = 1;
        `uvm_send(req)
    endtask
endclass
