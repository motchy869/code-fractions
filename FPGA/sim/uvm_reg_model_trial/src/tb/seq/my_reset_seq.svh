// Verible directive
// verilog_lint: waive-start line-length

//! Some techniques used in this file are based on the following source:
//! - [UVM Register Model Example](https://www.chipverify.com/uvm/uvm-register-model-example)

`ifndef MY_VERIF_PKG_SVH_INCLUDED
    $fatal("compile \"my_verif_pkg.sv\" instead of including this file");
`endif

class my_reset_seq extends uvm_sequence;
    `uvm_object_utils(my_reset_seq)

    localparam int RESET_DURATION_CLK = 20; // AXI specification requires holding reset signal at least 16 clock cycles.

    virtual my_rt_sig_if m_vif;

    // Constructor
    function new(string name = "my_reset_seq");
        super.new(name);
    endfunction

    // Entry task
    task body();
        if (!uvm_config_db#(virtual my_rt_sig_if)::get(null, "uvm_test_top", "rt_sig_vif", m_vif)) begin
            `uvm_fatal("NO-VIF", {"virtual interface must be set for: ", get_full_name(), ".rt_sig_vif"})
        end

        `uvm_info("INFO", "Resetting the DUT.", UVM_MEDIUM)
        m_vif.sync_rst <= 1'b1;
        repeat (RESET_DURATION_CLK) begin
            @(posedge m_vif.clk);
        end
        m_vif.sync_rst <= 1'b0;
        @(posedge m_vif.clk);
    endtask
endclass
