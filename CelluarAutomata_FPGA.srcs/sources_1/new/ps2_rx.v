`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2019/12/13 11:43:48
// Design Name: 
// Module Name: ps2_rx
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


module ps2_rx(
    input wire CLK,
    input wire i_rst,
    input wire i_ps2d,
    input wire i_ps2c,
    input wire i_ena,
    output reg o_rx_done_tick,
    output wire [7:0] o_data
    );



    // 自动机状态编码
    localparam [1:0] idle = 2'b00;
    localparam [1:0] dps  = 2'b01;
    localparam [1:0] load = 2'b10;



    // 信号声明
    reg [1:0] state_reg;    // 状态机
    reg [1:0] state_next;

    reg [7:0] filter_reg;   // 波形窗口
    wire [7:0] filter_next;

    reg f_ps2c_reg;         // 从机时钟状态
    wire f_ps2c_next;

    reg [3:0] cnt_reg;      // 计数器
    reg [3:0] cnt_next;

    reg [10:0] data_reg;    // 接收数据
    reg [10:0] data_next;

    wire is_fall;           // 从机时钟是否为下降沿



    // 下降沿检测
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

    assign filter_next = {i_ps2c, filter_reg[7:1]};
    assign f_ps2c_next = (filter_reg == 8'b1111_1111) ? 1'b1 :
                         (filter_reg == 7'b0000_0000) ? 1'b0 :
                         f_ps2c_reg;
    assign is_fall = f_ps2c_reg & ~f_ps2c_next;



    // 状态机实现
        // 状态转移
    always @ (posedge CLK, posedge i_rst)
    begin
        if(i_rst)
        begin
            state_reg <= idle;
            cnt_reg <= 0;
            data_reg <= 0;
        end
        else
        begin
            state_reg <= state_next;
            cnt_reg <= cnt_next;
            data_reg <= data_next;
        end
    end

        // 次态逻辑
    always @ *
    begin
        state_next = state_reg;
        o_rx_done_tick = 1'b0;
        cnt_next = cnt_reg;
        data_next = data_reg;
        case(state_reg)
            idle:   // 等待开始下降沿信号
            begin
                if(is_fall && i_ena)
                begin
                    data_next = {i_ps2d, data_reg[10:1]};
                    cnt_next = 4'b1001;
                    state_next = dps;
                end
            end
            dps:    // 8位数据 + 1位校验位
            begin
                if(is_fall)
                begin
                    data_next = {i_ps2d, data_reg[10:1]};   // 先收到的数据在高位
                    if(cnt_reg == 0) state_next = load;
                    else cnt_next = cnt_next - 1;
                end
            end
            load:   // 等待结束位
            begin
                state_next = idle;
                o_rx_done_tick = 1'b1;
            end
        endcase
    end


    
    // 输出
    assign o_data = data_reg[8:1];

endmodule
