`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2019/12/09 23:00:07
// Design Name: 
// Module Name: ram
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


module ram #(
    parameter ADDR_WIDTH = 1,
    parameter DATA_WIDTH = 1,
    parameter DEPTH = 1,
    parameter MEMFILE = ""
    ) (
    input wire CLK,
    input wire [ADDR_WIDTH-1:0] i_addr, 
    input wire i_write,
    input wire [DATA_WIDTH-1:0] i_data,
    output reg [DATA_WIDTH-1:0] o_data 
    );

    reg [DATA_WIDTH-1:0] memory_array [0:DEPTH-1]; 

    initial begin
        if (MEMFILE > 0)
        begin
            $display("Loading memory init file '" + MEMFILE + "' into array.");
            $readmemb(MEMFILE, memory_array);
        end
    end

    always @ (posedge CLK)
    begin
        if(i_write)
        begin
            memory_array[i_addr] <= i_data;
        end
        o_data <= memory_array[i_addr];     
    end
endmodule