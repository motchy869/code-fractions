`default_nettype none

import main_pkg::*;

module main(
    input wire CLK,
    input wire RST,
    output reg [BIT_WIDTH_REG_1-1:0] OUT_REG_1_A,
    output reg [BIT_WIDTH_REG_1-1:0] OUT_REG_1_B,
    output reg [BIT_WIDTH_REG_1-1:0] OUT_REG_1_C,
    output reg [BIT_WIDTH_REG_1-1:0] OUT_REG_1_D,
    output reg [BIT_WIDTH_REG_1-1:0] OUT_REG_2_A,
    output reg [BIT_WIDTH_REG_1-1:0] OUT_REG_2_B,
    output reg [BIT_WIDTH_REG_1-1:0] OUT_REG_2_C,
    output reg [BIT_WIDTH_REG_1-1:0] OUT_REG_2_D,
    output reg [BIT_WIDTH_REG_1-1:0] OUT_REG_2_E,
    output reg [BIT_WIDTH_REG_1-1:0] OUT_REG_2_F
);

/* reg_1[3] = 3'd3,
 * reg_1[2] = 3'd2,
 * reg_1[1] = 3'd1,
 * reg_1[0] = 3'd0,
 */
reg [3:0][2:0] reg_1 = {BIT_WIDTH_REG_1'(3), BIT_WIDTH_REG_1'(2), BIT_WIDTH_REG_1'(1), BIT_WIDTH_REG_1'(0)};

/* reg_2[2][1] = 8'd5
 * reg_2[2][0] = 8'd4
 * reg_2[1][1] = 8'd3
 * reg_2[1][0] = 8'd2
 * reg_2[0][1] = 8'd1
 * reg_2[0][0] = 8'd0
 */
reg [2:0][1:0][BIT_WIDTH_REG_2-1:0] reg_2 = {
    {BIT_WIDTH_REG_2'(5), BIT_WIDTH_REG_2'(4)},
    {BIT_WIDTH_REG_2'(3), BIT_WIDTH_REG_2'(2)},
    {BIT_WIDTH_REG_2'(1), BIT_WIDTH_REG_2'(0)}
};

always @(posedge CLK) begin
    if (RST) begin
        OUT_REG_1_A <= '0;
        OUT_REG_1_B <= '0;
        OUT_REG_1_C <= '0;
        OUT_REG_1_D <= '0;
        OUT_REG_2_A <= '0;
        OUT_REG_2_B <= '0;
        OUT_REG_2_C <= '0;
        OUT_REG_2_D <= '0;
        OUT_REG_2_E <= '0;
        OUT_REG_2_F <= '0;
    end else begin
        OUT_REG_1_A <= reg_1[0];
        OUT_REG_1_B <= reg_1[1];
        OUT_REG_1_C <= reg_1[2];
        OUT_REG_1_D <= reg_1[3];
        OUT_REG_2_A <= reg_2[0][0];
        OUT_REG_2_B <= reg_2[0][1];
        OUT_REG_2_C <= reg_2[1][0];
        OUT_REG_2_D <= reg_2[1][1];
        OUT_REG_2_E <= reg_2[2][0];
        OUT_REG_2_F <= reg_2[2][1];
    end
end

endmodule
