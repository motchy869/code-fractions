// Verible directive
// verilog_lint: waive-start parameter-name-style
// verilog_lint: waive-start line-length

`default_nettype none

//! top module
module top (
    input wire logic CLK, //! clock input
    input wire logic RST, //! reset input
    output reg [2:0] LED_RGB //! RGB LED output
);
// ---------- imports ----------
// --------------------

// ---------- parameters ----------
localparam int unsigned N_IN_ELEMS = 9; //! number of input elements
localparam int unsigned BW_IN_ELEM = 8; //! bit width of each input element
localparam int unsigned BW_SUM = (BW_IN_ELEM-1)+$clog2(N_IN_ELEMS+1)+1; //! bit width of output sum
localparam int unsigned N_UNQ_TEST_VECS = 10; //! number of unique test vectors
// --------------------

// ---------- parameter validation ----------
// --------------------

// ---------- functions ----------
typedef logic signed [BW_IN_ELEM-1:0] elem_t; //! element data type
typedef logic signed [BW_SUM-1:0] sum_t; //! sum data type

//! function to generate test vectors
function automatic elem_t [N_UNQ_TEST_VECS-1:0][N_IN_ELEMS-1:0] genTestVecs();
    elem_t [N_UNQ_TEST_VECS-1:0][N_IN_ELEMS-1:0] test_vecs;
    for (int i=0; i<N_UNQ_TEST_VECS; ++i) begin
        for (int j=0; j<N_IN_ELEMS; ++j) begin
            // test_vecs[i][j] = elem_t'($urandom(0, 2**BW_IN_ELEM-1) - 2**(BW_IN_ELEM-1)); // not supported
            // test_vecs[i][j] = elem_t'($urandom()%(2**BW_IN_ELEM) - 2**(BW_IN_ELEM-1)); // not supported
            test_vecs[i][j] = elem_t'(i*N_IN_ELEMS + j); // simple test vector
        end
    end
    return test_vecs;
endfunction;
// --------------------

// ---------- signals and storage ----------
wire logic i_clk = CLK; //! clock input
var logic [1:0] r_rst_cdc; //! 2 FFs for reset signal
wire logic g_sync_rst = r_rst_cdc[1]; //! synchronized reset signal
var elem_t [N_UNQ_TEST_VECS-1:0][N_IN_ELEMS-1:0] r_test_vecs = genTestVecs(); //! test vectors
var logic [$clog2(N_UNQ_TEST_VECS)-1:0] r_tst_vec_idx = '0; //! index of test vector to input to DUT
(* keep = "true" *) wire logic w_vld; //! output valid signal
(* keep = "true" *) wire sum_t w_sum; //! output sum
// --------------------

// ---------- instances ----------
tree_adder_typ_a_v0_1_0 #(
    .N_IN_ELEMS(N_IN_ELEMS),
    .BW_IN_ELEM(BW_IN_ELEM)
) dut (
    .i_clk(i_clk),
    .i_sync_rst(g_sync_rst),
    .i_freeze(1'b0), //! freeze signal
    .i_elems(r_test_vecs[r_tst_vec_idx]), //! test vector
    .o_out_vld(w_vld), //! output valid signal
    .o_sum(w_sum) //! output sum
);
// --------------------

// ---------- Drives output signals. ----------
assign LED_RGB[0] = w_vld;
assign LED_RGB[2:1] = w_sum[1:0];
// --------------------

// ---------- blocks ----------
//! Synchronize reset signal
always_ff @(posedge i_clk) begin: blk_rst_cdc
    r_rst_cdc <= {r_rst_cdc[0], RST};
end

//! Update test vector index
always_ff @(posedge i_clk) begin: blk_update_tst_vec_idx
    if (g_sync_rst) begin
        r_tst_vec_idx <= '0;
    end else if (r_tst_vec_idx == $clog2(N_UNQ_TEST_VECS)'(N_UNQ_TEST_VECS-1)) begin
        r_tst_vec_idx <= '0;
    end else begin
        r_tst_vec_idx <= r_tst_vec_idx + 1'b1;
    end
end
// --------------------
endmodule

`default_nettype wire
