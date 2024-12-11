// Verible directive
// verilog_lint: waive-start parameter-name-style

`default_nettype none

`define PLUS_ONE(x) (x + $bits(x)'(1))
`define INCR(x, dx) (x + $bits(x)'(dx))

localparam int P = 4; // processing parallelism
localparam int BW_CHUNK_ELEM_COUNT = $clog2(P+1); // bit-width of the number of the valid elements in chunks

//! This module generates a ramp waveform in parallelism 4 (4 elements/clock-cycle).
//! This module outputs a 'chunk' at each clock-cycle (with back-pressure from the downstream side).
//! Each chunk contains 4 elements except for the last one (may contain less than 4 elements).
module ramp_p4_v0_1_0#(
    parameter int BW_VAL = 16, //! bit-width of output numeric value
    parameter int BW_SEQ_CONT = 16 //! bit-width of sequence control data: tread length and the number of steps
)(
    //! common ports
    input wire logic i_clk, //! input clock
    input wire logic i_sync_rst, //! input reset signal synchronous to the input clock

    //! @virtualbus us_side_if @dir in upstream side interface
    input wire logic ip_start_req, //! Start request pulse for waveform generation. The request is accepted only when `o_idle` is high. The pulse length must be 1 clock-cycle.
    input wire logic signed [BW_VAL-1:0] i_init_val, //! Initial term value. Latched at starting waveform generation
    input wire logic signed [BW_VAL-1:0] i_inc_val, //! Increment value. The (n+1)-th tread value is larger than the n-th tread value by this value. This value is latched at starting waveform generation.
    input wire logic [BW_SEQ_CONT-1:0] i_tread_len, //! Tread length. When this value is less than 1, `ip_start_req` is ignored. This value is latched at starting waveform generation.
    input wire logic [BW_SEQ_CONT-1:0] i_num_treads, //! The number of treads. When this value is less than 1, `ip_start_req` is ignored. This value is latched at starting waveform generation.
    output wire logic o_idle, //! Idle flag which indicates that new start request can be issued. Masked by reset signal.
    //! @end

    //! @virtualbus ds_side_if @dir out downstream side interface
    //! input ready signal which indicates that the downstream is ready to accept the output chunk
    input wire logic i_ds_ready,
    output wire logic o_chunk_valid, //! Output valid signal which indicates that the output chunk is valid. Masked by reset signal.
    output wire logic [BW_CHUNK_ELEM_COUNT-1:0] o_chunk_elem_cnt, //! The number of the valid elements in the chunk. This value is 4 except for the last chunk (can be less than 4).
    output wire logic [P-1:0][BW_VAL-1:0] o_chunk //! output chunk
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

// ---------- internal signals and storage ----------
typedef enum {
    STAT_RST, //! reset state
    STAT_IDLE, //! idle state
    STAT_WAV_GEN //! generating waveform
} state_t;

var state_t r_curr_state; //! current operation state
var state_t g_next_state; //! operation state right after the next clock rising-edge

typedef struct packed {
    logic signed [BW_VAL-1:0] init_val; //! initial term value
    logic signed [BW_VAL-1:0] inc_val; //! increment value
    logic [BW_SEQ_CONT-1:0] tread_len; //! tread length
    logic [BW_SEQ_CONT-1:0] num_treads; //! the number of treads
} wav_param_t;

wire logic g_wav_param_good; //! indicates that waveform generation parameters are good
assign g_wav_param_good = (i_tread_len >= BW_SEQ_CONT'(1)) && (i_num_treads >= BW_SEQ_CONT'(1));
wire logic g_acceptable_start_req; //! acceptable start request
assign g_acceptable_start_req = r_curr_state == STAT_IDLE && ip_start_req && g_wav_param_good;
var wav_param_t r_wav_param; //! waveform generation parameters latched at starting waveform generation
wire logic [BW_SEQ_CONT-1:0] g_waveform_len; //! the length of the waveform
assign g_waveform_len = r_wav_param.num_treads*r_wav_param.tread_len;
wire logic g_can_goto_next_chunk; //! Indicates that the current chunk is accepted by the downstream side.
assign g_can_goto_next_chunk = o_chunk_valid && i_ds_ready;
var logic [BW_SEQ_CONT-1:0] r_sent_chunk_cnt; //! the number of chunks sent to the downstream side
var logic [BW_SEQ_CONT-1:0] r_sent_treads_cnt; //! the number of full-treads sent to the downstream side
var logic [BW_SEQ_CONT-1:0] r_intra_tread_chunk_head_pos; //! current chunk head position in the tread which the current chunk head belongs to
var logic signed [BW_VAL-1:0] r_chunk_head_val; //! the value of the current chunk head
var logic [BW_SEQ_CONT-1:0] g_next_sent_treads_cnt; //! the value of `r_sent_treads_cnt` for the next chunk.
var logic [BW_SEQ_CONT-1:0] g_next_intra_tread_chunk_head_pos; //! the value of `r_intra_tread_chunk_head_pos` for the next chunk.
var logic signed [BW_VAL-1:0] g_next_chunk_head_val; //! the value of `r_chunk_head_val` for the next chunk.
wire logic g_last_chunk_flg; //! flag indicating that the current chunk is the last one
assign g_last_chunk_flg = r_curr_state == STAT_WAV_GEN && `PLUS_ONE(r_sent_chunk_cnt)*P >= g_waveform_len;
var logic [P-1:0][BW_VAL-1:0] g_chunk; //! current chunk
// --------------------

// ---------- Drive output signals. ----------
assign o_idle = !i_sync_rst && r_curr_state == STAT_IDLE;

assign o_chunk_valid = !i_sync_rst && r_curr_state == STAT_WAV_GEN;
assign o_chunk_elem_cnt = g_last_chunk_flg ? BW_CHUNK_ELEM_COUNT'(g_waveform_len - r_sent_chunk_cnt*P) : BW_CHUNK_ELEM_COUNT'(P);
assign o_chunk = g_chunk;
// --------------------

//! Decide next operation state.
always_comb begin: decide_next_state
    unique case (r_curr_state)
        STAT_RST: begin
            g_next_state = i_sync_rst ? STAT_RST : STAT_IDLE;
        end
        STAT_IDLE: begin
            g_next_state = i_sync_rst ? STAT_RST :
            g_acceptable_start_req ? STAT_WAV_GEN : STAT_IDLE;
        end
        STAT_WAV_GEN: begin
            g_next_state = i_sync_rst ? STAT_RST :
            g_can_goto_next_chunk && g_last_chunk_flg ? STAT_IDLE : STAT_WAV_GEN;
        end
        default: begin
            $error("unexpected state");
        end
    endcase
end

//! Update `r_curr_state`.
always_ff @(posedge i_clk) begin: update_state
    if (i_sync_rst) begin
        r_curr_state <= STAT_RST;
    end else begin
        r_curr_state <= g_next_state;
    end
end

//! Update `r_wav_param`.
always_ff @(posedge i_clk) begin: update_wav_param
    if (i_sync_rst) begin
        r_wav_param <= '{default:'0};
    end else begin
        if (g_acceptable_start_req) begin
            r_wav_param.init_val <= i_init_val;
            r_wav_param.inc_val <= i_inc_val;
            r_wav_param.tread_len <= i_tread_len;
            r_wav_param.num_treads <= i_num_treads;
        end
    end
end

//! Update `r_sent_chunk_cnt`.
always_ff @(posedge i_clk) begin: update_sent_chunk_cnt
    if (i_sync_rst) begin
        r_sent_chunk_cnt <= '0;
    end else if (g_acceptable_start_req) begin
        r_sent_chunk_cnt <= '0;
    end else if (g_can_goto_next_chunk) begin
        r_sent_chunk_cnt <= g_last_chunk_flg ? '0 : `PLUS_ONE(r_sent_chunk_cnt);
    end
end

//! Update `r_sent_treads_cnt`.
always_ff @(posedge i_clk) begin: update_sent_treads_cnt
    if (i_sync_rst) begin
        r_sent_treads_cnt <= '0;
    end else if (g_acceptable_start_req) begin
        r_sent_treads_cnt <= '0;
    end else if (g_can_goto_next_chunk) begin
        if (g_last_chunk_flg) begin
            r_sent_treads_cnt <= '0;
        end else begin
            r_sent_treads_cnt <= g_next_sent_treads_cnt;
        end
    end
end

//! Update `r_intra_tread_chunk_head_pos`.
always_ff @(posedge i_clk) begin: update_intra_tread_chunk_head_pos
    if (i_sync_rst) begin
        r_intra_tread_chunk_head_pos <= '0;
    end else if (g_acceptable_start_req) begin
        r_intra_tread_chunk_head_pos <= '0;
    end else if (g_can_goto_next_chunk) begin
        if (g_last_chunk_flg) begin
            r_intra_tread_chunk_head_pos <= '0;
        end else begin
            r_intra_tread_chunk_head_pos <= g_next_intra_tread_chunk_head_pos;
        end
    end
end

//! Update `r_chunk_head_val`.
always_ff @(posedge i_clk) begin: update_chunk_head_val
    if (i_sync_rst) begin
        r_chunk_head_val <= '0;
    end else if (g_acceptable_start_req) begin
        r_chunk_head_val <= i_init_val;
    end else if (g_can_goto_next_chunk) begin
        if (g_last_chunk_flg) begin
            r_chunk_head_val <= '0;
        end else begin
            r_chunk_head_val <= g_next_chunk_head_val;
        end
    end
end

//! Control `g_next_sent_treads_cnt`, `g_next_intra_tread_chunk_head_pos`, `g_next_chunk_head_val`, `g_chunk`.
always_comb begin: cont_chunk__next_idx__val
    // Avoid creating unintended latches.
    g_next_sent_treads_cnt = r_sent_treads_cnt;
    g_next_intra_tread_chunk_head_pos = r_intra_tread_chunk_head_pos;
    g_next_chunk_head_val = r_chunk_head_val;
    g_chunk = '0;

    if (r_wav_param.tread_len == BW_SEQ_CONT'(1)) begin
        g_next_sent_treads_cnt = `INCR(r_sent_treads_cnt, P);
        g_next_intra_tread_chunk_head_pos = '0;
        g_next_chunk_head_val = r_chunk_head_val + BW_VAL'(P)*r_wav_param.inc_val;
        for (int i=0; i<P; ++i) begin
            g_chunk[i] = r_chunk_head_val + BW_VAL'(i) * r_wav_param.inc_val;
        end
    end else if (r_wav_param.tread_len == BW_SEQ_CONT'(2)) begin
        g_next_sent_treads_cnt = `INCR(r_sent_treads_cnt, P/2);
        g_next_intra_tread_chunk_head_pos = '0;
        g_next_chunk_head_val = r_chunk_head_val + BW_VAL'(P/2)*r_wav_param.inc_val;
        g_chunk = {
            {(P/2){r_chunk_head_val + r_wav_param.inc_val}},
            {(P/2){r_chunk_head_val}}
        };
    end else if (r_wav_param.tread_len == BW_SEQ_CONT'(3)) begin
        case (r_intra_tread_chunk_head_pos)
            BW_SEQ_CONT'(0): begin
                g_next_sent_treads_cnt = `INCR(r_sent_treads_cnt, 1);
                g_next_intra_tread_chunk_head_pos = BW_SEQ_CONT'(1);
                g_next_chunk_head_val = r_chunk_head_val + r_wav_param.inc_val;
                g_chunk = {r_chunk_head_val + r_wav_param.inc_val, {3{r_chunk_head_val}}};
            end
            BW_SEQ_CONT'(1): begin
                g_next_sent_treads_cnt = `INCR(r_sent_treads_cnt, 1);
                g_next_intra_tread_chunk_head_pos = BW_SEQ_CONT'(2);
                g_next_chunk_head_val = r_chunk_head_val + r_wav_param.inc_val;
                g_chunk = {{2{r_chunk_head_val + r_wav_param.inc_val}}, {2{r_chunk_head_val}}};
            end
            default: begin // 2
                g_next_sent_treads_cnt = `INCR(r_sent_treads_cnt, 2);
                g_next_intra_tread_chunk_head_pos = '0;
                g_next_chunk_head_val = r_chunk_head_val + BW_SEQ_CONT'(2)*r_wav_param.inc_val;
                g_chunk = {{3{r_chunk_head_val + r_wav_param.inc_val}}, r_chunk_head_val};
            end
        endcase
    end else if (r_wav_param.tread_len == BW_SEQ_CONT'(4)) begin
        g_next_sent_treads_cnt = `INCR(r_sent_treads_cnt, 1);
        g_next_intra_tread_chunk_head_pos = '0;
        g_next_chunk_head_val = r_chunk_head_val + r_wav_param.inc_val;
        g_chunk = {P{r_chunk_head_val}};
    end else begin // r_wav_param.tread_len > 4
        if (r_intra_tread_chunk_head_pos + BW_SEQ_CONT'(P) < r_wav_param.tread_len) begin
            g_next_sent_treads_cnt = r_sent_treads_cnt;
            g_next_intra_tread_chunk_head_pos = `INCR(r_intra_tread_chunk_head_pos, P);
            g_next_chunk_head_val = r_chunk_head_val;
        end else begin
            g_next_sent_treads_cnt = `INCR(r_sent_treads_cnt, 1);
            if (r_intra_tread_chunk_head_pos + BW_SEQ_CONT'(P) == r_wav_param.tread_len) begin
                g_next_intra_tread_chunk_head_pos = '0;
            end else begin
                g_next_intra_tread_chunk_head_pos = r_intra_tread_chunk_head_pos + BW_SEQ_CONT'(P) - r_wav_param.tread_len;
            end
            g_next_chunk_head_val = r_chunk_head_val + r_wav_param.inc_val;
        end

        for (int i=0; i<P; ++i) begin
            if (r_intra_tread_chunk_head_pos + BW_SEQ_CONT'(i) + BW_SEQ_CONT'(1) <= r_wav_param.tread_len) begin
                g_chunk[i] = r_chunk_head_val;
            end else begin
                g_chunk[i] = r_chunk_head_val + r_wav_param.inc_val;
            end
        end
    end
end

endmodule

`default_nettype wire
