`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 26.06.2024 19:03:06
// Design Name: 
// Module Name: receiver
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


module receiver
    #(parameter d_bits = 8, //data bits
                sb_tick = 16 // stop bit ticks
     )
     (
        input clk,reset_n,rx,s_tick,
        output reg rx_done_tick,
        output [d_bits - 1:0] rx_dout   
    );
    localparam idle = 0;
    localparam start = 1;
    localparam data = 2;
    localparam stop = 3;
    
    reg[1:0]state_reg,state_next;
    reg[3:0]s_reg,s_next; //keep track of baud rate ticks
    reg[$clog2(d_bits)-1:0]n_reg,n_next; //keep track of number of bits received
    reg[d_bits-1:0]b_reg,b_next; //store bits received
    always@(posedge clk, negedge reset_n)
    begin
        if(~reset_n)
        begin
        state_reg <= idle;
        s_reg <= 0;
        n_reg <= 0;
        b_reg <= 0;
        end
        else
        begin
            state_reg <= state_next;
            s_reg <= s_next;
            n_reg <= n_next;
            b_reg <= b_next;
        end 
    end
    //next state logic
    always @(*)
    begin
         state_reg <= state_reg;
         s_reg <= s_reg;
         n_reg <= n_reg;
         b_reg <= b_reg;
         rx_done_tick = 1'b0;
         case(state_reg)
            idle:
                if(~rx)
                begin
                    s_next = 0;
                    state_next = start;
                end
            start:
                if(s_tick)
                    if(s_reg == 7)
                    begin
                        s_next = 0;
                        n_next = 0;
                        state_next = data;
                    end
                    else
                        s_next = s_reg+1;
             data:
                 if(s_tick)
                    if(s_reg == 15)
                    begin
                        s_next = 0;
                        b_next = {rx,b_reg[d_bits-1:1]};
                        if(n_reg == d_bits-1)
                            state_next = stop;
                        else
                            n_next = n_reg + 1;
                    end
                    else
                        s_next = s_reg + 1;
              stop:
                    if(s_tick)
                        if(s_reg == sb_tick-1)
                        begin
                            rx_done_tick = 1'b1;
                            state_next = idle;
                        end
                        else
                            s_next = s_reg + 1;
              default:
                    s_next = s_reg + 1;
       endcase  
    end
    assign rx_dout = b_reg;
     
endmodule
