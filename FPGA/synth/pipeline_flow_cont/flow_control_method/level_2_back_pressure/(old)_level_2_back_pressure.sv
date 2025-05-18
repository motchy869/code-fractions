// Verible directive
// verilog_lint: waive-start parameter-name-style
// verilog_lint: waive-start line-length

`default_nettype none

//! Computes the sum of two inputs.
//! Both feed-stop and back-pressure flow control are supported.
module level_2_back_pressure #(
    parameter int unsigned BIT_WIDTH_IN = 8 //! input bit with, must be greater than 0
)(
    input wire logic i_clk, //! input clock
    input wire logic i_sync_rst, //! input reset signal synchronous to the input clock
    input wire logic i_freeze, //! freeze directive, which stops all state transitions except for the reset
    //! @virtualbus us_side_if @dir in upstream side interface
    output wire logic o_ready, //! ready signal to upstream side which indicates that the upstream side is allowed to update input data (to this module) right AFTER the next rising edge of the clock
    input wire logic i_in_valid, //! Indicates that the input data is valid
    input wire logic signed [BIT_WIDTH_IN-1:0] i_a, //! input a
    input wire logic signed [BIT_WIDTH_IN-1:0] i_b, //! input b
    //! @end
    //! @virtualbus ds_side_if @dir out downstream side interface
    //! ready signal from downstream side which indicates that this module is allowed to update output data (to downstream side) right AFTER the next rising edge of the clock
    input wire logic i_ds_ready,
    output wire logic o_out_valid, //! Indicates that the output data is valid
    output wire logic signed [BIT_WIDTH_IN:0] o_sum //! output sum
    //! @end
);
// ---------- parameters ----------
localparam int unsigned BIT_WIDTH_OUT = BIT_WIDTH_IN + 1; //! output bit width
// --------------------

// ---------- parameter validation ----------
generate
    if (BIT_WIDTH_IN == '0) begin: gen_input_bit_width_validation
        nonexistent_module_to_throw_a_custom_error_message_for_too_small_input_bit_width inst();
    end
endgenerate
// --------------------

// ---------- functions ----------
// --------------------

// ---------- signals and storage ----------
wire g_adv_pipeline; //! signal indicating that the pipeline should advance
assign g_adv_pipeline = i_in_valid && o_ready;

// ping-pong buffer read and write pointer type
typedef struct packed {
    logic idx; //! buffer index
    logic phase; //! The buffer phase. Begins at 0 and toggles between 0 and 1 every time the index wraps around. This is utilized for distinguishing between full and empty conditions.
} ping_pong_buf_ptr_t;

typedef logic [BIT_WIDTH_OUT-1:0] output_ppb_data_t; //! output ping-pong buffer data type
var output_ppb_data_t [1:0] r_out_ping_pong_buf; //! output ping-pong buffer
var ping_pong_buf_ptr_t r_out_ppb_rd_ptr; //! output ping-pong buffer read pointer
var ping_pong_buf_ptr_t r_out_ppb_wr_ptr; //! output ping-pong buffer write pointer
wire g_out_ppb_full; //! output ping-pong buffer full signal
assign g_out_ppb_full = r_out_ppb_rd_ptr.idx == r_out_ppb_wr_ptr.idx && r_out_ppb_rd_ptr.phase != r_out_ppb_wr_ptr.phase;
wire g_out_ppb_empty; //! output ping-pong buffer empty signal
assign g_out_ppb_empty = r_out_ppb_rd_ptr.idx == r_out_ppb_wr_ptr.idx && r_out_ppb_rd_ptr.phase == r_out_ppb_wr_ptr.phase;
wire g_out_ppb_pop_en; //! output ping-pong buffer pop enable signal
assign g_out_ppb_pop_en = i_ds_ready && o_out_valid;
// --------------------

// ---------- instances ----------
// --------------------

// ---------- Drives output signals. ----------
assign o_ready = !g_out_ppb_full;
assign o_out_valid = !g_out_ppb_empty;
assign o_sum = r_out_ping_pong_buf[r_out_ppb_rd_ptr.idx];
// --------------------

// ---------- blocks ----------
//! Updates output ping-pong buffer write pointer.
always_ff @(posedge i_clk) begin: blk_update_out_ppb_wr_ptr
    if (i_sync_rst) begin
        r_out_ppb_wr_ptr <= '{default:'0};
    end else if (!i_freeze) begin
        if (g_adv_pipeline) begin
            r_out_ppb_wr_ptr.idx <= ~r_out_ppb_wr_ptr.idx;
            if (r_out_ppb_wr_ptr.idx) begin
                r_out_ppb_wr_ptr.phase <= ~r_out_ppb_wr_ptr.phase;
            end
        end
    end
end

//! Updates output ping-pong buffer read pointer.
always_ff @(posedge i_clk) begin: blk_update_out_ppb_rd_ptr
    if (i_sync_rst) begin
        r_out_ppb_rd_ptr <= '{default:'0};
    end else if (!i_freeze) begin
        if (g_out_ppb_pop_en) begin
            r_out_ppb_rd_ptr.idx <= ~r_out_ppb_rd_ptr.idx;
            if (r_out_ppb_rd_ptr.idx) begin
                r_out_ppb_rd_ptr.phase <= ~r_out_ppb_rd_ptr.phase;
            end
        end
    end
end

//! Updates output ping-pong buffer entries.
always_ff @(posedge i_clk) begin: blk_update_out_ppb_entries
    if (i_sync_rst) begin
        r_out_ping_pong_buf <= '{default:'0};
    end else if (!i_freeze) begin
        if (g_adv_pipeline) begin
            r_out_ping_pong_buf[r_out_ppb_wr_ptr.idx] <= BIT_WIDTH_OUT'(i_a) + BIT_WIDTH_OUT'(i_b);
        end
    end
end
// --------------------
endmodule

`default_nettype wire
