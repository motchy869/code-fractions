// Verible directive
// verilog_lint: waive-start line-length

//! Some techniques used in this file are based on the following source:
//! - [UVM Register Model Example](https://www.chipverify.com/uvm/uvm-register-model-example)

`ifndef INCLUDED_FROM_MY_VERIF_PKG
    $fatal(2, "include \"my_verif_pkg.svh\" instead of including this file");
    nonexistent_module_to_throw_a_custom_error_message_for invalid_inclusion();
`endif

class my_rt_sig_driver extends uvm_driver#(my_rt_sig_seq_item);
    `uvm_component_utils(my_rt_sig_driver)

    virtual my_rt_sig_if m_vif;

    function new(string name = "my_rt_sig_driver", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual my_rt_sig_if)::get(null, "uvm_test_top", "g_rt_sig_vif", m_vif)) begin
            `uvm_fatal("NO-VIF", {"virtual interface must be set for: ", "uvm_test_top", ".g_rt_sig_vif"})
        end
    endfunction

    extern virtual task reset_dut();
    extern virtual task run_phase(uvm_phase phase);
endclass

`ifdef XILINX_SIMULATOR // Vivado 2023.2 crushes with SIGSEGV when clocking block is used.
    `define WAIT_CLK_POSEDGE @(posedge m_vif.i_clk)
`else
    `define WAIT_CLK_POSEDGE @m_vif.drv_cb
`endif

task my_rt_sig_driver::reset_dut();
    localparam int RESET_DURATION_CLK = 20; // AXI specification requires holding reset signal at least 16 clock cycles.

    `uvm_info("INFO", "Resetting the DUT.", UVM_MEDIUM)
    m_vif.sync_rst <= 1'b1;
    repeat (RESET_DURATION_CLK) begin
        `WAIT_CLK_POSEDGE;
    end
    m_vif.sync_rst <= 1'b0;
    `uvm_info("INFO", "Release the dut from reset.", UVM_MEDIUM)
    `WAIT_CLK_POSEDGE;
endtask

task my_rt_sig_driver::run_phase(uvm_phase phase);
    my_rt_sig_seq_item item;

    phase.raise_objection(this);

    m_vif.sync_rst <= 1'b0;

    forever begin
        `WAIT_CLK_POSEDGE
        seq_item_port.try_next_item(item); // Get the next item from the sequencer if there is one.
        if (item == null) begin
            ; // nothing to do
        end else begin
            unique case (item.drv_cmd)
                my_rt_sig_seq_item::DRV_CMD_NOP:
                    ; // nothing to do
                my_rt_sig_seq_item::DRV_CMD_RESET:
                    reset_dut();
            endcase
            seq_item_port.item_done(); // Tell the sequencer that the item is done.
            if (item.is_last_item) begin
                `uvm_info("INFO", "Got last item in the sequence.", UVM_MEDIUM);
                break;
            end
        end
    end

    phase.drop_objection(this);
endtask

`undef WAIT_CLK_POSEDGE
