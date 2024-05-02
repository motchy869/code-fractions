// Verible directive
// verilog_lint: waive-start line-length

//! Some techniques used in this file are based on the following source:
//! - [UVM Register Model Example](https://www.chipverify.com/uvm/uvm-register-model-example)

`ifndef INCLUDED_FROM_MY_VERIF_PKG
    $fatal(2, "include \"my_verif_pkg.svh\" instead of including this file");
    nonexistent_module_to_throw_a_custom_error_message_for invalid_inclusion();
`endif

class my_reg_adapter extends uvm_reg_adapter;
    `uvm_object_utils(my_reg_adapter)

    function new(string name = "my_reg_adapter");
        super.new(name);
        this.supports_byte_enable = 1'b1;
        this.provides_responses = 1'b1;
    endfunction

    //! Convert `uvm_reg_bus_op` instance to command for bus-driver'.
    virtual function uvm_sequence_item reg2bus(const ref uvm_reg_bus_op rw);
        my_bus_seq_item pkt = my_bus_seq_item::type_id::create("pkt");
        pkt.drv_cmd = my_bus_seq_item::DRV_CMD_BUS_ACCESS;
        pkt.write = (rw.kind == UVM_WRITE);
        pkt.addr = rw.addr;
        pkt.data = rw.data;
        pkt.wstrb = rw.byte_en;
        `uvm_info(get_name(), $sformatf("reg2bus: kind=%s, addr=0x%0h, data=0x%0h, byte_en=0x%0h", rw.kind.name(), rw.addr, rw.data, rw.byte_en), UVM_DEBUG)
        return pkt;
    endfunction

    //! Convert `uvm_sequence_item` instance (typically comes from bus-monitor) to `uvm_reg_bus_op` instance.
    virtual function void bus2reg(const ref uvm_sequence_item bus_item, ref uvm_reg_bus_op rw);
        my_bus_seq_item pkt;

        if (!$cast(pkt, bus_item)) begin
            `uvm_fatal(get_name(), "bus2reg: bus_item is not of type my_bus_seq_item")
        end

        rw.kind = pkt.write ? UVM_WRITE : UVM_READ;
        rw.addr = pkt.addr;
        rw.data = pkt.data;
        rw.byte_en = pkt.wstrb;
        rw.status = pkt.status;
        `uvm_info(get_name(), $sformatf("bus2reg: kind=%s, addr=0x%0h, data=0x%0h, byte_en=0x%0h, status=%s", rw.kind.name(), rw.addr, rw.data, rw.byte_en, rw.status.name()), UVM_DEBUG)
    endfunction
endclass
