// Verible directive
// verilog_lint: waive-start line-length
// verilog_lint: waive-start parameter-name-style

`include "my_verif_pkg.svh"
`include "../simple_dut.svh"

`default_nettype none

//! test bench top module
module my_test_bench;
    import uvm_pkg::*;

    // ---------- parameters ----------
    // --------------------

    // ---------- internal signal and storage ----------
    var bit r_clk; //! clock signal
    my_verif_pkg::bus_vif_t bus_vif; //! virtual interface for `bus_if`
    virtual interface my_rt_sig_if rt_sig_vif; //! virtual interface for `rt_sig_if`
    // --------------------

    // ---------- instances ----------
    //! AXI4-Lite interface between test bench and DUT
    axi4_lite_if#(
        .ADDR_BIT_WIDTH(my_verif_params_pkg::AXI4_LITE_ADDR_BIT_WIDTH),
        .DATA_BIT_WIDTH(my_verif_params_pkg::AXI4_LITE_DATA_BIT_WIDTH)
    ) bus_if (.i_clk(r_clk));

    //! real-time signal interface between test bench and DUT
    my_rt_sig_if rt_sig_if (.i_clk(r_clk));

    //! DUT instance
    simple_dut#(
        .AXI4_LITE_ADDR_BIT_WIDTH(my_verif_params_pkg::AXI4_LITE_ADDR_BIT_WIDTH),
        .AXI4_LITE_DATA_BIT_WIDTH(my_verif_params_pkg::AXI4_LITE_DATA_BIT_WIDTH)
    ) dut (
        .i_clk(r_clk),
        .i_sync_rst(rt_sig_if.sync_rst),
        .if_s_axi4_lite(bus_if.slv_port),
        .i_vec(rt_sig_if.input_vec),
        .i_vec_valid(rt_sig_if.input_vec_valid),
        .or_in_prod(rt_sig_if.inner_prod),
        .or_in_prod_valid(rt_sig_if.inner_prod_valid)
    );
    // --------------------

    //! Drive the clock.
    initial begin
        #my_verif_params_pkg::CLK_PHASE_OFFSET_NS;
        r_clk = ~r_clk;
        forever #(my_verif_params_pkg::CLK_PERIOD_NS/2) r_clk = ~r_clk;
    end

    //! Run test.
    initial begin
        bus_vif = bus_if;
        rt_sig_vif = rt_sig_if;
        uvm_config_db#(my_verif_pkg::bus_vif_t)::set(null, "uvm_test_top", "g_bus_vif", bus_vif);
        uvm_config_db#(virtual my_rt_sig_if)::set(null, "uvm_test_top", "g_rt_sig_vif", rt_sig_vif);
        run_test();
    end
endmodule

`default_nettype wire
