// Verible directive
// verilog_lint: waive-start parameter-name-style

`default_nettype none

module my_test_bench;
    import uvm_pkg::*;
    import my_verif_pkg::*;

    // ---------- parameters ----------
    localparam int CLK_PERIOD_NS = 8; //! clock period in ns
    localparam int SIM_TIME_LIMIT_NS = 300; //! simulation time limit in ns
    // --------------------

    // ---------- internal signal and storage ----------
    var bit r_clk; //! clock signal
    // --------------------

    //! Drive the clock.
    initial forever #(CLK_PERIOD_NS/2) r_clk = ~r_clk;

    //! Launch scenario and manage time limit.
    initial begin
        uvm_top.set_timeout(SIM_TIME_LIMIT_NS, 0);
    end
endmodule

`default_nettype wire
