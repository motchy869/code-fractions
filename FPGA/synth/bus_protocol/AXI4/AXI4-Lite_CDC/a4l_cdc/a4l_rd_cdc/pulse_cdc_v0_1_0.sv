// Verible directive
// verilog_lint: waive-start parameter-name-style
// verilog_lint: waive-start line-length

`default_nettype none

//! Pulse CDC (Clock Domain Crossing).
//! Additional delays can be set by ```US_ADD_DELAY``` and ```DS_ADD_DELAY``` parameters.
//! - pulse length: 1 clock cycle
//! - input-to-output delay: min. = (1+```US_ADD_DELAY```)T_us + (3+```DS_ADD_DELAY```)T_ds, max. (1+```US_ADD_DELAY```)T_us + (4+```DS_ADD_DELAY```)T_ds (T_us and T_ds are clock periods of upstream and downstream side, respectively.)
//! - input dead time: Must be (6+```US_ADD_DELAY```)T_us + (3+```DS_ADD_DELAY```)T_ds or greater. Consecutive pulses whose time gap is less than this value can be ignored.
//! ## changelog
//! ### [0.1.0] - 2024-12-15
//! - initial release
module pulse_cdc_v0_1_0 #(
    parameter int unsigned US_ADD_DELAY = 0, //! additional delay cycle in upstream side
    parameter int unsigned DS_ADD_DELAY = 0 //! additional delay cycle in downstream side
)(
    //! @virtualbus us_side_if @dir in upstream side interface
    input wire logic i_us_clk, //! upstream side clock
    input wire logic i_us_sync_rst, //! synchronous reset signal for upstream side
    input wire logic i_us_pulse, //! pulse from upstream side
    //! @end
    //! @virtualbus ds_side_if @dir out downstream side interface
    input wire logic i_ds_clk, //! downstream side clock
    input wire logic i_ds_sync_rst, //! synchronous reset signal for downstream side
    output wire logic o_ds_pulse //! pulse to downstream side
    //! @end
);
// ---------- parameters ----------
// --------------------

// ---------- parameter validation ----------
// --------------------

// ---------- functions ----------
// --------------------

// ---------- signals and storage ----------
var logic [US_ADD_DELAY:0] r_us_cd__latched_pulse; //! Latched pulse from upstream side. [0] is for latch, [US_ADD_DELAY:1] is for additional delay. clock domain = us-side
var logic [2:0] r_ds_cd__lp_sync_ff; //! Latched pulse CDC FFs. [1:0] is for CDC, [2:1] is for rising-edge detection. clock domain = ds-side
wire g_ds_cd__pos_edge_det; //! Rising-edge detection for latched pulse. clock domain = ds-side
assign g_ds_cd__pos_edge_det = ~r_ds_cd__lp_sync_ff[2] & r_ds_cd__lp_sync_ff[1];
var logic [DS_ADD_DELAY:0] r_ds_cd__pulse; //! buffered pulse to downstream side. clock domain = ds-side
var logic [1:0] r_us_cd__lp_fb_sync_ff; //! Latched pulse feedback CDC FFs, used for clear latch in us-side. clock domain = us-side
wire g_us_cd__clr_latch; //! latch clear timing in us-side. clock domain = us-side
assign g_us_cd__clr_latch = r_us_cd__lp_fb_sync_ff[1];
// --------------------

// ---------- instances ----------
// --------------------

// ---------- Drives output signals. ----------
assign o_ds_pulse = r_ds_cd__pulse[$high(r_ds_cd__pulse)];
// --------------------

// ---------- blocks ----------
//! Latches/clears pulse in upstream side.
always_ff @(posedge i_us_clk) begin: blk_latch_clr_pulse_us
    if (i_us_sync_rst) begin
        r_us_cd__latched_pulse <= '0;
    end else begin
        if (g_us_cd__clr_latch) begin
            r_us_cd__latched_pulse[0] <= 1'b0; // clear
        end else if (i_us_pulse) begin
            r_us_cd__latched_pulse[0] <= 1'b1; // set
        end
        for (int unsigned i=1; i<=US_ADD_DELAY; ++i) begin
            r_us_cd__latched_pulse[i] <= r_us_cd__latched_pulse[i-1];
        end
    end
end

//! Updates latched pulse CDC FFs.
always_ff @(posedge i_ds_clk) begin: blk_forward_cdc
    if (i_ds_sync_rst) begin
        r_ds_cd__lp_sync_ff <= '0;
    end else begin
        r_ds_cd__lp_sync_ff <= {r_ds_cd__lp_sync_ff[1:0], r_us_cd__latched_pulse[$high(r_us_cd__latched_pulse)]};
    end
end

//! Generate pulse to downstream side.
always_ff @(posedge i_ds_clk) begin: blk_gen_pulse
    if (i_ds_sync_rst) begin
        r_ds_cd__pulse <= 1'b0;
    end else begin
        r_ds_cd__pulse[0] <= g_ds_cd__pos_edge_det;
        for (int unsigned i=1; i<=DS_ADD_DELAY; ++i) begin
            r_ds_cd__pulse[i] <= r_ds_cd__pulse[i-1];
        end
    end
end

//! Updates latched pulse feedback CDC FFs.
always_ff @(posedge i_us_clk) begin: blk_backward_cdc
    if (i_us_sync_rst) begin
        r_us_cd__lp_fb_sync_ff <= '0;
    end else begin
        r_us_cd__lp_fb_sync_ff <= {r_us_cd__lp_fb_sync_ff[0], r_ds_cd__lp_sync_ff[1]};
    end
end
// --------------------
endmodule

`default_nettype wire
