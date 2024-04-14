// Verible directive
// verilog_lint: waive-start line-length

//! Some techniques used in this file are based on the following source:
//! - [UVM Register Model Example](https://www.chipverify.com/uvm/uvm-register-model-example)

`ifndef MY_VERIF_PKG_SVH_INCLUDED
    $fatal("compile \"my_verif_pkg.sv\" instead of including this file");
`endif

class my_bus_seq_item extends uvm_pkg::uvm_sequence_item;
    bit [my_verif_pkg::AXI4_LITE_ADDR_BIT_WIDTH-1:0] addr; // address
    bit [my_verif_pkg::AXI4_LITE_DATA_BIT_WIDTH-1:0] data; // data
    bit write; // 0/1: read/write
    bit [my_verif_pkg::AXI4_LITE_DATA_BIT_WIDTH/8-1:0] wstrb; // write strobe

    `uvm_object_utils_begin(my_bus_seq_item)
        `uvm_field_int(addr, UVM_ALL_ON)
        `uvm_field_int(data, UVM_ALL_ON)
        `uvm_field_int(write, UVM_ALL_ON)
        `uvm_field_int(wstrb, UVM_ALL_ON)
    `uvm_object_utils_end

    function new(string name = "my_bus_seq_item");
        super.new(name);
    endfunction
endclass