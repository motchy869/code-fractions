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
    extern virtual task input_vec(logic [3:0][my_verif_params_pkg::AXI4_LITE_DATA_BIT_WIDTH-1:0] input_vec);
    extern virtual task run_phase(uvm_phase phase);
endclass

// (1)
// `ifdef XILINX_SIMULATOR // Vivado 2023.2 crashes with SIGSEGV when clocking block is used.
//     `define WAIT_CLK_POSEDGE @(posedge m_vif.i_clk)
// `else
//     `define WAIT_CLK_POSEDGE @vif.mst_cb
// `endif
// (2) Clocking block is buggy in Xcelium, so we decided to simply use `@(posedge m_vif.i_clk)`
`define WAIT_CLK_POSEDGE @(posedge m_vif.i_clk)

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

task my_rt_sig_driver::input_vec(logic [3:0][my_verif_params_pkg::AXI4_LITE_DATA_BIT_WIDTH-1:0] input_vec);
    m_vif.input_vec <= input_vec;
    m_vif.input_vec_valid <= 1'b1;
    `uvm_info("INFO", {"input vector."}, UVM_MEDIUM);
    `WAIT_CLK_POSEDGE;
    m_vif.input_vec_valid <= 1'b0; // Will be overwritten after +0 ns if there is next input vector in `seq_item_port`.
endtask

task my_rt_sig_driver::run_phase(uvm_phase phase);
    my_rt_sig_seq_item item;
    time curr_time;

    phase.raise_objection(this);

    m_vif.sync_rst <= 1'b0;
    m_vif.input_vec <= '0;
    m_vif.input_vec_valid <= 1'b0;

    forever begin
        seq_item_port.get_next_item(item);

        curr_time = $time;
        if (curr_time != 0 && (curr_time - my_verif_params_pkg::CLK_PHASE_OFFSET_NS)%my_verif_params_pkg::CLK_PERIOD_NS != 0) begin
            `uvm_warning("WARNING", $sformatf("Current time is not aligned with the clock edge. Current time: %0d", curr_time))
        end

        unique case (item.drv_cmd)
            my_rt_sig_seq_item::DRV_CMD_NOP:
                ; // nothing to do
            my_rt_sig_seq_item::DRV_CMD_RESET:
                reset_dut();
            my_rt_sig_seq_item::DRV_CMD_INPUT_VEC:
                input_vec(item.input_vec);
        endcase

        seq_item_port.item_done(); // Tell the sequencer that the item is done.

        if (item.is_last_item) begin
            `uvm_info("INFO", "Got last item in the sequence.", UVM_MEDIUM);
            break;
        end
    end

    phase.drop_objection(this);
endtask

`undef WAIT_CLK_POSEDGE
