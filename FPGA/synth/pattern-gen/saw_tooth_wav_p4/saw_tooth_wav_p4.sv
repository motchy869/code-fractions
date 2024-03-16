`default_nettype none

`define COMB_LOGIC var logic

localparam int PARA = 4; // processing parallelism

//! Generate sawtooth waveform in 4 parallelism (4 elements/clock-cycle).
//! This module outputs 'chunk' at each clock-cycle with valid signal.
//! Each chunk normally contains 4 elements, but the last output chunk may contain less than 4 elements.
module saw_tooth_wav_p4 #(
    parameter int BW_VAL = 16, //! bit-width of output numeric value
    parameter int BW_SEQ_CONT = 16 //! bit-width of sequence control data: tread length and the number of steps
)(
    //! common ports
    input wire logic i_clk, //! input clock
    input wire logic i_sync_rst, //! input reset synchronous to the input clock

    //! @virtualbus us_side_if @dir in upstream side interface
    input wire logic ip_start, //! Start request pulse for waveform generation. The request is accepted only when `o_busy` is low. The pulse length must be 1 clock-cycle.
    input wire logic [BW_VAL-1:0] i_init_val, //! initial term value
    input wire logic [BW_SEQ_CONT-1:0] i_tread_len, //! Tread length. **Value less than 1 is translated as 1.**
    input wire logic [BW_SEQ_CONT-1:0] i_num_steps, //! The number of steps. **Value less than 1 is translated as 1.**
    //input wire logic [BW_SEQ_CONT-1:0] i_rep_num, //! the number of the repetition -> (2024-03-15) Repetition should be taken care of by the parent module.
    output `COMB_LOGIC o_busy, //! busy flag which indicates that waveform generation is in progress
    //! @end

    //! @virtualbus ds_side_if @dir out downstream side interface
    //! input ready signal which indicates that the downstream is ready to accept the output chunk
    input wire logic i_ds_ready,
    output `COMB_LOGIC o_chunk_valid, //! output valid signal which indicates that the output chunk is valid
    output `COMB_LOGIC [$clog2(PARA+1)-1:0] o_chunk_elem_cnt, //! the number of the valid elements in the chunk
    output `COMB_LOGIC [PARA-1:0] o_chunk //! output chunk
    //! @end
);

//! parameter validation
generate
    if (BW_VAL < 1) begin: gen_BW_VAL_validation
        $error("BW_VAL must be greater than or equal to 1");
    end

    if (BW_SEQ_CONT < 1) begin: gen_BW_SEQ_CONT_validation
        $error("BW_SEQ_CONT must be greater than or equal to 1");
    end
endgenerate

// ---------- working signals and storage ----------
// input clipping
wire logic [BW_SEQ_CONT-1:0] g_clipped_tread_len; //! clipped tread length
assign g_clipped_tread_len = i_tread_len == '0 ? BW_SEQ_CONT'(1) : i_tread_len;
wire logic [BW_SEQ_CONT-1:0] g_clipped_num_steps; //! clipped version of the number of steps
assign g_clipped_num_steps = i_num_steps == '0 ? BW_SEQ_CONT'(1) : i_num_steps;

typedef enum {
    TREAD_LEN_PTN_E__TL1, TREAD_LEN_PTN_E__TL2_4, TREAD_LEN_PTN_E__TL3, TREAD_LEN_PTN_E__TL_GT4
} tread_len_ptn_e;

tread_len_ptn_e g_tread_len_ptn_sel; //! selection of sub module specialized for specific tread length
assign g_tread_len_ptn_sel = g_clipped_tread_len == BW_SEQ_CONT'(1) ? TREAD_LEN_PTN_E__TL1 :
    g_clipped_tread_len inside {BW_SEQ_CONT'(2), BW_SEQ_CONT'(4)} ? TREAD_LEN_PTN_E__TL2_4 :
    g_clipped_tread_len == BW_SEQ_CONT'(3) ? TREAD_LEN_PTN_E__TL3 :
    TREAD_LEN_PTN_E__TL_GT4; // g_clipped_tread_len > 4


typedef struct {
    logic busy;
    logic chunk_valid;
    logic [$clog2(PARA+1)-1:0] chunk_elem_cnt;
    logic [PARA-1:0] chunk;
} sub_mod_out_t; //! output signals of sub module specialized for specific tread length

wire sub_mod_out_t w_sub_mod_out_tl1; //! output signals from sub module specialized for tread length 1
wire sub_mod_out_t w_sub_mod_out_tl2_4; //! output signals from sub module specialized for tread length 2 and 4
wire sub_mod_out_t w_sub_mod_out_tl3; //! output signals from sub module specialized for tread length 3
wire sub_mod_out_t w_sub_mod_out_tl_gt4; //! output signals from sub module specialized for tread length greater than 4
// --------------------

// ---------- sub modules ----------
`uselib file=saw_tooth_wav_p4_tl1.sv
saw_tooth_wav_p4_tl1 stw_p4_tl1(
    .i_clk(i_clk), .i_sync_rst(i_sync_rst),

    .ip_start(g_tread_len_ptn_sel == TREAD_LEN_PTN_E__TL1 && ip_start),
    .i_init_val(i_init_val),
    .i_num_steps(g_clipped_num_steps),
    .o_busy(w_sub_mod_out_tl1.busy),

    .i_ds_ready(i_ds_ready),
    .o_chunk_valid(w_sub_mod_out_tl1.chunk_valid),
    .o_chunk_elem_cnt(w_sub_mod_out_tl1.chunk_elem_cnt),
    .o_chunk(w_sub_mod_out_tl1.chunk)
);

`uselib file=saw_tooth_wav_p4_tl2_4.sv
saw_tooth_wav_p4_tl2_4 stw_p4_tl2_4(
    .i_clk(i_clk), .i_sync_rst(i_sync_rst),

    .ip_start(g_tread_len_ptn_sel == TREAD_LEN_PTN_E__TL2_4 && ip_start),
    .i_init_val(i_init_val),
    .i_tread_len(g_clipped_tread_len == BW_SEQ_CONT'(2) ? BW_SEQ_CONT'(0) : BW_SEQ_CONT'(1)),
    .i_num_steps(g_clipped_num_steps),
    .o_busy(w_sub_mod_out_tl2_4.busy),

    .i_ds_ready(i_ds_ready),
    .o_chunk_valid(w_sub_mod_out_tl2_4.chunk_valid),
    .o_chunk_elem_cnt(w_sub_mod_out_tl2_4.chunk_elem_cnt),
    .o_chunk(w_sub_mod_out_tl2_4.chunk)
);

`uselib file=saw_tooth_wav_p4_tl3.sv
saw_tooth_wav_p4_tl3 stw_p4_tl3(
    .i_clk(i_clk), .i_sync_rst(i_sync_rst),

    .ip_start(g_tread_len_ptn_sel == TREAD_LEN_PTN_E__TL3 && ip_start),
    .i_init_val(i_init_val),
    .i_num_steps(g_clipped_num_steps),
    .o_busy(w_sub_mod_out_tl3.busy),

    .i_ds_ready(i_ds_ready),
    .o_chunk_valid(w_sub_mod_out_tl3.chunk_valid),
    .o_chunk_elem_cnt(w_sub_mod_out_tl3.chunk_elem_cnt),
    .o_chunk(w_sub_mod_out_tl3.chunk)
);

`uselib file=saw_tooth_wav_p4_tl_gt4.sv
saw_tooth_wav_p4_tl_gt4 stw_p4_tl_gt4(
    .i_clk(i_clk), .i_sync_rst(i_sync_rst),

    .ip_start(g_tread_len_ptn_sel == TREAD_LEN_PTN_E__TL_GT4 && ip_start),
    .i_init_val(i_init_val),
    .i_tread_len(g_clipped_tread_len),
    .i_num_steps(g_clipped_num_steps),
    .o_busy(w_sub_mod_out_tl_gt4.busy),

    .i_ds_ready(i_ds_ready),
    .o_chunk_valid(w_sub_mod_out_tl_gt4.chunk_valid),
    .o_chunk_elem_cnt(w_sub_mod_out_tl_gt4.chunk_elem_cnt),
    .o_chunk(w_sub_mod_out_tl_gt4.chunk)
);
// --------------------

// Drive output signals.
always_comb begin
    case (g_tread_len_ptn_sel)
        TREAD_LEN_PTN_E__TL1: begin
        end
        TREAD_LEN_PTN_E__TL2_4: begin
        end
        TREAD_LEN_PTN_E__TL3: begin
        end
        TREAD_LEN_PTN_E__TL_GT4: begin
        end
    endcase
end

endmodule

`default_nettype wire
