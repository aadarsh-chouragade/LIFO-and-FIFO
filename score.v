module score( 
 input clk_fpga, 
 input reset, 
 input btnU, 
 input sw, // switch between Team 1 and Team 2 
 
 output [0:6] segW,segO, segT, segH, 
 output [6:0] Y, 
 output [7:0] led // drive the leds 
 ); 
 
 wire delivery; // debounced up button press 
 wire [7:0] binaryRuns; // runs from game 
 wire [3:0] binaryWickets; // wickets from game 
 wire inningOver;
 wire gameOver; 
 wire winner; 
 

debounce d0(clk_fpga, btnU, delivery); 

 cricketGame g0(clk_fpga, reset, delivery, sw, binaryRuns, 
binaryWickets, led, inningOver, gameOver, winner,Y);
 
 bcdDisplay b0(clk_fpga, binaryRuns, binaryWickets, 
inningOver, gameOver, winner, segW, segO , segT, segH); 
 
endmodule

module debounce( 
 input clk_fpga, // clock signal input button, 
 input button, // input button 
 output debounced_button // debounced button 
 ); 
 
 wire Q1; // output of first D flip flop and input of 
 wire Q2; // output of second D flip flop 
 wire Q2_bar; // inverted output of second D flip flop 
 

 slowClock_10Hz u1(clk_fpga, clk_10Hz); // 10Hz slow 
 D_FF d1(clk_10Hz, button, Q1); // first flip flop 
 D_FF d2(clk_10Hz, Q1, Q2);
 
 assign Q2_bar = ~Q2; 
 assign debounced_button = Q1 & Q2_bar; 
endmodule 

module D_FF( 
 input clk, // input clock, slow clock 
 input D, // pushbotton 
 output reg Q, 
output reg Qbar 
 ); 
 
 always @ (posedge clk) begin 
 Q <= D; 
 Qbar <= !Q; 
 end 
endmodule 

module cricketGame( 
 input clk_fpga, 
 input reset, 
 input delivery, 
 input teamSwitch, 
 output [7:0] runs, 
 output [3:0] wickets, 
 output [7:0] leds, 
 output inningOver, 
 output gameOver, 
 output winner, 
 output [6:0] y 
 ); 
 wire clk_10; 
 wire [11:0] team1Data; 
 wire [11:0] team2Data; 
 wire [6:0] team1Balls; 
 wire [6:0] team2Balls; 
 wire [3:0] lfsr_out; 
 
slowClock_10Hz(clk_fpga,clk_10); 

lfsr g1(clk_10, reset, lfsr_out); 
 
lab6(y,lfsr_out); 

 score_and_wickets g2(clk_10, reset, delivery, teamSwitch, 
lfsr_out, gameOver, runs, wickets, team1Data, team2Data); 

 score_comparator g3(clk_10, reset, team1Data, team2Data, 
team1Balls, team2Balls, wickets, leds, inningOver, gameOver, winner);
 
 led_controller g4(clk_10, reset, teamSwitch, delivery, lfsr_out, 
inningOver, gameOver, leds, team1Balls, team2Balls); 

endmodule

module lfsr( 
 input clk_fpga, 
 input reset, 
 output [3:0] lfsr_out 
 ); 
 
 reg [5:0] shift; 
 wire xor_sum; 
 
 assign xor_sum = shift[1] ^ shift[4]; // feedback taps 
 always @ (posedge clk_fpga) 
 begin 
 if(reset) 
 shift <= 6'b111111; 
 else 
 shift <= {xor_sum, shift[5:1]}; // shift right 
 end 
 assign lfsr_out = shift[3:0]; // output of LFSR 
 
endmodule

module score_and_wickets( 
 input clk_fpga, 
 input reset, 
 input delivery, 
 input teamSwitch, 
 input [3:0] lfsr_out, 
 input gameOver, 
 output reg [7:0] runs, 
 output reg [3:0] wickets, 
 output reg [11:0] team1Data, 
 output reg [11:0] team2Data
 ); 
 localparam single = 16; 
 localparam double = 32; 
 localparam triple = 48; 
 localparam four = 64; 
 localparam six = 96; 
 
 // update score after each delivery(bowl) based on cricket rule. 
 always @ (posedge clk_fpga, posedge reset) 
 begin 
 if (reset) 
 begin 
 runs <= 0; 
 wickets <= 0; 
 team1Data <= 0; 
 team2Data <= 0; 
 end 
 else if (gameOver) 
 begin 
 runs <= runs; 
 wickets <= wickets; 
 team1Data <= team1Data; 
 team2Data <= team2Data; 
 end 
 else if(delivery) 
 begin 
 if((~teamSwitch) && (wickets < 10))
 begin 
 case (lfsr_out)
 0,1,2: team1Data <= team1Data;
 3,4,5,6: team1Data <= team1Data + single; 
  7,8,9: team1Data <= team1Data + double; 
 10: team1Data <= team1Data + triple; 
 11: team1Data <= team1Data + four; 
 12: team1Data <= team1Data + six; 
 13,14: team1Data <= team1Data;  
 15: team1Data <= team1Data + 1; 
 endcase 
 runs <= team1Data[11:4]; 
 wickets <= team1Data[3:0]; 
 end 
 else if((teamSwitch) && (wickets < 10))
 begin 
 case (lfsr_out) 
 0,1,2: team2Data <= team2Data;
 3,4,5,6: team2Data <= team2Data + single; 
 7,8,9: team2Data <= team2Data + double; 
 10: team2Data <= team2Data + triple; 
 11: team2Data <= team2Data + four; 
 12: team2Data <= team2Data + six;
 13,14: team2Data <= team2Data; // wide ball and no balls 
 15: team2Data <= team2Data + 1; //wickets 
 endcase 
 runs <= team2Data[11:4]; 
 wickets <= team2Data[3:0]; 
 end 
 end 
 else 
 begin 
 case (teamSwitch) 
 0: begin 
 runs <= team1Data[11:4]; 
 wickets <= team1Data[3:0]; 
 end 
 1: begin 
 runs <= team2Data[11:4]; 
 wickets <= team2Data[3:0]; 
 end 
 endcase 
 end 
 end 
endmodule

module score_comparator( 
 input clk_fpga, 
 input reset, 
 input [11:0] team1Data, 
 input [11:0] team2Data, 
 input [6:0] team1Balls, 
 
 
 input [6:0] team2Balls, 
 input [3:0] wickets, 
 input [7:0] balls, 
 output reg inningOver, 
 output reg gameOver, 
 output reg winnerLocked 
 ); 
 
  
 always @ (posedge clk_fpga) begin 
 if((wickets >= 10) || (balls >= 120)) 
 inningOver <= 1; 
 else 
 inningOver <= 0; 
 end 
  
 always @ (posedge clk_fpga, posedge reset) 
 begin 
 if (reset) 
 gameOver <= 0; 
 else if (((team1Data[3:0] >= 10) || (team1Balls >= 120)) && ((team2Data[3:0] >= 10) || (team2Balls >= 120)))
 gameOver <= 1; 
 else 
 gameOver <= gameOver; 
 end 
  
 always @ (posedge gameOver) begin 
 if (team1Data[11:4] > team2Data[11:4])  
 winnerLocked <= 0; 
 else 
 winnerLocked <= 1;  
 end 
 
endmodule 

module led_controller( 
 input clk_fpga, 
 input reset, 
 input teamSwitch, 
 input delivery, 
 input [3:0] lfsr_out, 
 input inningOver, 
 input gameOver, 
 output reg [7:0] leds, 
 output reg [6:0] team1Balls, 
 output reg [6:0] team2Balls 
 ); 
 
 wire [7:0] scroll;  
 
 always @ (posedge clk_fpga, posedge reset) begin 
 if (reset) 
 begin 
 leds <= 0; 
 team1Balls <= 0; 
 team2Balls <= 0; 
 end 
 else if(gameOver) 
 
 leds <= scroll;  
 else if(delivery) 
 begin 
 if((teamSwitch == 0) && (inningOver == 0))   
 begin 
 case (lfsr_out)  
 13,14: team1Balls <= team1Balls; 
 
 default: team1Balls <= team1Balls + 1;  
 endcase 
 leds <= team1Balls; 
 end 
 else if ((teamSwitch) && (inningOver == 0))  
 begin 
 case (lfsr_out) 
 13,14: team2Balls <= team2Balls; 
 default: team2Balls <= team2Balls +1; 
 endcase 
 leds <= team2Balls; 
 end 
 end 
 else if(~teamSwitch) 
 leds <= team1Balls; 
 else 
 leds <= team2Balls; 
 end 
  
 scroll_Leds g5 (clk_fpga, scroll); 
 
endmodule 

module scroll_Leds( 
 input clk_fpga, 
 output reg [7:0] led 
 ); 
 
 wire clk_10Hz; 
 always @ (posedge clk_10Hz) 
 begin 
 if (led == 8'hff) 
 led <= 8'hfe;  
 else 
 led <= {led[6:0], 1'b1}; 
 end 
 slowClock_10Hz c0 (clk_fpga, clk_10Hz); 
endmodule 

module slowClock_10Hz( 
 input clk_fpga, 
 output reg clk_10Hz);
 
 localparam clkdiv = 5_000_000 - 1; 
 reg [22:0] period_count = 0; 
  
 always@ (posedge clk_fpga) 
 begin 
 period_count <= period_count + 1'b1; 
 if (period_count == 2_500_000) 
 begin 
 period_count <= 0;  
 clk_10Hz <= ~clk_10Hz; 
 end 
 end 
endmodule 


module bcdDisplay( 
 input clk_fpga, 
 input [7:0] binaryRuns,  
 input [3:0] binaryWickets,  
 input inningOver,  
 input gameOver,  
 input winner,  
 
 output [6:0] segW,segO,segT,seg
 ); 
 
 wire clk_1kHz; 
 wire [3:0] mux_out; 
 wire [1:0] counter_out; 
 wire [3:0] wickets, ones, tens, hundreds; 
 
  
 binary_to_BCD b1 (binaryRuns, binaryWickets, inningOver, 
gameOver, winner, wickets, ones, tens, hundreds); 
 
 bcd7seg b2 (wickets, segW); 
 bcd7seg b3 (ones, segO); 
 bcd7seg b4 (tens, segT); 
 bcd7seg b5 (hundreds, segH); 
endmodule 

module binary_to_BCD( 
 
 
 input [7:0] binaryRuns, 
 input [3:0] binaryWickets, 
 input inningOver, 
 input gameOver, 
 input winner, 
 output reg [3:0] wickets, ones, tens, hundreds
 );
 
 reg [7:0] data;  
 
 always@ (binaryRuns,binaryWickets,inningOver, gameOver,winner)
 begin 
 if(~gameOver)  
 begin 
 if(inningOver) 
 begin 
 hundreds <= 4'b1100; 
 tens <= 4'b1101;   
 ones <= 4'b0000;  
 wickets <= 4'b1110; 
 end 
 else 
 begin 
 data = binaryRuns; 
 hundreds <= data / 100; 
 data = data % 100; 
 tens <= data / 10; 
 ones <= data % 10; 
 wickets <= (binaryWickets % 10); 
 end 
 end 
 else 
 begin 
 case (winner)  
 0: begin   
 hundreds <= 4'b1111; 
 tens <= 4'b0000; 
 
  
 ones <= 4'b0001; 
 wickets <= 4'b0000; 
 end 
 1: begin  
 hundreds <= 4'b1111; 
 tens <= 4'b0000; 
 ones <= 4'b0010; 
 wickets <= 4'b0000; 
 end 
 endcase 
 end 
 end 
endmodule 

module bcd7seg( 
 input [3:0] y, 
 output reg [6:0] segs 
 ); 
 
  
 always @ (y) 
 begin 
 case (y) 
 0: segs = 7'b100_0000; //0 
 1: segs = 7'b111_1001; //1 
 2: segs = 7'b010_0100; //2 
 3: segs = 7'b011_0000; //3 
 4: segs = 7'b001_1001; //4 
 5: segs = 7'b001_0010; //5 
 6: segs = 7'b000_0010; //6 
 7: segs = 7'b111_1000; //7 
 8: segs = 7'b000_0000; //8 
 9: segs = 7'b001_0000; //9 
 10: segs = 7'b000_1000; //A 
 11: segs = 7'b000_0011; //B 
 12: segs = 7'b101_1111;  
 13: segs = 7'b100_1111; 
 14: segs = 7'b111_1101; 
 15: segs = 7'b000_0111; 
 endcase 
 end 
endmodule 

module lab6(se,s); 
input [3:0]s; 
output reg [0:6]se; 
always@(s) 
begin 
case(s) 
4'b0000:se=7'b0000001; 
4'b0001:se=7'b1001111; 
4'b0010:se=7'b0010010; 
4'b0011:se=7'b0000110; 
4'b0100:se=7'b1001100; 
4'b0101:se=7'b0100100; 
4'b0110:se=7'b0100000; 
4'b0111:se=7'b0001111; 
4'b1000:se=7'b0000000; 
4'b1001:se=7'b0000100; 
4'b1010:se=7'b0000010; 
4'b1011:se=7'b1100000; 
4'b1100:se=7'b0110001; 
4'b1101:se=7'b1000010; 
4'b1110:se=7'b0110000; 
4'b1111:se=7'b0111000; 
endcase 
end 
endmodule