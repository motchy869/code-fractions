`default_nettype none

`timescale  1ns / 10ps

// timeunit 1ns;
// timeprecision 10ps;

localparam int CLKNUM = 10;

module main_tb;

reg CLK;
wire [BIT_WIDTH_REG_1-1:0] OUT_REG_1_A;
wire [BIT_WIDTH_REG_1-1:0] OUT_REG_1_B;
wire [BIT_WIDTH_REG_1-1:0] OUT_REG_1_C;
wire [BIT_WIDTH_REG_1-1:0] OUT_REG_1_D;
wire [BIT_WIDTH_REG_1-1:0] OUT_REG_2_A;
wire [BIT_WIDTH_REG_1-1:0] OUT_REG_2_B;
wire [BIT_WIDTH_REG_1-1:0] OUT_REG_2_C;
wire [BIT_WIDTH_REG_1-1:0] OUT_REG_2_D;
wire [BIT_WIDTH_REG_1-1:0] OUT_REG_2_E;
wire [BIT_WIDTH_REG_1-1:0] OUT_REG_2_F;

/* Generate clock. */
localparam integer STEP = 10;

always begin
    CLK = 0; #(STEP/2);
    CLK = 1; #(STEP/2);
end

main main_inst(
    .CLK(CLK),
    .OUT_REG_1_A(OUT_REG_1_A),
    .OUT_REG_1_B(OUT_REG_1_B),
    .OUT_REG_1_C(OUT_REG_1_C),
    .OUT_REG_1_D(OUT_REG_1_D),
    .OUT_REG_2_A(OUT_REG_2_A),
    .OUT_REG_2_B(OUT_REG_2_B),
    .OUT_REG_2_C(OUT_REG_2_C),
    .OUT_REG_2_D(OUT_REG_2_D),
    .OUT_REG_2_E(OUT_REG_2_E),
    .OUT_REG_2_F(OUT_REG_2_F)
);

initial begin
    #(STEP*CLKNUM);
    $stop;
end

endmodule
