// Verible directive
// verilog_lint: waive-start parameter-name-style
// verilog_lint: waive-start line-length

`default_nettype none

//! AXI4-Lite read-transaction CDC.
//! No outstanding transactions are supported.
//! ## changelog
//! ### [0.1.0] - 2024-12-xx
//! - initial release
module a4l_rd_cdc_v0_1_0 #(
    parameter int AXI4_LITE_ADDR_BIT_WIDTH = 32, //! bit width of AXI4-Lite address bus
    parameter int AXI4_LITE_DATA_BIT_WIDTH = 32 //! bit width of AXI4-Lite data bus
)(
    //! @virtualbus s_axi_if @dir in AXI4 subordinate interface, through which the manager-side frontend (MS-FE) receives read request form the manager.
    input wire logic s0_aclk, //! MS-FE clock
    input wire logic s0_sync_rst, //! synchronous reset signal
    input wire logic [AXI4_LITE_ADDR_BIT_WIDTH-1:0] s0_araddr, //! read address
    input wire logic [2:0] s0_arprot, //! protection type
    input wire logic s0_arvalid, //! read address valid
    output wire logic s0_arready, //! read address ready
    output wire logic [AXI4_LITE_DATA_BIT_WIDTH-1:0] s0_rdata, //! read data
    output wire logic [1:0] s0_rresp, //! read response
    output wire logic s0_rvalid, //! read data valid
    input wire logic s0_rready, //! read data ready
    //! @end
    //! @virtualbus m_axi_if @dir out AXI4 manager interface, through which the subordinate-side frontend (SS-FE) sends read request to the subordinate.
    input wire logic m0_aclk, //! SS-FE clock
    input wire logic m0_sync_rst, //! synchronous reset signal
    output wire logic [AXI4_LITE_ADDR_BIT_WIDTH-1:0] m0_araddr, //! read address
    output wire logic [2:0] m0_arprot, //! protection type
    output wire logic m0_arvalid, //! read address valid
    input wire logic m0_arready, //! read address ready
    input wire logic [AXI4_LITE_DATA_BIT_WIDTH-1:0] m0_rdata, //! read data
    input wire logic [1:0] m0_rresp, //! read response
    input wire logic m0_rvalid, //! read data valid
    output wire logic m0_rready //! read data ready
    //! @end
);
// ---------- parameters ----------
// --------------------

// ---------- parameter validation ----------
// --------------------

// ---------- functions ----------
//! Custom fatal function. If UVM is available, it uses `uvm_fatal`, otherwise it uses `$fatal`.
function automatic void custom_fatal(input string msg, input int unsigned line_no);
    string ln_msg = $sformatf("[@line %0d] %s", line_no, msg);

    `ifdef uvm_fatal
        `uvm_fatal("INFO", ln_msg, UVM_MEDIUM);
    `else
        $fatal(2, ln_msg);
    `endif
endfunction
// --------------------

// ---------- signals and storage ----------
var logic r_ms_fe_rst_done; //! Indicates that MS-FE reset is done. Only for simulation. Fitting tools will optimize this out.
var logic r_ss_fe_rst_done; //! Indicates that SS-FE reset is done. Only for simulation. Fitting tools will optimize this out.

//! depth-0 state type
typedef enum logic [1:0] {
    D0_IDLE,
    D0_WAITING_RESP,
    D0_RESPONDING
} d0_state_t;

//! depth-1 state type
typedef enum logic {
    D1_SENDING_ARADDR,
    D1_WAITING_RVALID
} d1_state_t;

var d0_state_t r_ms_fe_stat; //! MS-FE state
var d0_state_t r_ss_fe_d0_stat; //! SS-FE depth-0 state
var d1_state_t r_ss_fe_d1_stat; //! SS-FE depth-1 state
var d0_state_t g_next_ms_fe_stat; //! MS-FE state right after the next clock rising edge
var d0_state_t g_next_ss_fe_d0_stat; //! SS-FE depth-0 state right after the next clock rising edge
var d1_state_t g_next_ss_fe_d1_stat; //! SS-FE depth-1 state right after the next clock rising edge

//! latched request
typedef struct packed {
    logic [AXI4_LITE_ADDR_BIT_WIDTH-1:0] araddr;
    logic [2:0] arprot;
} req_lat_t;

var req_lat_t r_ms_fe__latched_req; //! Latched request in MS-FE. clock domain = MS-FE
var req_lat_t [1:0] r_ss_fe__req_cdc_ff; //! Synchronization FFs for latched request from MS-FE to SS-FE. clock domain = SS-FE
wire g_ms_fe__req_lat_en; //! Pulse indicating that MS-FE received a request from the manager. Clock domain = MS-FE
assign g_ms_fe__req_lat_en = r_ms_fe_stat == D0_IDLE && s0_arvalid;
wire w_ss_fe__req_pls_from_ms_fe; //! Pulse indicating that MS-FE has received a request from the manager, and the content of ```r_ss_fe__req_cdc_ff[1]``` is ready to use. Clock domain = SS-FE

//! latched response
typedef struct packed {
    logic [AXI4_LITE_DATA_BIT_WIDTH-1:0] rdata;
    logic [1:0] rresp;
} resp_lat_t;

var resp_lat_t r_ss_fe__latched_resp; //! Latched response in SS-FE. clock domain = SS-FE
var resp_lat_t [1:0] r_ms_fe__resp_cdc_ff; //! Synchronization FFs for latched response from SS-FE to MS-FE. clock domain = MS-FE
wire g_ss_fe__resp_lat_en; //! Pulse indicating that SS-FE received a response from the subordinate. Clock domain = SS-FE
assign g_ss_fe__resp_lat_en = r_ss_fe_d0_stat == D0_WAITING_RESP && g_next_ss_fe_d0_stat == D0_IDLE;
wire w_ms_fe__resp_pls_from_ss_fe; //! Pulse indicating that SS-FE has received a response from the subordinate, and the content of ```r_ms_fe__resp_cdc_ff[1]``` is ready to use. Clock domain = MS-FE

//! AXI4-Lite subordinate output signal type
typedef struct packed {
    logic arready;
    logic [AXI4_LITE_DATA_BIT_WIDTH-1:0] rdata;
    logic [1:0] rresp;
    logic rvalid;
} a4l_s_out_sig_t;

//! AXI4-Lite manager output signal type
typedef struct packed {
    logic [AXI4_LITE_ADDR_BIT_WIDTH-1:0] araddr;
    logic [2:0] arprot;
    logic arvalid;
    logic rready;
} a4l_m_out_sig_t;

var a4l_s_out_sig_t r_s0_out_sig; //! MS-FE buffered output signals
var a4l_m_out_sig_t r_m0_out_sig; //! SS-FE buffered output signals
// --------------------

// ---------- instances ----------
//! pulse CDC for request from MS-FE to SS-FE
pulse_cdc_v0_1_0 #(
    .US_ADD_DELAY(0),
    .DS_ADD_DELAY(0)
) req_pls_cdc (
    .i_us_clk(s0_aclk),
    .i_us_sync_rst(s0_sync_rst),
    .i_us_pulse(g_ms_fe__req_lat_en),
    .i_ds_clk(m0_aclk),
    .i_ds_sync_rst(m0_sync_rst),
    .o_ds_pulse(w_ss_fe__req_pls_from_ms_fe)
);

//! pulse CDC for response from SS-FE to MS-FE
pulse_cdc_v0_1_0 #(
    .US_ADD_DELAY(0),
    .DS_ADD_DELAY(0)
) resp_pls_cdc (
    .i_us_clk(m0_aclk),
    .i_us_sync_rst(m0_sync_rst),
    .i_us_pulse(g_ss_fe__resp_lat_en),
    .i_ds_clk(s0_aclk),
    .i_ds_sync_rst(s0_sync_rst),
    .o_ds_pulse(w_ms_fe__resp_pls_from_ss_fe)
);
// --------------------

// ---------- Drives output signals. ----------
assign s0_arready = r_s0_out_sig.arready;
assign s0_rdata = r_s0_out_sig.rdata;
assign s0_rresp = r_s0_out_sig.rresp;
assign s0_rvalid = r_s0_out_sig.rvalid;

assign m0_araddr = r_m0_out_sig.araddr;
assign m0_arprot = r_m0_out_sig.arprot;
assign m0_arvalid = r_m0_out_sig.arvalid;
assign m0_rready = r_m0_out_sig.rready;
// --------------------

// ---------- blocks ----------
//! Updates MS-FE reset done flag.
always_ff @(posedge s0_aclk) begin: blk_update_ms_fe_rst_done_flag
    if (s0_sync_rst) begin
        r_ms_fe_rst_done <= 1'b0;
    end else begin
        r_ms_fe_rst_done <= 1'b1;
    end
end

//! Updates SS-FE reset done flag.
always_ff @(posedge m0_aclk) begin: blk_update_ss_fe_rst_done_flag
    if (m0_sync_rst) begin
        r_ss_fe_rst_done <= 1'b0;
    end else begin
        r_ss_fe_rst_done <= 1'b1;
    end
end

//! Determines next MS-FE state.
always_comb begin: blk_det_next_ms_fe_state
    case (r_ms_fe_stat)
        D0_IDLE: begin
            if (s0_arvalid) begin
                g_next_ms_fe_stat = D0_WAITING_RESP;
            end else begin
                g_next_ms_fe_stat = D0_IDLE;
            end
        end
        D0_WAITING_RESP: begin
            if (w_ms_fe__resp_pls_from_ss_fe) begin
                g_next_ms_fe_stat = D0_RESPONDING;
            end else begin
                g_next_ms_fe_stat = D0_WAITING_RESP;
            end
        end
        D0_RESPONDING: begin
            if (s0_rready) begin
                g_next_ms_fe_stat = D0_IDLE;
            end else begin
                g_next_ms_fe_stat = D0_RESPONDING;
            end
        end
        default: begin
            if (r_ms_fe_rst_done) begin
                custom_fatal($sformatf("bug. r_ms_fe_stat=%0p", r_ms_fe_stat), `__LINE__);
            end
            g_next_ms_fe_stat = D0_IDLE;
        end
    endcase
end

//! Determines next SS-FE depth-0 state.
always_comb begin: blk_det_next_ss_fe_d0_state
    case (r_ss_fe_d0_stat)
        D0_IDLE: begin
            if (w_ss_fe__req_pls_from_ms_fe) begin
                g_next_ss_fe_d0_stat = D0_WAITING_RESP;
            end else begin
                g_next_ss_fe_d0_stat = D0_IDLE;
            end
        end
        D0_WAITING_RESP: begin
            unique case (r_ss_fe_d1_stat)
                D1_SENDING_ARADDR: begin
                    if (m0_arready && m0_rvalid) begin
                        g_next_ss_fe_d0_stat = D0_IDLE;
                    end else begin
                        g_next_ss_fe_d0_stat = D0_WAITING_RESP;
                    end
                end
                D1_WAITING_RVALID: begin
                    if (m0_rvalid) begin
                        g_next_ss_fe_d0_stat = D0_IDLE;
                    end else begin
                        g_next_ss_fe_d0_stat = D0_WAITING_RESP;
                    end
                end
            endcase
        end
        default: begin
            if (r_ss_fe_rst_done) begin
                custom_fatal($sformatf("bug. r_ss_fe_d0_stat=%0p", r_ss_fe_d0_stat), `__LINE__);
            end
            g_next_ss_fe_d0_stat = D0_IDLE;
        end
    endcase
end

//! Determines next SS-FE depth-1 state.
always_comb begin: blk_det_next_ss_fe_d1_state
    case (r_ss_fe_d0_stat)
        D0_IDLE: begin
            g_next_ss_fe_d1_stat = D1_SENDING_ARADDR;
        end
        D0_WAITING_RESP: begin
            unique case (r_ss_fe_d1_stat)
                D1_SENDING_ARADDR: begin
                    if (m0_arready && !m0_rvalid) begin
                        g_next_ss_fe_d1_stat = D1_WAITING_RVALID;
                    end else begin
                        g_next_ss_fe_d1_stat = D1_SENDING_ARADDR;
                    end
                end
                D1_WAITING_RVALID: begin
                    g_next_ss_fe_d1_stat = D1_WAITING_RVALID;
                end
            endcase
        end
        default: begin
            if (r_ss_fe_rst_done) begin
                custom_fatal($sformatf("bug. r_ss_fe_d0_stat=%0p", r_ss_fe_d0_stat), `__LINE__);
            end
            g_next_ss_fe_d1_stat = D1_SENDING_ARADDR;
        end
    endcase
end

//! Updates MS-FE state.
always_ff @(posedge s0_aclk) begin: blk_update_ms_fe_state
    if (s0_sync_rst) begin
        r_ms_fe_stat <= D0_IDLE;
    end else begin
        r_ms_fe_stat <= g_next_ms_fe_stat;
    end
end

//! Updates SS-FE state.
always_ff @(posedge m0_aclk) begin: blk_update_ss_fe_state
    if (m0_sync_rst) begin
        r_ss_fe_d0_stat <= D0_IDLE;
        r_ss_fe_d1_stat <= D1_SENDING_ARADDR;
    end else begin
        r_ss_fe_d0_stat <= g_next_ss_fe_d0_stat;
        r_ss_fe_d1_stat <= g_next_ss_fe_d1_stat;
    end
end

//! Updates latched request in MS-FE.
always_ff @(posedge s0_aclk) begin: blk_update_lat_req
    if (s0_sync_rst) begin
        r_ms_fe__latched_req <= '{default: '0};
    end if (g_ms_fe__req_lat_en) begin
        r_ms_fe__latched_req.araddr <= s0_araddr;
        r_ms_fe__latched_req.arprot <= s0_arprot;
    end
end

//! Updates latched response in SS-FE.
always_ff @(posedge m0_aclk) begin: blk_update_lat_resp
    if (m0_sync_rst) begin
        r_ss_fe__latched_resp <= '{default: '0};
    end if (g_ss_fe__resp_lat_en) begin
        r_ss_fe__latched_resp.rdata <= m0_rdata;
        r_ss_fe__latched_resp.rresp <= m0_rresp;
    end
end

//! Updates synchronization FFs for latched request from MS-FE to SS-FE.
always_ff @(posedge m0_aclk) begin: blk_update_req_cdc_ff
    if (m0_sync_rst) begin
        r_ss_fe__req_cdc_ff <= '{default: '0};
    end else begin
        r_ss_fe__req_cdc_ff <= {r_ss_fe__req_cdc_ff[0], r_ms_fe__latched_req};
    end
end

//! Updates synchronization FFs for latched response from SS-FE to MS-FE.
always_ff @(posedge s0_aclk) begin: blk_update_resp_cdc_ff
    if (s0_sync_rst) begin
        r_ms_fe__resp_cdc_ff <= '{default: '0};
    end else begin
        r_ms_fe__resp_cdc_ff <= {r_ms_fe__resp_cdc_ff[0], r_ss_fe__latched_resp};
    end
end

//! Updates MS-FE buffered output signals.
always_ff @(posedge s0_aclk) begin: blk_update_ms_fe_buf_out_sig
    if (s0_sync_rst) begin
        r_s0_out_sig <= '{default: '0};
    end else begin
        case (g_next_ms_fe_stat)
            D0_IDLE: begin
                r_s0_out_sig.arready <= 1'b1;
                r_s0_out_sig.rdata <= '0;
                r_s0_out_sig.rresp <= '0;
                r_s0_out_sig.rvalid <= 1'b0;
            end
            D0_WAITING_RESP: begin
                r_s0_out_sig.arready <= 1'b0;
                r_s0_out_sig.rdata <= '0;
                r_s0_out_sig.rresp <= '0;
                r_s0_out_sig.rvalid <= 1'b0;
            end
            D0_RESPONDING: begin
                r_s0_out_sig.arready <= 1'b0;
                r_s0_out_sig.rdata <= r_ms_fe__resp_cdc_ff[1].rdata;
                r_s0_out_sig.rresp <= r_ms_fe__resp_cdc_ff[1].rresp;
                r_s0_out_sig.rvalid <= 1'b1;
            end
            default: begin
                if (r_ms_fe_rst_done) begin
                    custom_fatal($sformatf("bug. g_next_ms_fe_stat=%0p", g_next_ms_fe_stat), `__LINE__);
                end
            end
        endcase
    end
end

//! Updates SS-FE buffered output signals.
always_ff @(posedge m0_aclk) begin: blk_update_ss_fe_buf_out_sig
    if (m0_sync_rst) begin
        r_m0_out_sig <= '{default: '0};
    end else begin
        case (g_next_ss_fe_d0_stat)
            D0_IDLE: begin
                r_m0_out_sig <= '{default: '0};
            end
            D0_WAITING_RESP: begin
                unique case (r_ss_fe_d1_stat)
                    D1_SENDING_ARADDR: begin
                        r_m0_out_sig.araddr <= r_ss_fe__req_cdc_ff[1].araddr;
                        r_m0_out_sig.arprot <= r_ss_fe__req_cdc_ff[1].arprot;
                        r_m0_out_sig.arvalid <= 1'b1;
                        r_m0_out_sig.rready <= 1'b1;
                    end
                    D1_WAITING_RVALID: begin
                        r_m0_out_sig.araddr <= '0;
                        r_m0_out_sig.arprot <= '0;
                        r_m0_out_sig.arvalid <= 1'b0;
                        r_m0_out_sig.rready <= 1'b1;
                    end
                endcase
            end
            default: begin
                if (r_ss_fe_rst_done) begin
                    custom_fatal($sformatf("bug. g_next_ss_fe_d0_stat=%0p", g_next_ss_fe_d0_stat), `__LINE__);
                end
            end
        endcase
    end
end
// --------------------
endmodule

`default_nettype wire
