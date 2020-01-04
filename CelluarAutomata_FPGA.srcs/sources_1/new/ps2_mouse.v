`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2019/12/13 14:17:19
// Design Name: 
// Module Name: ps2_mouse
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


module ps2_mouse(
    input wire CLK,
    input wire i_rst,
    inout wire io_ps2d,
    inout wire io_ps2c,
    output wire [2:0] o_btnm,
    output wire [8:0] o_x_move,
    output wire [8:0] o_y_move,
    output reg o_m_done_tick
    );

    localparam STRM = 8'hf4;    // stream command

    // 状态编码
    localparam [2:0] init_1 = 3'b000;
    localparam [2:0] init_2 = 3'b001;
    localparam [2:0] init_3 = 3'b010;
    localparam [2:0] pack_1 = 3'b011;
    localparam [2:0] pack_2 = 3'b100;
    localparam [2:0] pack_3 = 3'b101;
    localparam [2:0] pack_4 = 3'b110;
    localparam [2:0] done   = 3'b111;

    // 变量声明
    reg [2:0] state_reg;    // 状态机寄存器
    reg [2:0] state_next;

    wire [7:0] rx_data;     // 读入的8bit数据
    reg [2:0] btn_reg;      // 按键状态
    reg [2:0] btn_next;
    reg [8:0] x_reg;        // x轴位移寄存器
    reg [8:0] x_next;
    reg [8:0] y_reg;        // y轴位移寄存器
    reg [8:0] y_next;
    
    reg w_ena;              // 发送使能
    wire tx_idle;           // 发送闲置

    wire rx_done_tick;      // 读取完毕信号
    wire tx_done_tick;      // 发送完毕信号



    // 实例化

    ps2_rx ps2_rx_unit (
        .CLK(CLK),
        .i_rst(i_rst),
        .i_ena(tx_idle),
        .i_ps2d(io_ps2d),
        .i_ps2c(io_ps2c),
        .o_rx_done_tick(rx_done_tick),
        .o_data(rx_data)
    );
    
    ps2_tx ps2_tx_unit (
        .CLK(CLK),
        .i_rst(i_rst),
        .i_ena(w_ena),
        .i_data(STRM),
        .io_ps2d(io_ps2d),
        .io_ps2c(io_ps2c),
        .o_tx_idle(tx_idle),
        .o_tx_done_tick(tx_done_tick)
    );


    // 状态机实现
        // 状态转移
    always @ (posedge CLK or posedge i_rst)
    begin
        if(i_rst)
        begin
            state_reg <= init_1;
            btn_reg <= 0;
            x_reg <= 0;
            y_reg <= 0;
        end
        else
        begin
            state_reg <= state_next;
            btn_reg <= btn_next;
            x_reg <= x_next;
            y_reg <= y_next;
        end
    end

        // 次态逻辑
    always @ *
    begin
        state_next = state_reg;
        w_ena = 1'b0;
        o_m_done_tick = 1'b0;
        btn_next = btn_reg;
        x_next = x_reg;
        y_next = y_reg;
        case(state_reg)
            init_1:     // 准备发送命令
            begin
                w_ena <= 1'b1;
                state_next = init_2;
            end
            init_2:
            begin       // 等待发送完成
                if(tx_done_tick)
                    state_next = init_3;
            end
            init_3:     // 等待接收答复
            begin
                if(rx_done_tick)
                    state_next = pack_1;
            end
            pack_1:     // 等待第一段数据接收完成
            begin
                if(rx_done_tick)
                begin
                    state_next = pack_2;
                    btn_next = rx_data[2:0];    // 三键状态
                    x_next[8] = rx_data[4];     // x位移符号位
                    y_next[8] = rx_data[5];     // y位移符号位
                end
            end
            pack_2:     // 等待第二段数据接收完成
            begin
                if(rx_done_tick)
                begin
                    state_next = pack_3;
                    x_next[7:0] = rx_data; 
                end
            end
            pack_3:     // 等待第三段数据接收完成
            begin
                if(rx_done_tick)
                begin
                    state_next = done;
                    y_next[7:0] = rx_data;
                end
            end
            done:       // 接收完毕
            begin
                o_m_done_tick = 1'b1;
                state_next = pack_1;
            end

        endcase
    end

    // 输出
    assign o_btnm = btn_reg;
    assign o_x_move = x_reg;
    assign o_y_move = y_reg;

endmodule