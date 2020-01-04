`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2019/12/09 21:18:09
// Design Name: 
// Module Name: vga
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


module vga(
    input wire CLK,           // base clock
    input wire i_rst,           // restart frame
    input wire i_pix_stb,       // 65MHz clock
    output wire o_hs,           // horizontal sync
    output wire o_vs,           // vertical sync
    output wire o_is_blanking,     // high during blanking interval
    output wire o_is_active,       // high during active pixel drawing
    output wire o_screened_tick,    // high for one tick at the end of screen
    output wire o_animate_tick,      // high for one tick at end of active drawing
    output wire [10:0] o_x,      // current pixel x position
    output wire [10:0] o_y       // current pixel y position
    );

    localparam HS_STA = 24;                     // horizontal sync start
    localparam HS_END = 24 + 136;               // horizontal sync end
    localparam HA_STA = 24 + 136 + 160;         // horizontal active pixel start
    localparam VS_STA = 768 + 3;                // vertical sync start
    localparam VS_END = 768 + 3 + 6;            // vertical sync end
    localparam VA_STA = 0;                      // vertical active pixel start
    localparam VA_END = 768;                    // vertical active pixel end
    localparam LINE   = 1024 + 24 + 136 + 160;  // complete line (pixels)
    localparam SCREEN = 768 + 3 + 6 + 29;       // complete screen (lines)

    reg [10:0] h_count;  // line position
    reg [10:0] v_count;  // column position


    
    assign o_hs = ~((h_count >= HS_STA) && (h_count < HS_END));
    assign o_vs = ~((v_count >= VS_STA) && (v_count < VS_END));

    assign o_x = (h_count < HA_STA) ? 0 : (h_count - HA_STA);
    assign o_y = (v_count >= VA_END) ? (VA_END - VA_STA - 1) : (v_count - VA_STA);

    assign o_is_blanking = ((h_count < HA_STA) || (v_count > VA_END - 1));
    assign o_is_active = ~((h_count < HA_STA) || (v_count > VA_END - 1) || (v_count < VA_STA)); 

    assign o_screened_tick = ((v_count == SCREEN - 1) && (h_count == LINE));
    assign o_animate_tick = ((v_count == VA_END - 1) && (h_count == LINE));

    always @ (posedge CLK)
    begin
        if(i_rst)
        begin
            h_count <= 0;
            v_count <= 0;
        end
        if(i_pix_stb)
        begin
            if(h_count == LINE)
            begin
                h_count <= 0;
                v_count <= v_count + 1;
            end 
            else h_count <= h_count + 1;
            if(v_count == SCREEN) v_count <= 0;
        end
    end

endmodule
