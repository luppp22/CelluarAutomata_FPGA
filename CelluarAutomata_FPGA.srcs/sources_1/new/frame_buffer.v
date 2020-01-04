`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2019/12/09 23:02:09
// Design Name: 
// Module Name: frame_buffer
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


module frame_buffer #(
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
    input wire i_pix_stb,
    input wire [PIXEL_X_WIDTH-1:0] i_ptr_x,
    input wire [PIXEL_Y_WIDTH-1:0] i_ptr_y,
    input wire i_cell_sta,
    output wire [PIXEL_X_WIDTH-1:0] o_inq_x,
    output wire [PIXEL_Y_WIDTH-1:0] o_inq_y,
    output wire [3:0] o_vga_r,
    output wire [3:0] o_vga_g,
    output wire [3:0] o_vga_b,
    output wire o_vga_hs,
    output wire o_vga_vs
    );

    // 全局参数
    localparam FULL_D_WIDTH     = 2;    // 白、黑、透明
    localparam HALF_D_WDITH     = 1;    // 白、黑

    // 屏幕（背景）参数
    localparam VRAM_DEPTH       = SCREEN_WIDTH * SCREEN_WIDTH;
    localparam VRAM_A_WIDTH     = 20;
    localparam VRAM_D_WIDTH     = HALF_D_WDITH;

    // 光标参数
    localparam POINTER_SIZE     = 16;
    localparam POINTER_DEPTH    = POINTER_SIZE * POINTER_SIZE;
    localparam POINTER_A_WIDTH  = 8;
    localparam POINTER_D_WIDTH  = FULL_D_WIDTH;

    // 颜色参数
    localparam [3:0] COLOR_BLACK    = 4'b0000;
    localparam [3:0] COLOR_WHITE    = 4'b1111;

    // 变量声明
    wire vga_is_active;                     // 当前像素是否显示
    wire [PIXEL_X_WIDTH-1:0] vga_x;         // 当前像素x坐标
    wire [PIXEL_Y_WIDTH-1:0] vga_y;         // 当前像素y坐标
    reg [VRAM_A_WIDTH-1:0] addr_bg;         // 背景RAM地址输入
    wire [VRAM_D_WIDTH-1:0] dataout_bg;     // 背景RAM数据输出
    reg [POINTER_A_WIDTH-1:0] addr_p;       // 鼠标RAM地址输入
    wire [POINTER_D_WIDTH-1:0] dataout_p;   // 鼠标RAM数据输出

    reg bkg;
    reg cel;
    reg ptr;
    reg [1:0] ptr_clr;
    reg [3:0] vga_r;
    reg [3:0] vga_g;
    reg [3:0] vga_b;

    // VGA驱动
    vga vga_ins(
        .CLK(CLK),
        .i_rst(i_rst),
        .i_pix_stb(i_pix_stb),
        .o_hs(o_vga_hs),
        .o_vs(o_vga_vs),
        .o_x(vga_x),
        .o_y(vga_y),
        .o_is_active(vga_is_active)
    );

    // 背景内容储存
    ram #(
        .ADDR_WIDTH(VRAM_A_WIDTH),
        .DATA_WIDTH(VRAM_D_WIDTH),
        .DEPTH(VRAM_DEPTH),
        .MEMFILE("background.mem")
    ) background_ram(
        .CLK(CLK),
        .i_addr(addr_bg),
        .i_write(0),    // 只读
        .i_data(0),
        .o_data(dataout_bg)
    );

    // 光标内容存储
    ram #(
        .ADDR_WIDTH(POINTER_A_WIDTH),
        .DATA_WIDTH(POINTER_D_WIDTH),
        .DEPTH(POINTER_DEPTH),
        .MEMFILE("pointer.mem")
    ) pointer_ram (
        .CLK(CLK),
        .i_addr(addr_p),
        .i_write(0),    // 只读
        .i_data(0),
        .o_data(dataout_p)
    );

    assign o_inq_x = vga_x;
    assign o_inq_y = vga_y;
    assign o_vga_r = vga_r;
    assign o_vga_g = vga_g;
    assign o_vga_b = vga_b;

    always @ *
    begin
        addr_bg = vga_y*SCREEN_WIDTH+vga_x;
        bkg = dataout_bg;

        cel = i_cell_sta;

        if(
            vga_x >= i_ptr_x &&
            vga_x <= i_ptr_x + POINTER_SIZE - 1 &&
            vga_y >= i_ptr_y && 
            vga_y <= i_ptr_y + POINTER_SIZE - 1
        )
        begin
            ptr = 1;
            addr_p = (vga_y - i_ptr_y) * POINTER_SIZE + (vga_x - i_ptr_x);
            ptr_clr = dataout_p;
        end
        else
        begin
            ptr = 0;
            addr_p = 0;
            ptr_clr = 2'b0;
        end

        if(vga_is_active)
        begin
            if(ptr && ptr_clr != 2'b11)
            begin
                vga_r = ptr_clr[0] ? COLOR_BLACK : COLOR_WHITE;
                vga_g = ptr_clr[0] ? COLOR_BLACK : COLOR_WHITE;
                vga_b = ptr_clr[0] ? COLOR_BLACK : COLOR_WHITE;
            end
            else
            begin
                vga_r = (bkg | cel) ? COLOR_BLACK : COLOR_WHITE;
                vga_g = (bkg | cel) ? COLOR_BLACK : COLOR_WHITE;
                vga_b = (bkg | cel) ? COLOR_BLACK : COLOR_WHITE;
            end
        end
        else
        begin
            vga_r = COLOR_BLACK;
            vga_g = COLOR_BLACK;
            vga_b = COLOR_BLACK;
        end
    end

endmodule
