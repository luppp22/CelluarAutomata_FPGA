`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2019/12/18 16:39:54
// Design Name: 
// Module Name: automaton
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


module automaton # (
    parameter SCREEN_WIDTH    = 1024,
    parameter SCREEN_HEIGHT   = 768,
    parameter BOARD_WIDTH     = 50,
    parameter BOARD_HEIGHT    = 38,
    parameter CELL_SIZE       = 20,
    parameter PIXEL_X_WIDTH   = 11,
    parameter PIXEL_Y_WIDTH   = 11,
    parameter CORD_X_WIDTH    = 6,
    parameter CORD_Y_WIDTH    = 6,
    parameter LR_SPACE        = (SCREEN_WIDTH - CELL_SIZE * BOARD_WIDTH) / 2,
    parameter UD_SPACE        = (SCREEN_HEIGHT - CELL_SIZE * BOARD_HEIGHT) / 2
    ) (
    input wire CLK,
    input wire i_rst,
    input wire i_cal_stb,     // 计算下一状态的脉冲
    input wire i_clk_tick,     // 按下鼠标时产生的脉冲
    input wire [PIXEL_X_WIDTH-1:0] i_inq_x,
    input wire [PIXEL_Y_WIDTH-1:0] i_inq_y,
    input wire [PIXEL_X_WIDTH-1:0] i_sel_x,
    input wire [PIXEL_Y_WIDTH-1:0] i_sel_y,
    output wire o_sta
    );
    
    (* MAX_FANOUT = 50 *) reg [PIXEL_X_WIDTH-1:0] sel_x_fb1;
    (* MAX_FANOUT = 50 *) reg [PIXEL_Y_WIDTH-1:0] sel_y_fb1;
    (* MAX_FANOUT = 50 *) reg [PIXEL_X_WIDTH-1:0] inq_x_fb1;
    (* MAX_FANOUT = 50 *) reg [PIXEL_Y_WIDTH-1:0] inq_y_fb1;
    (* MAX_FANOUT = 50 *) reg [PIXEL_X_WIDTH-1:0] sel_x_fb2;
    (* MAX_FANOUT = 50 *) reg [PIXEL_Y_WIDTH-1:0] sel_y_fb2;
    (* MAX_FANOUT = 50 *) reg [PIXEL_X_WIDTH-1:0] inq_x_fb2;
    (* MAX_FANOUT = 50 *) reg [PIXEL_Y_WIDTH-1:0] inq_y_fb2;
    reg [CORD_X_WIDTH-1:0] sel_x_fb3;
    reg [CORD_Y_WIDTH-1:0] sel_y_fb3;
    reg [CORD_X_WIDTH-1:0] inq_x_fb3;
    reg [CORD_Y_WIDTH-1:0] inq_y_fb3;

    wire [0:BOARD_WIDTH*BOARD_HEIGHT-1] is_sel;
    wire [0:BOARD_WIDTH*BOARD_HEIGHT*2-1] cell_sta;

    wire [0:BOARD_WIDTH*BOARD_HEIGHT-1] lf_tp_i; // 左上输入
    wire [0:BOARD_WIDTH*BOARD_HEIGHT-1] md_tp_i;
    wire [0:BOARD_WIDTH*BOARD_HEIGHT-1] rt_tp_i;
    wire [0:BOARD_WIDTH*BOARD_HEIGHT-1] lf_md_i;
    wire [0:BOARD_WIDTH*BOARD_HEIGHT-1] rt_md_i;
    wire [0:BOARD_WIDTH*BOARD_HEIGHT-1] lf_bt_i;
    wire [0:BOARD_WIDTH*BOARD_HEIGHT-1] md_bt_i;
    wire [0:BOARD_WIDTH*BOARD_HEIGHT-1] rt_bt_i;

    wire [0:BOARD_WIDTH*BOARD_HEIGHT-1] lf_tp_o; // 左上输出
    wire [0:BOARD_WIDTH*BOARD_HEIGHT-1] md_tp_o;
    wire [0:BOARD_WIDTH*BOARD_HEIGHT-1] rt_tp_o;
    wire [0:BOARD_WIDTH*BOARD_HEIGHT-1] lf_md_o;
    wire [0:BOARD_WIDTH*BOARD_HEIGHT-1] rt_md_o;
    wire [0:BOARD_WIDTH*BOARD_HEIGHT-1] lf_bt_o;
    wire [0:BOARD_WIDTH*BOARD_HEIGHT-1] md_bt_o;
    wire [0:BOARD_WIDTH*BOARD_HEIGHT-1] rt_bt_o;

    always @ (posedge CLK)
    begin
        sel_x_fb1 <= i_sel_x;
        sel_y_fb1 <= i_sel_y;
        inq_x_fb1 <= i_inq_x;
        inq_y_fb1 <= i_inq_y;

        sel_x_fb2 <= sel_x_fb1 - LR_SPACE;
        sel_y_fb2 <= sel_y_fb1 - UD_SPACE;
        inq_x_fb2 <= inq_x_fb1 - LR_SPACE;
        inq_y_fb2 <= inq_y_fb1 - UD_SPACE;

        if(
            sel_x_fb2 >= 0 &&
            sel_x_fb2 <= CELL_SIZE * BOARD_WIDTH &&
            sel_y_fb2 >= 0 &&
            sel_y_fb2 <= CELL_SIZE * BOARD_HEIGHT
        )
        begin
            sel_x_fb3 <= sel_x_fb2 / CELL_SIZE;
            sel_y_fb3 <= sel_y_fb2 / CELL_SIZE;
        end
        else
        begin
            sel_x_fb3 <= 63;
            sel_y_fb3 <= 63;
        end

        if(
            inq_x_fb2 >= 0 &&
            inq_x_fb2 <= CELL_SIZE * BOARD_WIDTH &&
            inq_y_fb2 >= 0 &&
            inq_y_fb2 <= CELL_SIZE * BOARD_HEIGHT
        )
        begin
            inq_x_fb3 <= inq_x_fb2 / CELL_SIZE;
            inq_y_fb3 <= inq_y_fb2 / CELL_SIZE;
        end
        else
        begin
            inq_x_fb3 <= 63;
            inq_y_fb3 <= 63;
        end
    end

    genvar i, j;
    generate
        for(i = 0; i < BOARD_HEIGHT; i = i + 1)
        begin
            for(j = 0; j < BOARD_WIDTH; j = j + 1)
            begin

                assign is_sel[i*BOARD_WIDTH+j] = (sel_y_fb3 == i && sel_x_fb3 == j);
                
                cell_unit cell_ins (
                    .CLK(CLK),
                    .i_rst(i_rst),
                    .i_cal_stb(i_cal_stb),
                    .i_flip(i_clk_tick & is_sel[i*BOARD_WIDTH+j]),
                    .i_lf_tp(cell_sta[(i-1)*BOARD_WIDTH+j-1]),
                    .i_md_tp(cell_sta[(i-1)*BOARD_WIDTH+j]),
                    .i_rt_tp(cell_sta[(i-1)*BOARD_WIDTH+j+1]),
                    .i_lf_md(cell_sta[i*BOARD_WIDTH+j-1]),
                    .i_rt_md(cell_sta[i*BOARD_WIDTH+j+1]),
                    .i_lf_bt(cell_sta[(i+1)*BOARD_WIDTH+j-1]),
                    .i_md_bt(cell_sta[(i+1)*BOARD_WIDTH+j]),
                    .i_rt_bt(cell_sta[(i+1)*BOARD_WIDTH+j+1]),
                    .o_sta(cell_sta[i*BOARD_WIDTH+j])
                );

            end
        end

    endgenerate

    assign o_sta = cell_sta[inq_y_fb3*BOARD_WIDTH+inq_x_fb3];

endmodule
