`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2019/12/13 14:40:36
// Design Name: 
// Module Name: logic_processor
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module logic_processor #(
    parameter SCREEN_WIDTH  = 1024,
    parameter SCREEN_HEIGHT = 768,
    parameter PIXEL_X_WIDTH = 10,
    parameter PIXEL_Y_WIDTH = 10,
    parameter BOARD_WIDTH   = 50,
    parameter BOARD_HEIGHT  = 38,
    parameter CORD_X_WIDTH  = 6,
    parameter CORD_Y_WIDTH  = 6,
    parameter CELL_SIZE     = 20,
    parameter LR_SPACE      = (SCREEN_WIDTH - CELL_SIZE * BOARD_WIDTH) / 2,
    parameter UD_SPACE      = (SCREEN_HEIGHT - CELL_SIZE * BOARD_HEIGHT) / 2
    ) (
    input wire CLK,
    input wire i_rst,
    input wire [2:0] i_spd,
    input wire i_m_done_tick,
    input wire [8:0] i_ptr_x_move,
    input wire [8:0] i_ptr_y_move,
    input wire [2:0] i_m_btnm,
    output wire o_pix_stb,
    output wire o_cal_stb,
    output wire o_clk_tick,
    output wire [PIXEL_X_WIDTH-1:0] o_ptr_x,
    output wire [PIXEL_Y_WIDTH-1:0] o_ptr_y,
    output wire [PIXEL_X_WIDTH-1:0] o_sel_x,
    output wire [PIXEL_Y_WIDTH-1:0] o_sel_y
    );

    reg [PIXEL_X_WIDTH-1:0] ptr_x_reg;      // 指针x坐标
    reg [PIXEL_X_WIDTH-1:0] ptr_x_next;
    reg [PIXEL_Y_WIDTH-1:0] ptr_y_reg;      // 指针y坐标
    reg [PIXEL_Y_WIDTH-1:0] ptr_y_next;
    reg is_clk;
    reg is_clk_next;

    // 生成65MHz时钟
    reg [15:0] clk_cnt_1;
    reg pix_stb;
    always @ (posedge CLK)
        {pix_stb, clk_cnt_1} <= clk_cnt_1 + 16'hA666;
    
    assign o_pix_stb = pix_stb;

    // 生成指定频率的时钟
    reg [31:0] clk_cnt_2;
    reg cal_stb;
    
    always @ (posedge CLK)
        begin
            case(i_spd)
                3'b000: {cal_stb, clk_cnt_2} <= clk_cnt_2 + 32'h00; // 0Hz
                3'b001: {cal_stb, clk_cnt_2} <= clk_cnt_2 + 32'h2A; // 1Hz
                3'b010: {cal_stb, clk_cnt_2} <= clk_cnt_2 + 32'h55; // 2Hz
                3'b011: {cal_stb, clk_cnt_2} <= clk_cnt_2 + 32'hAB; // 4Hz
                3'b100: {cal_stb, clk_cnt_2} <= clk_cnt_2 + 32'h157; // 8Hz
                3'b101: {cal_stb, clk_cnt_2} <= clk_cnt_2 + 32'h687; // 16Hz
                3'b110: {cal_stb, clk_cnt_2} <= clk_cnt_2 + 32'h1374; // 32Hz
                3'b111: {cal_stb, clk_cnt_2} <= clk_cnt_2 + 32'h2748; // 64Hz
            endcase
        end
    assign o_cal_stb = cal_stb;

    // 状态转移
    always @ (posedge CLK or posedge i_rst)
    begin
        if(i_rst)
        begin
            ptr_x_reg <= 0;
            ptr_y_reg <= 0;
            is_clk <= 0;
        end
        else if(i_m_done_tick)
        begin
            ptr_x_reg <= ptr_x_next;
            ptr_y_reg <= ptr_y_next;
            is_clk <= is_clk_next;
        end
    end

    always @ *
    begin
        is_clk_next = i_m_btnm[0];

        if($signed(ptr_x_reg) + $signed(i_ptr_x_move) >= 0 && $signed(ptr_x_reg) + $signed(i_ptr_x_move) < SCREEN_WIDTH)
            ptr_x_next = $signed(ptr_x_reg) + $signed(i_ptr_x_move);
        else ptr_x_next = ptr_x_reg;
        if($signed(ptr_y_reg) - $signed(i_ptr_y_move) >= 0 && $signed(ptr_y_reg) - $signed(i_ptr_y_move) < SCREEN_HEIGHT)
            ptr_y_next = $signed(ptr_y_reg) - $signed(i_ptr_y_move);
        else ptr_y_next = ptr_y_reg;
    end

    assign o_clk_tick = ~is_clk & is_clk_next;
    assign o_ptr_x = ptr_x_reg;
    assign o_ptr_y = ptr_y_reg;
    assign o_sel_x = ptr_x_reg;
    assign o_sel_y = ptr_y_reg;

endmodule
