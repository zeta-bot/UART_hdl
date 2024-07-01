`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 27.06.2024 10:25:59
// Design Name: 
// Module Name: transmitter
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


module transmitter
    #(parameter d_bits = 8,
                sb_tick = 16
    )
    (
        input clk, reset_n,
        input tx_start, s_tick,
        input [d_bits - 1 : 0] tx_din,
        output reg tx_done_tick,
        output tx
    );
    localparam idle = 0;
    localparam start = 1;
    localparam data = 2;
    localparam stop = 3;
    
    reg [1:0] state_reg,state_next;     //which state we are currently in
    reg [3:0] s_reg,s_next;     //number of s_ticks
    reg [$clog2(d_bits) - 1:0] n_reg, n_next;       //number of bits transmitted
    reg [d_bits - 1:0] b_reg, b_next;       //store bits to be transmitted
    reg tx_reg,tx_next;     //bit to be transmitted
    
    always@(posedge clk, negedge reset_n)
    begin
        if(~reset_n)
        begin
            state_reg <= idle;
            s_reg <= 0;
            n_reg <= 0;
            b_reg <= 0;
            tx_reg <= 1'b1;
         end
         else
         begin
            state_reg <= state_next;
            s_reg <= s_next;
            n_reg <= n_next;
            b_reg <= b_next;
            tx_reg <= tx_next;
         end
      end
      
      //next state logic
      always @(*)
      begin
            state_next = state_reg;
            s_next = s_reg;
            n_next = n_reg;
            b_next = b_reg;
            tx_done_tick = 1'b0;
            case(state_reg)
                idle:
                begin
                    tx_next = 1'b1;
                    if (tx_start)
                    begin
                        s_next = 0;
                        b_next = tx_din;
                        state_next = start;
                    end
                 end
                 start:
                 begin
                    tx_next = 1'b0;
                    if(s_tick)
                        if(s_reg == 15)
                        begin
                            s_next = 0;
                            n_next = 0;
                            state_next = data;
                        end
                        else
                            s_next = s_reg + 1;
                  end
                  data:
                  begin
                        tx_next = b_reg[0];
                        if(s_tick)
                            if(s_reg == 15)
                            begin
                                s_next = 0;
                                b_next = {1'b0, b_reg[d_bits - 1:1]};
                                if(n_reg == d_bits-1)
                                    state_next = stop;
                                else
                                    n_next = n_reg + 1;
                             end
                             else
                                s_next = s_reg + 1;
                   end
                   stop:
                   begin
                        tx_next = 1'b1;
                        if(s_tick)
                            if(s_reg == sb_tick - 1)
                            begin
                                tx_done_tick = 1'b1;
                                state_next = idle;
                            end
                            else
                                s_next = s_reg + 1;
                   end
                   default:
                        state_next = idle;
             endcase
       end
       assign tx = tx_reg;
endmodule
