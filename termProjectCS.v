`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    15:43:16 01/03/2021 
// Design Name: 
// Module Name:    termProjectCS 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module tel(clk, rst, startCall, answerCall, endCallCaller, endCallCallee, 
charSent, sendCharCaller, sendCharCallee, statusMsg, sentMsg);
	input clk, rst;
	input startCall, answerCall, endCallCaller, endCallCallee;
	input sendCharCaller, sendCharCallee;
	input [7:0] charSent;
	output reg [63:0] statusMsg = "IDLE    ";
	output reg [63:0] sentMsg = {8{8'd32}};
	
	reg [2:0] CurrentState;
	reg [2:0] NextState;
	
	reg [3:0] Counter = 0;
	reg [31:0] totalCost = 0;
	
	
	/*
	We have 6 states
	which are: 
	IDLE -> S0
	Ringing -> S1
	Reject -> S2
	Caller -> S3
	Callee -> S4
	Cost -> S5
	*/
	
	parameter [2:0] IDLE = 3'b000;
	parameter [2:0] Ringing = 3'b001;
	parameter [2:0] Reject = 3'b010;
	parameter [2:0] Caller = 3'b011;
	parameter [2:0] Callee = 3'b100;
	parameter [2:0] Cost = 3'b101;
	
	//sequential part - state transitions
	always @ (posedge clk or posedge rst) // asynchronous rst
	begin
		if(rst)
		begin
			CurrentState <= IDLE;
		end
		else
		begin
			CurrentState <= NextState;
		end	
	end
	
	always @ (posedge clk or posedge rst) //Control registers
	begin
		if(rst)
		begin
			totalCost <= 0;
			Counter <= 0;
		end
		else
		begin
			case(CurrentState)
				IDLE:
				begin
					totalCost <= 0;
					Counter <= 0;
				end
				Ringing:
				begin
					totalCost <= 0;
					Counter <= Counter + 1;
					if(NextState == Reject)
					begin
						Counter <= 0;
					end
				end
				Caller:
				begin
					Counter <= 0;
					if(sendCharCaller == 1)
					begin
						if(charSent == 127)
						begin
							totalCost <= totalCost + 2;		
						end
						else if(charSent < 8'd32 || charSent > 8'd127)
						begin
							totalCost <= totalCost;
						end
						else
						begin 
							if(charSent < 8'd48 || charSent > 8'd57 )
							begin
								totalCost <= totalCost + 2;
							end
							else
							begin
								totalCost <= totalCost + 1;
							end
						end
					end
					else
					begin
						totalCost <= totalCost;
					end
				end
				
				Callee:
				begin
					Counter <= 0;
					if(sendCharCallee == 1)
					begin
						if(charSent == 127)
						begin
							totalCost <= totalCost + 2;		
						end
						else if(charSent < 8'd32 || charSent > 8'd127)
						begin
							totalCost <= totalCost;
						end
						else
						begin 
							if(charSent < 8'd48 || charSent > 8'd57 )
							begin
								totalCost <= totalCost + 2;
							end
							else
							begin
								totalCost <= totalCost + 1;
							end
						end
					end
				end
				Reject:
				begin
					totalCost <= 0;
					Counter <= Counter + 1;
				end
				Cost:
				begin
					totalCost <= totalCost;
					Counter <= Counter + 1;
				end
				default:
				begin
					totalCost <= 0;
					Counter <= 0;
				end
			endcase	
		end
	end
	
	
	//combinational part - next state transitions
	always @ (*)
	begin
		case(CurrentState)
			IDLE:
			begin
				if(startCall == 1)
				begin
					NextState <= Ringing;
				end
				else
				begin
					NextState <= IDLE;
				end
			end
			Ringing:
			begin
				if(endCallCaller == 1)
				begin
					NextState <= IDLE;
				end
				else if(endCallCallee == 1)
				begin
					NextState <= Reject;
				end
				else if(answerCall == 1)
				begin 
					NextState <= Caller;
				end
				else
				begin
					if(Counter == 9)
					begin
						NextState <= IDLE;
					end
					else
					begin
						NextState <= Ringing;
					end				
				end
			end
			Reject:
			begin
				if(Counter == 9)
				begin
					NextState <= IDLE;		
				end
				else
				begin
					NextState <= Reject;					
				end
			end
			//Caller state
			Caller:
			begin
				if(sendCharCaller == 1)
				begin
					if(charSent == 127)
					begin
						if(endCallCaller == 0 && endCallCallee == 0)
						begin
							NextState <= Callee;
						end
						else 
						begin
							NextState <= Cost;
						end
					end
					else if(charSent < 8'd32 || charSent > 8'd127)
					begin
						if(endCallCaller == 0 && endCallCallee == 0)
						begin
							NextState <= Caller;
						end
						else 
						begin
							NextState <= Cost;
						end
					end
					else
					begin 
						if(endCallCaller == 0 && endCallCallee == 0)
						begin
							NextState <= Caller;
						end
						else 
						begin
							NextState <= Cost;
						end
					end
				end
				else 
				begin
					if(endCallCaller == 0 && endCallCallee == 0)
					begin
						NextState <= Caller;
					end
					else 
					begin
						NextState <= Cost;
					end
				end
			end
			//Callee State
			Callee:
			begin
				if(sendCharCallee == 1)
				begin
					if(charSent == 8'd127)
					begin
						if(endCallCaller == 0 && endCallCallee == 0)
						begin
							NextState <= Caller;
						end
						else 
						begin
							NextState <= Cost;
						end
					end
					else if(charSent < 8'd32 || charSent > 8'd127)
					begin
						if(endCallCaller == 0 && endCallCallee == 0)
						begin
							NextState <= Callee;
						end
						else 
						begin
							NextState <= Cost;
						end
					end
					else
					begin 
						if(endCallCaller == 0 && endCallCallee == 0)
						begin
							NextState <= Callee;
						end
						else 
						begin
							NextState <= Cost;
						end
						
					end
				end
					
				else 
				begin
					if(endCallCaller == 0 && endCallCallee == 0)
					begin
						NextState <= Callee;
					end
					else 
					begin
						NextState <= Cost;
					end
				end
			end
			Cost:
			begin
				if(Counter == 4)
				begin
					NextState <= IDLE;
				end
				else
				begin
					//sentMsg[31:0] <= totalCost;
					//sentMsg[63:32] <= 0;
					NextState <= Cost;
				end
			end
			default: 
			begin
				NextState <= IDLE;
				//sentMsg <= {8{8'd32}};
			end
		endcase	
		
	end
	
	always @ (posedge clk or posedge rst)	//Output messages
	begin
		if(rst)
		begin
			statusMsg <= "IDLE    ";
			sentMsg <= {8{8'd32}};
		end
		else
		begin
			case(CurrentState)
				IDLE:
				begin
					statusMsg <= "IDLE    ";
					sentMsg <= {8{8'd32}};
				end
				Ringing:
				begin
					statusMsg <= "RINGING ";
					sentMsg <= {8{8'd32}};
				end
				Reject:
				begin
					statusMsg <= "REJECTED";
					sentMsg <= {8{8'd32}};
				end
				Caller:
				begin
					statusMsg <= "CALLER  ";
					if(sendCharCaller == 1)
					begin
						if(charSent == 8'd127)
						begin
							sentMsg <= {8{8'd32}};
						end
						else if(charSent < 8'd32 || charSent > 8'd127)
						begin
							sentMsg <= sentMsg;
						end
						else
						begin
							sentMsg[7:0] <= charSent;
							sentMsg[15:8] <= sentMsg[7:0];
							sentMsg[23:16] <= sentMsg[15:8];
							sentMsg[31:24] <= sentMsg[23:16];
							sentMsg[39:32] <= sentMsg[31:24];
							sentMsg[47:40] <= sentMsg[39:32];
							sentMsg[55:48] <= sentMsg[47:40];
							sentMsg[63:56] <= sentMsg[55:48];
						end
						
					end
					else
					begin
						sentMsg <= sentMsg;
					end
				end
				Callee:
				begin
					statusMsg <= "CALLEE  ";
					if(sendCharCallee == 1)
					begin
						if(charSent == 8'd127)
						begin
							sentMsg <= {8{8'd32}};
						end
						else if(charSent < 8'd32 || charSent > 8'd127)
						begin
							sentMsg <= sentMsg;
						end
						else
						begin
							sentMsg[7:0] <= charSent;
							sentMsg[15:8] <= sentMsg[7:0];
							sentMsg[23:16] <= sentMsg[15:8];
							sentMsg[31:24] <= sentMsg[23:16];
							sentMsg[39:32] <= sentMsg[31:24];
							sentMsg[47:40] <= sentMsg[39:32];
							sentMsg[55:48] <= sentMsg[47:40];
							sentMsg[63:56] <= sentMsg[55:48];
						end
						
					end
					else
					begin
						sentMsg <= sentMsg;
					end
				end
				
				Cost:
				begin
					statusMsg <= "COST    ";
					//sentMsg[63:32] <= {4{8'd48}};
					sentMsg <= {8{8'd48}};
					// first left most 4 bit
					if(totalCost[31:28] < 4'b1010)
					begin
						sentMsg[63:56] <= 48 + totalCost[31:28];
					end
					else
					begin
						sentMsg[63:56] <= 55 + totalCost[31:28];
					end
					//second first left most 4 bit
					if(totalCost[27:24] < 4'b1010)
					begin
						sentMsg[55:48] <= 48 + totalCost[27:24];
					end
					else
					begin
						sentMsg[55:48] <= 55 + totalCost[27:24];
					end
					//third part
					if(totalCost[23:20] < 4'b1010)
					begin
						sentMsg[47:40] <= 48 + totalCost[23:20];
					end
					else
					begin
						sentMsg[47:40] <= 55 + totalCost[23:20];
					end
					//fourth part
					if(totalCost[19:16] < 4'b1010)
					begin
						sentMsg[39:32] <= 48 + totalCost[19:16];
					end
					else
					begin
						sentMsg[39:32] <= 55 + totalCost[19:16];
					end
					//fifth part
					if(totalCost[15:12] < 4'b1010)
					begin
						sentMsg[31:24] <= 48 + totalCost[15:12];
					end
					else
					begin
						sentMsg[31:24] <= 55 + totalCost[15:12];
					end
					//sixth part
					if(totalCost[11:8] < 4'b1010)
					begin
						sentMsg[23:16] <= 48 + totalCost[11:8];
					end
					else
					begin
						sentMsg[23:16] <= 55 + totalCost[11:8];
					end
					//seventh part
					if(totalCost[7:4] < 4'b1010)
					begin
						sentMsg[15:8] <= 48 + totalCost[7:4];
					end
					else
					begin
						sentMsg[15:8] <= 55 + totalCost[7:4];
					end
					//last part
					if(totalCost[3:0] < 4'b1010)
					begin
						sentMsg[7:0] <= 48 + totalCost[3:0];
					end
					else
					begin
						sentMsg[7:0] <= 55 + totalCost[3:0];
					end
					
					

				end
				default
				begin
					statusMsg <= "IDLE    ";
					sentMsg <= {8{8'd32}};
				end
			endcase
		end
	end
	
endmodule
