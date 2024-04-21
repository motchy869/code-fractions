// Verible directive
// verilog_lint: waive-start parameter-name-style

package my_verif_params_pkg;
    typedef enum logic [1:0] {
        AXI4_RESP_OKAY = 2'b00,
        AXI4_RESP_EXOKAY = 2'b01,
        AXI4_RESP_SLVERR = 2'b10,
        AXI4_RESP_DECERR = 2'b11
    } axi4_resp_t;

    localparam int AXI4_LITE_ADDR_BIT_WIDTH = 32; //! bit width of AXI4-Lite address bus
    localparam int AXI4_LITE_DATA_BIT_WIDTH = 32; //! bit width of AXI4-Lite data bus

    localparam int CLK_PERIOD_NS = 8; //! clock period in ns
endpackage
