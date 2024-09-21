`ifndef CPLX_NUM_IF_SVH_INCLUDED
`define CPLX_NUM_IF_SVH_INCLUDED

// Verible directive
// verilog_lint: waive-start parameter-name-style
// verilog_lint: waive-start line-length
// verilog_lint: waive-start interface-name-style

interface cplx_num_if #(
    parameter int unsigned BIT_WIDTH = 8 //! bit width of the real and imaginary parts
)();
    typedef struct packed {
        logic signed [BIT_WIDTH-1:0] re; //! real part
        logic signed [BIT_WIDTH-1:0] im; //! imaginary part
    } complex_t;

    complex_t num;
endinterface

`endif // CPLX_NUM_IF_SVH_INCLUDED
