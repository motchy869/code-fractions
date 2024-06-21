// Verible directive
// verilog_lint: waive-start parameter-name-style
// verilog_lint: waive-start line-length

`default_nettype none

module test_bench;

// ---------- types ----------
typedef struct packed {
    logic void_mkr;
} struct_a_t;

typedef struct packed {
    logic [2:0] gp_mkr;
} struct_b_t;

typedef struct packed {
    struct_a_t a;
    struct_b_t b;
} ext_info_t;
// --------------------

initial begin
    var ext_info_t [2:0] ext_info;

    ext_info[0].a.void_mkr = 1'b0;
    ext_info[0].b.gp_mkr = 3'b101;

    $display("ext_info[0].a.void_mkr = %d'%b", $bits(ext_info[0].a.void_mkr), ext_info[0].a.void_mkr);
    $display("ext_info[0].b.gp_mkr = %d'%b", $bits(ext_info[0].b.gp_mkr), ext_info[0].b.gp_mkr);
end

endmodule

`default_nettype wire
