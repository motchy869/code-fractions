// Verible directive
// verilog_lint: waive-start line-length

//! Some techniques used in this file are based on the following source:
//! - [UVM Register Model Example](https://www.chipverify.com/uvm/uvm-register-model-example)

`ifndef INCLUDED_FROM_MY_VERIF_PKG
    $fatal("compile \"my_verif_pkg.sv\" instead of including this file");
`endif

class my_rt_sig_collected_item extends uvm_sequence_item;
    logic [my_verif_params_pkg::AXI4_LITE_DATA_BIT_WIDTH-1:0] inner_prod;

    `uvm_object_utils_begin(my_rt_sig_collected_item)
        `uvm_field_int(inner_prod, UVM_DEFAULT | UVM_HEX)
    `uvm_object_utils_end

    function new(string name = "my_rt_sig_collected_item");
        super.new(name);
    endfunction
endclass
