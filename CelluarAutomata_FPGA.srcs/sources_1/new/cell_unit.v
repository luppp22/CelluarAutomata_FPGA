`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2019/12/18 19:30:40
// Design Name: 
// Module Name: cell_unit
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


module cell_unit(
    input wire CLK,
    input wire i_rst,
    input wire i_cal_stb,
    input wire i_flip,    // 当前是否被选中（修改）
    input wire i_lf_tp,
    input wire i_md_tp,
    input wire i_rt_tp,
    input wire i_lf_md,
    input wire i_rt_md,
    input wire i_lf_bt,
    input wire i_md_bt,
    input wire i_rt_bt,
    output wire o_sta
    );

    reg state;
    wire state_next;
    wire [3:0] sum;

    assign sum = i_lf_tp + 
                 i_md_tp + 
                 i_rt_tp + 
                 i_lf_md + 
                 i_rt_md + 
                 i_lf_bt + 
                 i_md_bt + 
                 i_rt_bt;
    
    assign state_next = (sum == 2 & state) | (sum == 3);

    always @ (posedge CLK or posedge i_rst)
    begin
        if(i_rst) state <= 0;
        else
        begin
            if(i_cal_stb) state <= state_next;
            else state <= i_flip ^ state;
        end
    end

    assign o_sta = state;

endmodule
