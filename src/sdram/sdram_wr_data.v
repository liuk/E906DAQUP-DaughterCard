`timescale 1ns / 1ps
////////////////////////////////////////////////////////////////////////////////
// Module Name	: sdram_wr_data
////////////////////////////////////////////////////////////////////////////////

module sdram_wr_data(
					clk,		
					rst_n,
					sdram_data,
					sys_data_in,
					sys_data_out,
					work_state,
					cnt_clk,
					rd_bstop
				);

input clk;		
input rst_n;	

input[15:0] 	sys_data_in;    // Write SDRAM
output[15:0]   sys_data_out;   // Read SDRAM
inout[15:0]    sdram_data;		 // SDRAM data bus

// SDRAM internal interface
input[3:0] work_state;	 
input[8:0] cnt_clk;		 
output rd_bstop;

`include "D:/WorkSpace/FermiLab/FPGA/DaughterCardRWtest-3-1/src/sdram/sdr_para.v"	 

//----------------------------------------------------
// Write data
//------------------------------------------------------------------------------
reg[15:0] sdr_din;	
reg sdr_dlink;		   

always @ (posedge clk)   
   if(!rst_n) begin 
			sdr_din <= 16'd0;	
         sdr_dlink <= 1'b0;
			end
   else if((work_state == `W_WRITE) | (work_state == `W_WD) | (work_state == `W_B_W_STOP)) begin
	            sdr_din   <= sys_data_in;	
					sdr_dlink <= 1'b1;					
					end
	else begin
					sdr_din <= 16'd0;
					sdr_dlink <= 1'b0;
					end
					
assign sdram_data = sdr_dlink ? sdr_din:16'hzzzz;

//------------------------------------------------------------------------------
// Read
//------------------------------------------------------------------------------
reg[15:0] sdr_dout;	

always @ (posedge clk)
   if(!rst_n)                    sdr_dout <= 16'd0;		   
   else if( (work_state == `W_RD) | (work_state ==`W_B_R_STOP) | (work_state == `W_RWAIT & cnt_clk <= 9'd1)  )    
							     sdr_dout <= sdram_data;					
   else                          sdr_dout <= 16'd0;		

assign rd_bstop      = sdr_dout[15]; 			
assign sys_data_out  = sdr_dout;
 
endmodule
