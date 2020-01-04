`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2019/12/09 20:13:39
// Design Name: 
// Module Name: top
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


module top(
    input wire CLK,             // 100MHz时钟
    input wire i_rst,           // 重置信号
    input wire [2:0] i_spd,     // 速度控制
    inout wire io_ps2d,         // ps2数据信号
    inout wire io_ps2c,         // ps2时钟信号
    output wire o_vga_hs,       // VGA水平同步信号
    output wire o_vga_vs,       // VGA垂直同步信号
    output wire [3:0] o_vga_r,  // R信号
    output wire [3:0] o_vga_g,  // G信号
    output wire [3:0] o_vga_b   // B信号
    );

    localparam SCREEN_WIDTH     = 1024; // 屏幕宽度
    localparam SCREEN_HEIGHT    = 768;  // 屏幕高度
    localparam PIXEL_X_WIDTH    = 11;   // 像素x坐标位数
    localparam PIXEL_Y_WIDTH    = 11;   // 像素y坐标位数
    localparam BOARD_WIDTH      = 50;   // 细胞界面宽度（个数）
    localparam BOARD_HEIGHT     = 38;   // 细胞界面高度（个数）
    localparam CORD_X_WIDTH     = 7;    // 细胞x坐标位数
    localparam CORD_Y_WIDTH     = 7;    // 细胞y坐标位数
    localparam CELL_SIZE        = 20;   // 每个细胞的大小
    localparam LR_SPACE         = (SCREEN_WIDTH - CELL_SIZE * BOARD_WIDTH) / 2;     // 左右间隙（像素）
    localparam UD_SPACE         = (SCREEN_HEIGHT - CELL_SIZE * BOARD_HEIGHT) / 2;   // 上下间隙（像素）


    wire [PIXEL_X_WIDTH-1:0] ptr_x;     // 指针x坐标
    wire [PIXEL_Y_WIDTH-1:0] ptr_y;     // 指针y坐标
    wire [PIXEL_X_WIDTH-1:0] inq_x;     // 查询细胞x坐标
    wire [PIXEL_Y_WIDTH-1:0] inq_y;     // 查询细胞y坐标
    wire [PIXEL_X_WIDTH-1:0] sel_x;     // 修改细胞x坐标
    wire [PIXEL_Y_WIDTH-1:0] sel_y;     // 修改细胞y坐标
    wire pix_stb;                       // VGA更新像素分时钟
    wire cal_stb;                       // 细胞状态更新分时钟
    wire clk_tick;                      // 鼠标点击脉冲
    wire cell_sta;                      // 查询的细胞状态
    wire [PIXEL_X_WIDTH-1:0] vga_x;     // VGA目前扫描像素x坐标 
    wire [PIXEL_Y_WIDTH-1:0] vga_y;     // VGA目前扫描像素y坐标
    wire vga_is_active;                 // VGA当前扫描位置是否位于显示区域
    wire vga_screened_tick;             // VGA扫描完一帧脉冲
    wire [8:0] ptr_x_move;              // 鼠标x轴位移量（有符号数）
    wire [8:0] ptr_y_move;              // 鼠标y轴位移量（有符号数）
    wire [2:0] m_btnm;                  // 鼠标三键状态
    wire m_done_tick;                   // 鼠标接收完毕脉冲

    // 逻辑处理器模块
    logic_processor #(
        .SCREEN_WIDTH(SCREEN_WIDTH),
        .SCREEN_HEIGHT(SCREEN_HEIGHT),
        .PIXEL_X_WIDTH(PIXEL_X_WIDTH),
        .PIXEL_Y_WIDTH(PIXEL_Y_WIDTH),
        .BOARD_WIDTH(BOARD_WIDTH),
        .BOARD_HEIGHT(BOARD_HEIGHT),
        .CORD_X_WIDTH(CORD_X_WIDTH),
        .CORD_Y_WIDTH(CORD_Y_WIDTH),
        .CELL_SIZE(CELL_SIZE),
        .LR_SPACE(LR_SPACE),
        .UD_SPACE(UD_SPACE)
    ) logic_processor_ins (
        .CLK(CLK),
        .i_rst(i_rst),
        .i_spd(i_spd),
        .i_m_done_tick(m_done_tick),
        .i_ptr_x_move(ptr_x_move),
        .i_ptr_y_move(ptr_y_move),
        .i_m_btnm(m_btnm),
        .o_pix_stb(pix_stb),
        .o_cal_stb(cal_stb),
        .o_clk_tick(clk_tick),
        .o_ptr_x(ptr_x),
        .o_ptr_y(ptr_y),
        .o_sel_x(sel_x),
        .o_sel_y(sel_y)
    );
  
    // 鼠标模块
    ps2_mouse ps2_mouse_ins (
        .CLK(CLK),
        .i_rst(i_rst),
        .io_ps2d(io_ps2d),
        .io_ps2c(io_ps2c),
        .o_x_move(ptr_x_move),
        .o_y_move(ptr_y_move),
        .o_btnm(m_btnm),
        .o_m_done_tick(m_done_tick)
    );

    // 帧缓冲器模块
    frame_buffer #(
        .SCREEN_WIDTH(SCREEN_WIDTH),
        .SCREEN_HEIGHT(SCREEN_HEIGHT),
        .PIXEL_X_WIDTH(PIXEL_X_WIDTH),
        .PIXEL_Y_WIDTH(PIXEL_Y_WIDTH),
        .BOARD_WIDTH(BOARD_WIDTH),
        .BOARD_HEIGHT(BOARD_HEIGHT),
        .CORD_X_WIDTH(CORD_X_WIDTH),
        .CORD_Y_WIDTH(CORD_Y_WIDTH),
        .CELL_SIZE(CELL_SIZE),
        .LR_SPACE(LR_SPACE),
        .UD_SPACE(UD_SPACE)
    ) frame_buffer_ins (
        .CLK(CLK),
        .i_rst(i_rst),
        .i_pix_stb(pix_stb),
        .i_ptr_x(ptr_x),
        .i_ptr_y(ptr_y),
        .i_cell_sta(cell_sta),
        .o_vga_r(o_vga_r),
        .o_vga_g(o_vga_g),
        .o_vga_b(o_vga_b),
        .o_inq_x(inq_x),
        .o_inq_y(inq_y),
        .o_vga_hs(o_vga_hs),
        .o_vga_vs(o_vga_vs)
    );

    // 自动机模块
    automaton # (
        .SCREEN_WIDTH(SCREEN_WIDTH),
        .SCREEN_HEIGHT(SCREEN_HEIGHT),
        .BOARD_WIDTH(BOARD_WIDTH),
        .BOARD_HEIGHT(BOARD_HEIGHT),
        .CELL_SIZE(CELL_SIZE),
        .PIXEL_X_WIDTH(PIXEL_X_WIDTH),
        .PIXEL_Y_WIDTH(PIXEL_Y_WIDTH),
        .CORD_X_WIDTH(CORD_X_WIDTH),
        .CORD_Y_WIDTH(CORD_Y_WIDTH),
        .LR_SPACE(LR_SPACE),
        .UD_SPACE(UD_SPACE)
    ) automaton_ins (
        .CLK(CLK),
        .i_rst(i_rst),
        .i_cal_stb(cal_stb),
        .i_clk_tick(clk_tick),
        .i_inq_x(inq_x),
        .i_inq_y(inq_y),
        .i_sel_x(sel_x),
        .i_sel_y(sel_y),
        .o_sta(cell_sta)
    );

endmodule
