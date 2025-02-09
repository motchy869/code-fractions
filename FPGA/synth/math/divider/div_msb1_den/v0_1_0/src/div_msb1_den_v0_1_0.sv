// Verible directive
// verilog_lint: waive-start parameter-name-style
// verilog_lint: waive-start line-length

`ifndef DIV_MSB1_DEN_V0_1_0_SV_INCLUDED
`define DIV_MSB1_DEN_V0_1_0_SV_INCLUDED

`default_nettype none

//! A pipelined unsigned integer divider with **MSB-1** denominator.
//! All outputs are buffered.
//! This module can be used only when the denominator's MSB is 1.
//!
//! - input: `num`, numerator, a `BW_NUM`-bit unsigned integer
//! - input: `den`, denominator, a `BW_DEN`-bit positive integer, whose **MSB is 1**.
//! - output: `quo`, quotient, a `BW_NUM-BW_DEN+1`(=:`BW_QUO`)-bit unsigned integer
//! - output: `rem`, remainder, a `BW_DEN`-bit unsigned integer
//! - latency: `BW_QUO` clock cycles
module div_msb1_den_v0_1_0 #(
    parameter int unsigned BW_NUM = 8, //! bit width of the numerator
    parameter int unsigned BW_DEN = 4 //! bit width of the denominator, must be in the range {1, 2, ..., `BW_NUM`}
)(
    //! @virtualbus cont_if @dir in control interface
    input wire logic i_clk, //! input clock
    input wire logic i_sync_rst, //! input reset signal synchronous to the input clock
    input wire logic i_freeze, //! freeze directive, which stops all state transitions except for the reset
    //! @end
    //! @virtualbus us_side_if @dir in upstream side interface
    //! input numerator
    input wire logic [BW_NUM-1:0] i_num,
    input wire logic [BW_DEN-1:0] i_den, //! input denominator, must be a positive integer whose **MSB is 1**
    //! @end
    //! @virtualbus ds_side_if @dir out downstream side interface
    //! output quotient
    output wire logic [BW_NUM-BW_DEN:0] o_quo,
    output wire logic [BW_DEN-1:0] o_rem //! output remainder
    //! @end
);
// ---------- parameters ----------
localparam int unsigned BW_QUO = BW_NUM - BW_DEN + 1; //! bit width of the quotient
localparam int unsigned LAT_CYC = BW_QUO; //! latency in clock cycle
// --------------------

// ---------- parameter validation ----------
generate
    if (BW_DEN < 1) begin: gen_BW_DEN_lower_bound_validation
        nonexistent_module_to_throw_a_custom_error_message_for too_small_BW_DEN();
    end
    if (BW_NUM < BW_DEN) begin: gen_BW_NUM_lower_bound_validation
        nonexistent_module_to_throw_a_custom_error_message_for too_small_BW_NUM();
    end
endgenerate
// --------------------

// ---------- brief sketch ----------
//
// Unused bits will be optimized away by the synthesizer.
// var logic [LAT_CYC-2:0][BW_DEN-1:0] den_buf;
// var logic [LAT_CYC-1:0][BW_NUM-1:0] num_buf;
// wire logic [LAT_CYC-1:0] quo_comb;
// var logic [LAT_CYC-1:0][BW_QUO-1:0] quo_buf;
//
// quo_comb[0] = i_num[BW_QUO-1+:BW_DEN] >= i_den;
// quo_buf[0][BW_QUO-1] <= quo_comb[0];
// num_buf[0] <= {i_num[BW_QUO-1+:BW_DEN] - quo_comb[0]*i_den, i_num[0+:BW_QUO-1]};
// den_buf[0] <= i_den;
//
// quo_comb[1] = num_buf[0][BW_QUO-2+:BW_DEN+1] >= den_buf[0];
// quo_buf[1][BW_QUO-2+:2] <= {quo_buf[0][BW_QUO-1+:1], quo_comb[1]};
// num_buf[1][0+:BW_NUM-1] <= {BW_DEN'(num_buf[0][BW_QUO-2+:BW_DEN+1] - quo_comb[1]*den_buf[0]), num_buf[0][0+:BW_QUO-2]};
// den_buf[1] <= den_buf[0];

// quo_comb[2] = num_buf[1][BW_QUO-3+:BW_DEN+1] >= den_buf[1];
// quo_buf[2][BW_QUO-3+:3] <= {quo_buf[1][BW_QUO-2+:2], quo_comb[2]};
// num_buf[2][0+:BW_NUM-2] <= {BW_DEN'(num_buf[1][BW_QUO-3+:BW_DEN+1] - quo_comb[2]*den_buf[1]), num_buf[1][0+:BW_QUO-3]};
// den_buf[2] <= den_buf[1];

// ...

// quo_comb[p] = num_buf[p-1][BW_QUO-p-1+:BW_DEN+1] >= den_buf[p-1];
// quo_buf[p][BW_QUO-p-1+:p+1] <= {quo_buf[p-1][BW_QUO-p+:p], quo_comb[p]};
// num_buf[p][0+:BW_NUM-p] <= {BW_DEN'(num_buf[p-1][BW_QUO-p-1+:BW_DEN+1] - quo_comb[p]*den_buf[p-1]), num_buf[p-1][0+:BW_QUO-p-1]};
// den_buf[p] <= den_buf[p-1];

// quo_comb[LAT_CYC-1] = num_buf[LAT_CYC-2][BW_QUO-LAT_CYC+:BW_DEN+1] >= den_buf[LAT_CYC-2]; // == num_buf[LAT_CYC-2][0+:BW_DEN+1] >= den_buf[LAT_CYC-2]
// quo_buf[LAT_CYC-1][BW_QUO-LAT_CYC+:LAT_CYC] <= {quo_buf[LAT_CYC-2][BW_QUO-LAT_CYC+1+:LAT_CYC-1], quo_comb[LAT_CYC-1]}; // ⇔ quo_buf[LAT_CYC-1][0+:BW_QUO] <= {quo_buf[LAT_CYC-2][1+:BW_QUO-1], quo_comb[LAT_CYC-1]};
// num_buf[LAT_CYC-1][0+:BW_NUM-LAT_CYC+1] <= {BW_DEN'(num_buf[LAT_CYC-2][BW_QUO-LAT_CYC+:BW_DEN+1] - quo_comb[LAT_CYC-1]*den_buf[LAT_CYC-2]), num_buf[LAT_CYC-2][0+:BW_QUO-LAT_CYC]}; // ⇔ num_buf[LAT_CYC-1][0+:BW_DEN] <= BW_DEN'(num_buf[LAT_CYC-2][0+:BW_DEN+1] - quo_comb[LAT_CYC-1]*den_buf[LAT_CYC-2]);

// assign o_quo = quo_buf[LAT_CYC-1];
// assign o_rem = num_buf[LAT_CYC-1];
// --------------------

// ---------- functions ----------
// --------------------

// ---------- signals and storage ----------
var logic [LAT_CYC-2:0][BW_DEN-1:0] r_den_buf; //! denominator pipeline buffer
var logic [LAT_CYC-1:0][BW_NUM-1:0] r_num_buf; //! numerator pipeline buffer
wire [LAT_CYC-1:0] g_quo_comb; //! quotient pipeline combinatorial logic
var logic [LAT_CYC-1:0][BW_QUO-1:0] r_quo_buf; //! quotient pipeline buffer
// --------------------

// ---------- instances ----------
// --------------------

// ---------- Drives output signals. ----------
assign o_quo = r_quo_buf[LAT_CYC-1];
assign o_rem = r_num_buf[LAT_CYC-1][0+:BW_DEN];
// --------------------

// ---------- blocks ----------
//! Updates denominator pipeline buffer.
always_ff @(posedge i_clk) begin: blk_update_den_pip_buf
    if (i_sync_rst) begin
        r_den_buf <= '0;
    end else if (~i_freeze) begin
        r_den_buf <= {r_den_buf[0+:LAT_CYC-2], i_den};
    end
end

//! Updates numerator pipeline buffer.
always_ff @(posedge i_clk) begin: blk_update_num_pip_buf_end_parts
    if (i_sync_rst) begin
        r_num_buf[0] <= '0;
        r_num_buf[LAT_CYC-1] <= '0;
    end else if (~i_freeze) begin
        r_num_buf[0] <= {i_num[BW_QUO-1+:BW_DEN] - ({BW_DEN{g_quo_comb[0]}}&i_den), i_num[0+:BW_QUO-1]};
        r_num_buf[LAT_CYC-1][0+:BW_DEN] <= BW_DEN'(r_num_buf[LAT_CYC-2][0+:BW_DEN+1] - ({(BW_DEN+1){g_quo_comb[LAT_CYC-1]}}&(BW_DEN+1)'(r_den_buf[LAT_CYC-2])));
    end
end

genvar p_gen;
generate
    for (p_gen=1; p_gen<LAT_CYC-1; ++p_gen) begin: gen_update_num_pip_buf_middle_part
        always_ff @(posedge i_clk) begin: blk_update_num_pip_buf_middle_part
            if (i_sync_rst) begin
                r_num_buf[p_gen] <= '0;
            end else if (~i_freeze) begin
                if (p_gen == 1) begin
                    // $display("[time=%t] p_gen=%0d, r_num_buf[p_gen-1][0+:BW_QUO-p_gen-1] = %08b, r_num_buf[p_gen-1][BW_QUO-p_gen-1+:BW_DEN+1] = %08b, g_quo_comb[p_gen] = %1b", $realtime, p_gen, r_num_buf[p_gen-1][0+:BW_QUO-p_gen-1], r_num_buf[p_gen-1][BW_QUO-p_gen-1+:BW_DEN+1], g_quo_comb[p_gen]);
                    // $display("[time=%t] p_gen=%0d, BW_DEN'(r_num_buf[p_gen-1][BW_QUO-p_gen-1+:BW_DEN+1] - g_quo_comb[p_gen]*r_den_buf[p_gen-1]) = %08b", $realtime, p_gen, BW_DEN'(r_num_buf[p_gen-1][BW_QUO-p_gen-1+:BW_DEN+1] - g_quo_comb[p_gen]*r_den_buf[p_gen-1]));
                    // $display("[time=%t] p_gen=%0d, {BW_DEN{g_quo_comb[p_gen]}}&r_den_buf[p_gen-1] = %08b", $realtime, p_gen, {BW_DEN{g_quo_comb[p_gen]}}&r_den_buf[p_gen-1]);
                    // $display("[time=%t] p_gen=%0d, {BW_DEN'(r_num_buf[p_gen-1][BW_QUO-p_gen-1+:BW_DEN+1] - ({(BW_DEN+1){g_quo_comb[p_gen]}}&(BW_DEN+1)'(r_den_buf[p_gen-1]))), r_num_buf[p_gen-1][0+:BW_QUO-p_gen-1]} = %08b", $realtime, p_gen, {BW_DEN'(r_num_buf[p_gen-1][BW_QUO-p_gen-1+:BW_DEN+1] - {(BW_DEN+1){g_quo_comb[p_gen]}}&r_den_buf[p_gen-1]), r_num_buf[p_gen-1][0+:BW_QUO-p_gen-1]});
                end
                r_num_buf[p_gen][0+:BW_NUM-p_gen] <= {BW_DEN'(r_num_buf[p_gen-1][BW_QUO-p_gen-1+:BW_DEN+1] - ({(BW_DEN+1){g_quo_comb[p_gen]}}&(BW_DEN+1)'(r_den_buf[p_gen-1]))), r_num_buf[p_gen-1][0+:BW_QUO-p_gen-1]};
            end
        end
    end
endgenerate

//! Calculates quotient pipeline combinatorial logic.
assign g_quo_comb[0] = i_num[BW_QUO-1+:BW_DEN] >= i_den;
generate
    for (p_gen=1; p_gen<LAT_CYC; ++p_gen) begin: gen_calc_quo_comb
        assign g_quo_comb[p_gen] = r_num_buf[p_gen-1][BW_QUO-p_gen-1+:BW_DEN+1] >= (BW_DEN+1)'(r_den_buf[p_gen-1]);
    end
endgenerate

//! Updates quotient pipeline buffer.
always_ff @(posedge i_clk) begin: blk_update_quo_pip_buf_1st_stg
    if (i_sync_rst) begin
        r_quo_buf[0] <= '0;
    end else if (~i_freeze) begin
        r_quo_buf[0][BW_QUO-1] <= g_quo_comb[0];
    end
end

generate
    for (p_gen=1; p_gen<LAT_CYC; ++p_gen) begin: gen_update_quo_pip_buf_2nd_and_after_stg
        always_ff @(posedge i_clk) begin: blk_update_quo_pip_buf_2nd_and_after_stg
            if (i_sync_rst) begin
                r_quo_buf[p_gen] <= '0;
            end else if (~i_freeze) begin
                r_quo_buf[p_gen][BW_QUO-p_gen-1+:p_gen+1] <= {r_quo_buf[p_gen-1][BW_QUO-p_gen+:p_gen], g_quo_comb[p_gen]};
            end
        end
    end
endgenerate
// --------------------
endmodule

`default_nettype wire
`endif // DIV_MSB1_DEN_V0_1_0_SV_INCLUDED
