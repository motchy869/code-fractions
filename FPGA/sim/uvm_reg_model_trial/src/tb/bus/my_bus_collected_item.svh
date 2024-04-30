// Verible directive
// verilog_lint: waive-start line-length

//! Some techniques used in this file are based on the following source:
//! - [UVM Register Model Example](https://www.chipverify.com/uvm/uvm-register-model-example)

`ifndef INCLUDED_FROM_MY_VERIF_PKG
    $fatal("compile \"my_verif_pkg.sv\" instead of including this file");
`endif

class my_bus_collected_item extends uvm_sequence_item;
    bit data_is_read; // Indicates that this item contains read data
    bit [my_verif_params_pkg::AXI4_LITE_ADDR_BIT_WIDTH-1:0] rd_addr; // read address
    bit [my_verif_params_pkg::AXI4_LITE_DATA_BIT_WIDTH-1:0] rd_data; // read data
    bit [1:0] rresp; // read response
    bit data_is_written; // Indicates that this item contains write data
    bit [my_verif_params_pkg::AXI4_LITE_ADDR_BIT_WIDTH-1:0] wr_addr; // write address
    bit [my_verif_params_pkg::AXI4_LITE_DATA_BIT_WIDTH-1:0] wr_data; // write data
    bit [my_verif_params_pkg::AXI4_LITE_DATA_BIT_WIDTH/8-1:0] wstrb; // write strobe
    bit [1:0] bresp; // write response

    `uvm_object_utils_begin(my_bus_collected_item)
        `uvm_field_int(data_is_read, UVM_DEFAULT | UVM_BIN)
        `uvm_field_int(rd_addr, UVM_DEFAULT | UVM_HEX)
        `uvm_field_int(rd_data, UVM_DEFAULT | UVM_HEX)
        `uvm_field_int(rresp, UVM_DEFAULT | UVM_HEX)
        `uvm_field_int(data_is_written, UVM_DEFAULT | UVM_BIN)
        `uvm_field_int(wr_addr, UVM_DEFAULT | UVM_HEX)
        `uvm_field_int(wr_data, UVM_DEFAULT | UVM_HEX)
        `uvm_field_int(wstrb, UVM_DEFAULT | UVM_HEX)
        `uvm_field_int(bresp, UVM_DEFAULT | UVM_HEX)
    `uvm_object_utils_end

    function new(string name = "my_bus_collected_item");
        super.new(name);
    endfunction
endclass
