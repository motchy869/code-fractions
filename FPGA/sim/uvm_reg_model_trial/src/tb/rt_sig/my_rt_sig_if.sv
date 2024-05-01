// Verible directive
// verilog_lint: waive-start line-length

`default_nettype none

//! An interface to DUT.
    //! This is focused on the real-time signals.
interface my_rt_sig_if (
    input wire logic i_clk //! clock
);
    logic sync_rst;
    logic [3:0][my_verif_params_pkg::AXI4_LITE_DATA_BIT_WIDTH-1:0] input_vec;
    logic input_vec_valid;
    logic [my_verif_params_pkg::AXI4_LITE_DATA_BIT_WIDTH-1:0] inner_prod;
    logic inner_prod_valid;

    // Vivado 2023.2 [VRFC 10-9175] modport should not be used in a hierarchical reference
    // //! driver port
    // modport drv_port(
    // ...
    // );
    // //! collector port
    // modport col_port(
    // ...
    // );

    clocking drv_cb @(posedge i_clk); // clocking block for driver
        default input #1 output #1;
        output sync_rst;
        output input_vec;
        output input_vec_valid;
        input inner_prod;
        input inner_prod_valid;
    endclocking

    clocking col_cb @(posedge i_clk); // clocking block for collector
        default input #1 output #1;
        input sync_rst;
        input input_vec;
        input input_vec_valid;
        input inner_prod;
        input inner_prod_valid;
    endclocking
endinterface

`default_nettype wire
