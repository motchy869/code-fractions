`ifndef MTY_SV_MACROS_SVH_INCLUDED
`define MTY_SV_MACROS_SVH_INCLUDED

// motchy's SystemVerilog macros

// verilog_lint: waive-start parameter-name-style
// verilog_lint: waive-start line-length

`define SIGNED_MIN_VAL_OF_BIT_WIDTH(bw) signed'({1'b1, {((bw)-1){1'b0}}})
`define SIGNED_MAX_VAL_OF_BIT_WIDTH(bw) signed'({1'b0, {((bw)-1){1'b1}}})

`define LARGER_ONE(x,y) ((x) > (y) ? (x) : (y))
`define SMALLER_ONE(x,y) ((x) < (y) ? (x) : (y))

`define ASST_VAL_IS_KNOWN(val, disable_check=1'b0) assert(disable_check || !$isunknown(val)) else begin $display("file: %s, line: %d", `__FILE__, `__LINE__); $fatal(2, "unknown value"); end
`define ASST_VAL_IN_RANGE(condition, disable_check=1'b0) assert(disable_check || condition) else begin $display("file: %s, line: %d", `__FILE__, `__LINE__); $fatal(2, "value out of range"); end
`define ASST_ALL_BITS_ARE_EQUAL(val, disable_check=1'b0) assert(disable_check || val == '0 || val == '1) else begin $display("file: %s, line: %d", `__FILE__, `__LINE__); $fatal(2, "All bits must be equal."); end

`endif // MTY_SV_MACROS_SVH_INCLUDED
