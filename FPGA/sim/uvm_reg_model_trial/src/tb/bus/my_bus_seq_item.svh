// Verible directive
// verilog_lint: waive-start line-length

//! Some techniques used in this file are based on the following source:
//! - [UVM Register Model Example](https://www.chipverify.com/uvm/uvm-register-model-example)

`ifndef INCLUDED_FROM_MY_VERIF_PKG
    $fatal(2, "compile \"my_verif_pkg.sv\" instead of including this file");
    nonexistent_module_to_throw_a_custom_error_message_for invalid_inclusion();
`endif

class my_bus_seq_item extends uvm_sequence_item;
    typedef enum bit {
        DRV_CMD_NOP,
        DRV_CMD_BUS_ACCESS // read / write access
    } drv_cmd_e;
    bit is_last_item; // Indicates the last item in the sequence
    drv_cmd_e drv_cmd; // command to the driver
    bit [my_verif_params_pkg::AXI4_LITE_ADDR_BIT_WIDTH-1:0] addr; // address
    bit [my_verif_params_pkg::AXI4_LITE_DATA_BIT_WIDTH-1:0] data; // data
    bit write; // 0/1: read/write
    bit [my_verif_params_pkg::AXI4_LITE_DATA_BIT_WIDTH/8-1:0] wstrb; // write strobe
    uvm_status_e status; // result of the transaction

    `uvm_object_utils_begin(my_bus_seq_item)
        `uvm_field_int(is_last_item, UVM_DEFAULT | UVM_BIN)
        `uvm_field_enum(drv_cmd_e, drv_cmd, UVM_DEFAULT | UVM_HEX)
        `uvm_field_int(addr, UVM_DEFAULT | UVM_HEX)
        `uvm_field_int(data, UVM_DEFAULT | UVM_HEX)
        `uvm_field_int(write, UVM_DEFAULT | UVM_BIN)
        `uvm_field_int(wstrb, UVM_DEFAULT | UVM_HEX)
        `uvm_field_enum(uvm_status_e, status, UVM_DEFAULT | UVM_HEX)
    `uvm_object_utils_end

    function new(string name = "my_bus_seq_item");
        super.new(name);
    endfunction
endclass
