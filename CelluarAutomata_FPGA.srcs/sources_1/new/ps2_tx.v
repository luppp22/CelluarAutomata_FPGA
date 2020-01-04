`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2019/12/13 11:44:54
// Design Name: 
// Module Name: ps2_tx
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


module ps2_tx(
    input wire CLK,
    input wire i_rst,
    input wire i_ena,
    input [7:0] i_data,
    inout wire io_ps2d,
    inout wire io_ps2c,
    output reg o_tx_idle,
    output reg o_tx_done_tick
    );



    // 状态编码
    localparam [2:0] idle  = 3'b000;
    localparam [2:0] rts   = 3'b001;
    localparam [2:0] start = 3'b010;
    localparam [2:0] write = 3'b011;
    localparam [2:0] stop  = 3'b100;



    // 信号声明
    reg [2:0] state_reg;    // 状态寄存器
    reg [7:0] state_next;

    reg [7:0] filter_reg;   // 波形窗口
    wire [7:0] filter_next;

    reg f_ps2c_reg;         // 从机时钟状态
    wire f_ps2c_next;

    reg [12:0] hold_reg;    // 用于维持CLK低电平状态
    reg [12:0] hold_next;

    reg [3:0] cnt_reg;      // 计数器
    reg [3:0] cnt_next;

    reg [8:0] data_reg;     // 数据寄存器
    reg [8:0] data_next;

    wire par;               // 奇偶校验位

    wire is_fall;           // 是否为下降沿

    reg ps2c_reg;           // 数据输出（从机）
    reg ps2d_reg;           // 时钟输出（从机）

    reg tri_c;              // 三态门
    reg tri_d;

    // 从机时钟下降沿检测
    always @ (posedge CLK or posedge i_rst)
    begin
        if(i_rst)
        begin
            filter_reg <= 0;
            f_ps2c_reg <= 0;
        end
        else
        begin
            filter_reg <= filter_next;
            f_ps2c_reg <= f_ps2c_next;
        end
    end

    assign filter_next = {io_ps2c, filter_reg[7:1]};
    assign f_ps2c_next = (filter_reg == 8'b1111_1111) ? 1'b1 :
                         (filter_reg == 8'b0000_0000) ? 1'b0 :
                         f_ps2c_reg;
    assign is_fall = f_ps2c_reg & ~f_ps2c_next;



    // 状态机实现
        // 状态转移
    always @ (posedge CLK, posedge i_rst)
    begin
        if(i_rst)
        begin
            state_reg <= idle;
            hold_reg <= 0;
            cnt_reg <= 0;
            data_reg <= 0;
        end
        else
        begin
            state_reg <= state_next;
            hold_reg <= hold_next;
            cnt_reg <= cnt_next;
            data_reg <= data_next;
        end
    end

        // 奇偶校验
    assign par = ~(^i_data);

        // 次态逻辑
    always @ *
    begin
        state_next = state_reg;
        hold_next = hold_reg;
        cnt_next = cnt_reg;
        data_next = data_reg;
        o_tx_done_tick = 1'b0;
        ps2c_reg = 1'b1;
        ps2d_reg = 1'b1;
        tri_c = 1'b0;
        tri_d = 1'b0;
        o_tx_idle = 1'b0;
        case(state_reg)
            idle:   // 写信号为0时
            begin
                o_tx_idle = 1'b1;
                if(i_ena)
                begin
                    data_next = {par, i_data};
                    hold_next = 13'h1fff;   // 2^13-1
                    state_next = rts;
                end
            end
            rts:    // request to send 请求发送
            begin
                ps2c_reg = 1'b0;
                tri_c = 1'b1;
                hold_next = hold_next - 1;
                if(hold_reg == 0) state_next = start;
            end
            start:  // 发送开始信号
            begin
                ps2d_reg = 1'b0;
                tri_d = 1'b1;
                if(is_fall)
                begin
                    cnt_next = 4'h8;
                    state_next = write;
                end
            end
            write:  // 发送8位数据 + 1位校验位
            begin
                ps2d_reg = data_reg[0];
                tri_d = 1'b1;
                if(is_fall)
                begin
                    data_next = {1'b0, data_reg[8:1]};
                    if(cnt_reg == 0) state_next = stop;
                    else cnt_next = cnt_reg - 1;
                end
            end
            stop:   // 结束信号占时
            begin
                if(is_fall)
                begin
                    state_next = idle;
                    o_tx_done_tick = 1'b1;
                end
            end
        endcase
    end

    // inout端三态门设置
    assign io_ps2c = (tri_c) ? ps2c_reg : 1'bz;
    assign io_ps2d = (tri_d) ? ps2d_reg : 1'bz;

endmodule
