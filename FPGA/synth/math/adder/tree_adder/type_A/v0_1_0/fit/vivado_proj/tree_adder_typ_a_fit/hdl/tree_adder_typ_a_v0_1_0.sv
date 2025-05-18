// Verible directive
// verilog_lint: waive-start parameter-name-style
// verilog_lint: waive-start line-length

`ifndef TREE_ADDER_TYP_A_V0_1_0_SV_INCLUDED
`define TREE_ADDER_TYP_A_V0_1_0_SV_INCLUDED

`default_nettype none

//! An integer tree-like adder.
//! This module calculates the sum of a given set of input elements using tree-like adder structure.
//!
//! The number of adder is ```N_IN_ELEMS-1``` and the cycle latency is ```$clog2(N_IN_ELEMS)``` where ```N_IN_ELEMS``` is the number of input elements.
//! The output bit width is ```(BW_IN_ELEM-1) + $clog2(N_IN_ELEMS+1) + 1``` (because the possible minimum sum is ```-N_IN_ELEMS*(2**(BW_IN_ELEM-1))```).
//!
//! There is **no handshake** function, so a parent module must handle the flow control.
module tree_adder_typ_a_v0_1_0 #(
    parameter int unsigned N_IN_ELEMS = 9, //! number of input elements, must be 2 or greater
    parameter int unsigned BW_IN_ELEM = 8 //! bit width of each input element
)(
    //! @virtualbus cont_if @dir in control interface
    //! clock signal
    input wire logic i_clk,
    input wire logic i_sync_rst, //! reset signal synchronous to clock
    input wire logic i_freeze, //! Freeze directive, which stops all state transitions except for the reset. this signal can be used to flow control by the parent module.
    //! @end
    //! @virtualbus us_side_if @dir in upstream side interface
    input wire logic [N_IN_ELEMS-1:0][BW_IN_ELEM-1:0] i_elems, //! input elements, treated as **SIGNED** internally
    //! @end
    //! @virtualbus ds_side_if @dir out downstream side interface
    //! Signal indicating that the output vector is valid. This is **ONLY** for initial garbage data skipping, **NOT** for flow control.
    output wire logic o_out_vld,
    output wire logic signed [(BW_IN_ELEM-1)+$clog2(N_IN_ELEMS+1)+1-1:0] o_sum //! output sum
    //! @end
);
// ---------- imports ----------
// --------------------

// ---------- parameters ----------
localparam int unsigned TREE_HEIGHT = $clog2(N_IN_ELEMS); //! tree height
localparam int unsigned TREE_WIDTH = N_IN_ELEMS/2 + (N_IN_ELEMS%2); //! tree width
localparam int unsigned BW_OUT = (BW_IN_ELEM-1) + $clog2(N_IN_ELEMS+1) + 1; //! output bit width
// --------------------

// ---------- parameter validation ----------
generate
    if (N_IN_ELEMS < 2) begin: gen_too_small_N_IN_ELEMS
        nonexistent_module_to_throw_a_custom_error_message_for_too_small_N_IN_ELEMS inst();
    end
    if (BW_IN_ELEM < 1) begin: gen_too_small_BW_IN_ELEM
        nonexistent_module_to_throw_a_custom_error_message_for_too_small_BW_IN_ELEM inst();
    end
endgenerate
// --------------------

// ---------- brief sketch ----------
// --------------------

// ---------- functions ----------
typedef logic signed [BW_OUT-1:0] min_max_t;
typedef logic [31:0] uint_t;

typedef struct packed {
    uint_t [TREE_HEIGHT-1:0] n_elems; // number of elements in each depth
    logic [TREE_HEIGHT-1:0][TREE_WIDTH-1:0] type_mat; // Type matrix, the (i,j)-th element stores the type of the element at that position. 1 for adder, 0 for pass-through
    min_max_t [TREE_HEIGHT-1:0][TREE_WIDTH-1:0] min_val_mat; // minimum value matrix, the (i,j)-th element stores the minimum value of the adder/pass-through at that position
    uint_t [TREE_HEIGHT-1:0][TREE_WIDTH-1:0] bw_mat; // bit width matrix
} adder_plan_t;

//! Counts the number of leading ones in a given value.
function automatic int unsigned cntLdgOnes(input logic [BW_OUT-1:0] val);
    int unsigned cnt = 0;
    for (int i=BW_OUT-1; i>=0; --i) begin
        if (val[i] == 1'b1) begin
            ++cnt;
        end else begin
            break;
        end
    end
    return cnt;
endfunction

//! Calculates the bit width of each adder.
function automatic adder_plan_t planAdders();
    adder_plan_t plan = '{default:'0};
    int unsigned n_adders, n_curr_summands;

    // depth 0
    n_adders = N_IN_ELEMS/2;
    plan.n_elems[0] = n_adders + uint_t'(N_IN_ELEMS[0]);
    for (int unsigned i=0; i<n_adders; ++i) begin
        plan.type_mat[0][i] = 1'b1; // adder
        plan.min_val_mat[0][i] = BW_OUT'(2)*BW_OUT'(signed'({1'b1, (BW_IN_ELEM-1)'(1'b0)}));
        plan.bw_mat[0][i] = BW_IN_ELEM+1;
    end
    if (N_IN_ELEMS[0] == 1'b1) begin
        plan.min_val_mat[0][n_adders] = BW_OUT'(signed'({1'b1, (BW_IN_ELEM-1)'(1'b0)}));
        plan.bw_mat[0][n_adders] = BW_IN_ELEM;
    end

    // depth 1 and above
    n_curr_summands = plan.n_elems[0];
    for (int unsigned d=1; d<TREE_HEIGHT; ++d) begin
        n_adders = n_curr_summands/2;
        plan.n_elems[d] = n_adders + uint_t'(n_curr_summands[0]);
        for (int unsigned i=0; i<n_adders; ++i) begin
            plan.type_mat[d][i] = 1'b1; // adder
            plan.min_val_mat[d][i] = plan.min_val_mat[d-1][2*i] + plan.min_val_mat[d-1][2*i+1];
            plan.bw_mat[d][i] = BW_OUT - cntLdgOnes(plan.min_val_mat[d][i]) + 1;
        end
        if (n_curr_summands[0] == 1'b1) begin
            plan.min_val_mat[d][n_adders] = plan.min_val_mat[d-1][2*n_adders];
            plan.bw_mat[d][n_adders] = plan.bw_mat[d-1][2*n_adders];
        end
        n_curr_summands = plan.n_elems[d];
    end

    return plan;
endfunction
// --------------------

// ---------- signals and storage ----------
var logic [TREE_HEIGHT-1:0] r_vld_dly_line; //! delayed valid signal

localparam adder_plan_t adder_plan = planAdders();
generate
    for (genvar d=0; d<TREE_HEIGHT; ++d) begin: gen_elem_depth
        for (genvar i=0; i<adder_plan.n_elems[d]; ++i) begin: gen_elem_horiz
            var logic signed [adder_plan.bw_mat[d][i]-1:0] r_elem; //! element, sum/pass-through
        end
    end
endgenerate
// --------------------

// ---------- instances ----------
// --------------------

// ---------- Drives output signals. ----------
assign o_out_vld = r_vld_dly_line[TREE_HEIGHT-1];
assign o_sum = gen_elem_depth[TREE_HEIGHT-1].gen_elem_horiz[0].r_elem;
// --------------------

// ---------- blocks ----------
//! Update valid delay line
always_ff @(posedge i_clk) begin: blk_update_vld_dly_line
    if (i_sync_rst) begin
        r_vld_dly_line <= '0;
    end else if (!i_freeze) begin
        r_vld_dly_line <= {r_vld_dly_line[0+:TREE_HEIGHT-1], 1'b1};
    end
end

//! Update depth-0 elements
generate
    for (genvar i=0; i<adder_plan.n_elems[0]; ++i) begin: gen_update_d0
        always_ff @(posedge i_clk) begin: blk_update_d0
            if (i_sync_rst) begin
                gen_elem_depth[0].gen_elem_horiz[i].r_elem <= '0;
            end else if (!i_freeze) begin
                localparam int unsigned BW = adder_plan.bw_mat[0][i];
                localparam logic elem_type = adder_plan.type_mat[0][i];
                if (elem_type) begin
                    gen_elem_depth[0].gen_elem_horiz[i].r_elem <= BW'(signed'(i_elems[2*i])) + BW'(signed'(i_elems[2*i+uint_t'(elem_type)]));
                end else begin
                    gen_elem_depth[0].gen_elem_horiz[i].r_elem <= BW'(signed'(i_elems[2*i]));
                end
            end
        end
    end
endgenerate

//! Update depth-1-and_above elements
generate
    for (genvar d=1; d<TREE_HEIGHT; ++d) begin: gen_update_depth
        for (genvar i=0; i<adder_plan.n_elems[d]; ++i) begin: gen_update_horiz
            always_ff @(posedge i_clk) begin: blk_update_dx
                if (i_sync_rst) begin
                    gen_elem_depth[d].gen_elem_horiz[i].r_elem <= '0;
                end else if (!i_freeze) begin
                    localparam int unsigned BW = adder_plan.bw_mat[d][i];
                    localparam logic elem_type = adder_plan.type_mat[d][i];
                    if (elem_type) begin
                        //gen_elem_depth[d].gen_elem_horiz[i].r_elem <= BW'(gen_elem_depth[d-1].gen_elem_horiz[2*i].r_elem) + BW'(gen_elem_depth[d-1].gen_elem_horiz[2*i+1].r_elem); // This causes elaboration errors 'Can't find definition of 'r_elem' in dotted signal: 'gen_elem_depth__BRA__<some number>__KET__.gen_elem_horiz__BRA__<some number>__KET__.r_elem'.
                        gen_elem_depth[d].gen_elem_horiz[i].r_elem <= BW'(gen_elem_depth[d-1].gen_elem_horiz[2*i].r_elem) + BW'(gen_elem_depth[d-1].gen_elem_horiz[2*i+elem_type].r_elem);
                    end else begin
                        gen_elem_depth[d].gen_elem_horiz[i].r_elem <= BW'(gen_elem_depth[d-1].gen_elem_horiz[2*i].r_elem);
                    end
                end
            end
        end
    end
endgenerate
// --------------------
endmodule

`default_nettype wire

`endif // TREE_ADDER_TYP_A_V0_1_0_SV_INCLUDED
