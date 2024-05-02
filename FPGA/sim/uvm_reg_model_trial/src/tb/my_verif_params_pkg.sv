// Verible directive
// verilog_lint: waive-start parameter-name-style

package my_verif_params_pkg;
    localparam int AXI4_LITE_ADDR_BIT_WIDTH = 32; //! bit width of AXI4-Lite address bus
    localparam int AXI4_LITE_DATA_BIT_WIDTH = 32; //! bit width of AXI4-Lite data bus

    localparam int CLK_PERIOD_NS = 8; //! clock period in ns
    localparam int CLK_PHASE_OFFSET_NS = CLK_PERIOD_NS/2; //! Clock phase offset in ns
endpackage
