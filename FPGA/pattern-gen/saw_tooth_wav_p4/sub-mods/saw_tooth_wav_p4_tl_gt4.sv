`default_nettype none

localparam int PARA = 4; // processing parallelism

//! Sub module of saw_tooth_wav_p4.
//! This module is specialized for tread length greater than 4.
module saw_tooth_wav_p4_tl_gt4
 #(
    parameter int BW_VAL = 16, //! bit-width of output numeric value
    parameter int BW_SEQ_CONT = 16 //! bit-width of sequence control data: tread length and the number of steps
)(
    //! common ports
    input wire logic i_clk, //! input clock
    input wire logic i_sync_rst, //! input reset synchronous to the input clock

    //! @virtualbus us_side_if @dir in upstream side interface
    input wire logic ip_start, //! Start request pulse for waveform generation. The request is accepted only when `o_busy` is low. The pulse length must be 1 clock-cycle.
    input wire logic [BW_VAL-1:0] i_init_val, //! initial term value
    input wire logic [BW_SEQ_CONT-1:0] i_tread_len, //! Tread length. **Value less than 5 causes undefined behavior.**
    input wire logic [BW_SEQ_CONT-1:0] i_num_steps, //! The number of steps. **Value less than 1 causes undefined behavior.**
    output wire logic o_busy, //! busy flag which indicates that waveform generation is in progress
    //! @end

    //! @virtualbus ds_side_if @dir out downstream side interface
    //! input ready signal which indicates that the downstream is ready to accept the output chunk
    input wire logic i_ds_ready,
    output wire logic o_chunk_valid, //! output valid signal which indicates that the output chunk is valid
    output wire logic [$clog2(PARA+1)-1:0] o_chunk_elem_cnt, //! the number of the valid elements in the chunk
    output wire logic [PARA-1:0] o_chunk //! output chunk
    //! @end
);

// ---------- working signals and storage ----------
wire logic g_start_en; //! enable signal to start waveform generation
assign g_start_en = !o_busy && ip_start;
var logic r_busy; //! busy signal which indicates that waveform generation is in progress
// --------------------

// Drive output signals.
assign o_busy = !i_sync_rst && r_busy;

//! Update the busy signal.
always_ff @(posedge i_clk) begin: update_busy_signal
    if (i_sync_rst) begin
        r_busy <= 1'b0;
    end else if (g_start_en) begin
        r_busy <= 1'b1;
    end
    // TODO: Deassert r_busy at waveform generation completion.
end

endmodule

`default_nettype wire
