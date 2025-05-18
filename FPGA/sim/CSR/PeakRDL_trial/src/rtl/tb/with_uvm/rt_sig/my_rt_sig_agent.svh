// Verible directive
// verilog_lint: waive-start line-length

//! Some techniques used in this file are based on the following source:
//! - [UVM Register Model Example](https://www.chipverify.com/uvm/uvm-register-model-example)

`ifndef INCLUDED_FROM_MY_VERIF_PKG
    $fatal(2, "include \"my_verif_pkg.svh\" instead of including this file");
    nonexistent_module_to_throw_a_custom_error_message_for_invalid_inclusion inst();
`endif

class my_rt_sig_agent extends uvm_agent;
    my_rt_sig_driver m_driver;
    uvm_sequencer#(my_rt_sig_seq_item) m_sequencer;

    `uvm_component_utils_begin(my_rt_sig_agent)
        `uvm_field_enum(uvm_active_passive_enum, is_active, UVM_DEFAULT)
    `uvm_component_utils_end

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        m_driver = my_rt_sig_driver::type_id::create("m_driver", this);
        m_sequencer = uvm_sequencer#(my_rt_sig_seq_item)::type_id::create("m_sequencer", this);
    endfunction

    virtual function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        if (get_is_active() == UVM_ACTIVE) begin
            m_driver.seq_item_port.connect(m_sequencer.seq_item_export);
        end
    endfunction
endclass
