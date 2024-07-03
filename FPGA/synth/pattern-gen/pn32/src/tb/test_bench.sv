// Verible directive
// verilog_lint: waive-start parameter-name-style
// verilog_lint: waive-start line-length

`include "../pn32.svh"

`default_nettype none

// timescale is defined in Makefile.

module test_bench;

// ---------- parameters ----------
localparam int unsigned CLK_PERIOD_NS = 8; //! clock period in ns
localparam int unsigned RESET_DURATION = CLK_PERIOD_NS; //! reset duration in ns
localparam int unsigned TIME__RST_RISE = 3*CLK_PERIOD_NS; //! the time when the reset signal rises
localparam int unsigned TIME__RST_FALL = TIME__RST_RISE + RESET_DURATION; //! the time when the reset signal falls
localparam int unsigned TIME__END_SIM = TIME__RST_FALL + 1024*CLK_PERIOD_NS; //! the time when the simulation ends

localparam int L = 32; //! the length of the shift register (**fixed**, cannot be changed)
// --------------------

// ---------- signal and storage ----------
var bit r_clk; //! clock signal
var bit r_sync_rst; //! clock synchronous reset signal

var logic [$clog2(TIME__END_SIM+1)-1:0] r_clk_count = '0;
wire g_reset_done;

var logic r_set_shift_reg = 1'b0;
var logic [L-1:0] r_shift_reg_in = '0;
wire w_bit_out;
// --------------------

/* Connect the DUT. */
pn32 pn32_inst (
    .i_clk(r_clk),
    .i_sync_rst(r_sync_rst),
    .i_set_shift_reg(r_set_shift_reg),
    .i_shift_reg_in(r_shift_reg_in),
    .o_bit_out(w_bit_out)
);

/* Drive clock. */
initial begin
    #CLK_PERIOD_NS; // Place the 1st rising edge at CLK_PERIOD_NS.
    while (1'b1) begin
        r_clk = 1'b1; #(CLK_PERIOD_NS/2);
        r_clk = 1'b0; #(CLK_PERIOD_NS/2);
    end
end

/* Update the clock count. */
always_ff @(posedge r_clk) begin
    r_clk_count <= r_clk_count + 1'b1;
end

/* Drive reset. */
assign r_sync_rst = TIME__RST_RISE <= r_clk_count*CLK_PERIOD_NS && r_clk_count*CLK_PERIOD_NS < TIME__RST_FALL;
assign g_reset_done = TIME__RST_FALL <= r_clk_count*CLK_PERIOD_NS;

/* Stop simulation. */
initial begin
    #TIME__END_SIM;
    $stop;
end

/* ---------- Drive the DUT. ---------- */
task automatic drive_dut();
    r_set_shift_reg = 1'b1;
    r_shift_reg_in = 'h12345678;

    #CLK_PERIOD_NS;
    r_set_shift_reg = 1'b0;
endtask

initial begin
    wait(g_reset_done);
    #(0.99*CLK_PERIOD_NS); // Ensure the DUT input setup time.
    drive_dut();
end
/* -------------------- */

endmodule

`default_nettype uwire
