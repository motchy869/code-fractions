// Verible directive
// verilog_lint: waive-start line-length

//! Some techniques used in this file are based on the following source:
//! - [UVM Register Model Example](https://www.chipverify.com/uvm/uvm-register-model-example)

`ifndef MY_VERIF_PKG_SVH_INCLUDED
    $fatal("compile \"my_verif_pkg.sv\" instead of including this file");
`endif

class my_rt_sig_driver extends uvm_driver#(my_rt_sig_seq_item);
    `uvm_component_utils(my_rt_sig_driver)

    virtual my_rt_sig_if m_vif;

    function new(string name = "my_rt_sig_driver", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual my_rt_sig_if)::get(uvm_root::get(), "uvm_test_top", "rt_sig_vif", m_vif)) begin
            `uvm_fatal("NO-VIF", {"virtual interface must be set for: ", get_full_name(), ".rt_sig_vif"})
        end
    endfunction

    virtual task run_phase(uvm_phase phase);
        my_rt_sig_seq_item item;

        phase.raise_objection(this);

        m_vif.input_vec <= '0;
        m_vif.input_vec_valid <= 1'b0;

        forever begin
            `ifdef XILINX_SIMULATOR // Vivado 2023.2 crushes with SIGSEGV when clocking block is used.
                `define WAIT_CLK_POSEDGE @(posedge m_vif.clk)
            `else
                `define WAIT_CLK_POSEDGE @m_vif.mst_cb
            `endif

            `WAIT_CLK_POSEDGE
            seq_item_port.try_next_item(item);
            if (item == null) begin
                m_vif.input_vec_valid <= 1'b0;
            end else begin
                m_vif.input_vec <= item.input_vec;
                m_vif.input_vec_valid <= 1'b1;
                `uvm_info("INFO", {"Sent input vector."}, UVM_MEDIUM);
                if (item.is_last_item) begin
                    phase.drop_objection(this);
                end
            end

            `undef WAIT_CLK_POSEDGE
        end
    endtask
endclass
