// Verible directive
// verilog_lint: waive-start line-length

//! Some techniques used in this file are based on the following source:
//! - [UVM Register Model Example](https://www.chipverify.com/uvm/uvm-register-model-example)

`ifndef INCLUDED_FROM_MY_VERIF_PKG
    $fatal("compile \"my_verif_pkg.sv\" instead of including this file");
`endif

class my_rt_sig_agent extends uvm_agent;
    my_rt_sig_driver m_driver;
    my_rt_sig_collector m_collector;
    my_rt_sig_monitor m_monitor;
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
        m_collector = my_rt_sig_collector::type_id::create("m_collector", this);
        m_monitor = my_rt_sig_monitor::type_id::create("m_monitor", this);
        m_sequencer = uvm_sequencer#(my_rt_sig_seq_item)::type_id::create("m_sequencer", this);
    endfunction

    virtual function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        m_collector.m_analysis_port.connect(m_monitor.m_analysis_export);
        if (get_is_active() == UVM_ACTIVE) begin
            m_driver.seq_item_port.connect(m_sequencer.seq_item_export);
        end
    endfunction
endclass
