// Verible directive
// verilog_lint: waive-start line-length

//! Some techniques used in this file are based on the following source:
//! - [UVM Register Model Example](https://www.chipverify.com/uvm/uvm-register-model-example)

`ifndef INCLUDED_FROM_MY_VERIF_PKG
    $fatal(2, "include \"my_verif_pkg.svh\" instead of including this file");
    nonexistent_module_to_throw_a_custom_error_message_for_invalid_inclusion inst();
`endif

class my_rt_sig_seq extends uvm_sequence;
    `uvm_object_utils(my_rt_sig_seq)

    localparam int DURATION_CYCLES = 3;

    function new(string name = "my_rt_sig_seq");
        super.new(name);
    endfunction

    task body();
        my_rt_sig_seq_item req;

        for (int i=0; i<DURATION_CYCLES; ++i) begin
            `uvm_create(req)
            req.drv_cmd = my_rt_sig_seq_item::DRV_CMD_INPUT_VEC;
            req.input_vec = {
                my_verif_params_pkg::AXI4_LITE_ADDR_BIT_WIDTH'(1+3*i),
                my_verif_params_pkg::AXI4_LITE_ADDR_BIT_WIDTH'(2+3*i),
                my_verif_params_pkg::AXI4_LITE_ADDR_BIT_WIDTH'(3+3*i),
                my_verif_params_pkg::AXI4_LITE_ADDR_BIT_WIDTH'(4+3*i)
            };
            `uvm_send(req)
        end
    endtask
endclass
