`timescale 1ns / 1ps
////////////////////////////////////////////////////////////////////////////////
// Top-level	: sdram_top
// Module Name	: sdram_cmd
// Function:     Assign the command to SDRAM for each work-state/ init-state
////////////////////////////////////////////////////////////////////////////////

module sdram_cmd(
				clk,		
		        rst_n,		
				sdram_cke,
				sdram_cs_n,
				sdram_ras_n,
				sdram_cas_n,
				sdram_we_n,
				sdram_ba,
				sdram_addr,
				init_state,
				work_state
			);
			
input clk;					
input rst_n;
// SDRAM hardware interface
output sdram_cke;			   
output sdram_cs_n;			
output sdram_ras_n;		
output sdram_cas_n;			
output sdram_we_n;			
output[1:0] sdram_ba;		
output[12:0] sdram_addr;	

// SDRAM internal interface
input[4:0] init_state;		 
input[3:0] work_state;		 


`include "D:/WorkSpace/FermiLab/FPGA/DaughterCardRWtest-3-1/src/sdram/sdr_para.v"		// SDRAM parameter defination 

//-------------------------------------------------------------------------------
//-------------------------------------------------------------------------------
reg[4:0]  sdram_cmd_r;	 
reg[1:0]  sdram_ba_r;
reg[12:0] sdram_addr_r;

assign {sdram_cke,sdram_cs_n,sdram_ras_n,sdram_cas_n,sdram_we_n} = sdram_cmd_r;
assign sdram_ba   = sdram_ba_r;
assign sdram_addr = sdram_addr_r;


//Addr. for write 
reg[1:0]  w_bank_addr;
reg[12:0] w_row_addr;
reg[8:0]  w_col_addr; 
//Addr. for read 
reg[1:0]  r_bank_addr;
reg[12:0] r_row_addr;
reg[8:0]  r_col_addr;
//-------------------------


//-------------------------------------------------------------------------------
//SDRAM  assign value to cmd&&addr
always @ (posedge clk or negedge rst_n) begin
	if(!rst_n) begin
			sdram_cmd_r  <= `CMD_INIT;
			sdram_ba_r   <= 2'b11;
			sdram_addr_r <= 13'h1fff;
			
         w_bank_addr <= 2'b0;
         w_row_addr  <= 13'b0;
         w_col_addr  <= 9'b0; 
         r_bank_addr <= 2'b0;
         r_row_addr  <= 13'b0;
         r_col_addr  <= 9'b0;
		end
	else
		case (init_state)
				`I_NOP,`I_TRP,`I_TRF1,`I_TRF2,`I_TRF3,`I_TRF4,`I_TRF5,`I_TRF6,`I_TRF7,`I_TRF8,`I_TMRD: begin
						sdram_cmd_r  <= `CMD_NOP;
						sdram_ba_r   <=  2'b11;
						sdram_addr_r <=  13'h1fff;	
					end
				`I_PRE: begin
						sdram_cmd_r  <= `CMD_PRGE;
						sdram_ba_r   <=  2'b11;
						sdram_addr_r <=  13'h1fff;
					end 
				`I_AR1,`I_AR2,`I_AR3,`I_AR4,`I_AR5,`I_AR6,`I_AR7,`I_AR8: begin
						sdram_cmd_r  <= `CMD_A_REF;
						sdram_ba_r   <=  2'b11;
						sdram_addr_r <=  13'h1fff;						
					end 			 	
				`I_MRS: begin						// mode reg setting 
						sdram_cmd_r  <= `CMD_LMR;
						sdram_ba_r   <=  2'b11;
						sdram_addr_r <= {
                            3'b000,			//  A12-A10 Reserved
                            1'b0,			//  M9 0 Programmed Burst Length  1 Single Location Access
                            2'b00,			// ({M8,M7}=00),Standard Operation
                            3'b011,			//  CAS latency (3£¬{M6,M5,M4}=011)
                            1'b0,			//  Burst Type:  0-Sequential/ 1-Interleaved   (sequential£¬M3=b0)
                            3'b111			//  Burst length  FULL PAGE     one page C8-C0 2^9=512   
														//  For one event 256*16bit  -> 2events/page
								};
					end	
				`I_DONE:
					case (work_state)
							`W_IDLE,`W_TRCD,`W_CL,`W_TRFC,`W_RD,`W_WD,`W_TDAL: begin
									sdram_cmd_r  <= `CMD_NOP;
									sdram_ba_r   <=  2'b11;
									sdram_addr_r <=  13'h1fff;
								end
							`W_ACTIVE_r: begin
									sdram_cmd_r  <= `CMD_ACTIVE;
									sdram_ba_r   <=  r_bank_addr[1:0];
									sdram_addr_r <=  r_row_addr[12:0];
								end
							`W_ACTIVE_w: begin
									sdram_cmd_r  <= `CMD_ACTIVE;
									sdram_ba_r   <=  w_bank_addr[1:0];
									sdram_addr_r <=  w_row_addr[12:0];
								end
							`W_READ: begin
									sdram_cmd_r  <= `CMD_READ;
									sdram_ba_r   <= r_bank_addr[1:0];	
									sdram_addr_r <= {
													4'b0010,		       // A10=1, enable pre-charge after writing
													r_col_addr[8:0]	 // col addr
												};
								//Since we write during spill/write out spill,   reset write-addr when begin reading
								   w_col_addr <= 9'd0;
							       w_row_addr <= 13'b0; 
							       w_bank_addr <= 2'b0;		 
							     																				 									
								end
							`W_WRITE: begin
									sdram_cmd_r  <= `CMD_WRITE;
									sdram_ba_r   <= w_bank_addr[1:0];
									sdram_addr_r <= {
													4'b0010,		
													w_col_addr[8:0]	 
												};								
								  //reset read-addr when begin writing
								   r_col_addr <= 9'd0;
							       r_row_addr <= 13'b0; 
							       r_bank_addr <= 2'b0;	
							      									
								end							
							`W_AR: begin
									sdram_cmd_r  <= `CMD_A_REF;
									sdram_ba_r   <= 2'b11;
									sdram_addr_r <= 13'h1fff;	
								end
							`W_B_W_STOP: begin
								
								    //Address auto-change for next event (256*16bits/event)												
									if(w_col_addr ==9'd256) begin
										       w_col_addr <= 9'd0;
										       if(w_row_addr ==13'h1fff) begin
											       w_row_addr  <= 13'b0;              
											       w_bank_addr <= w_bank_addr +2'b1;   //next bank
											   end
											   else w_row_addr <= w_row_addr + 13'b1;	//next row										 
											end
									else 	w_col_addr <= 9'd256;   
									
						            sdram_cmd_r  <= `CMD_B_STOP;
									sdram_ba_r   <= 2'b11;
									sdram_addr_r <= 13'h1fff;	
								end
							`W_B_R_STOP: begin
								
								    // Address auto-change for next event  (256*16bits/event)			
									// ¡Á¡Á¡Á¡Á¡Á¡Á¡Á¡Á¡Á¡Á¡Á¡Á¡Á¡Á¡Á¡Á¡Á¡Á¡Á¡Á¡Á¡Á¡Á¡Á¡Á¡Á¡Á¡Á¡Á¡Á¡Á¡Á¡Á¡Á¡Á¡Á¡Á¡Á¡Á¡Á¡Á¡Á¡Á¡Á¡Á¡Á¡Á¡Á¡Á¡Á¡Á¡Á¡Á¡Á¡Á¡Á¡Á¡Á¡Á¡Á¡Á¡Á¡Á¡Á¡Á¡Á¡Á¡Á¡Á¡Á¡Á¡Á¡Á¡Á¡Á
									if(r_col_addr ==9'd256) begin									    
										       r_col_addr <= 9'd0;											    
										       if(r_row_addr ==13'h1fff) begin
											       r_row_addr  <= 13'b0;
											       r_bank_addr <= r_bank_addr +2'b1;
	  									       end											 
										       else r_row_addr <= r_row_addr + 13'b1;											 
											end
									else r_col_addr <= 9'd256;
									
						            sdram_cmd_r  <= `CMD_B_STOP;
									sdram_ba_r   <= 2'b11;
									sdram_addr_r <= 13'h1fff;	
								end									
							default: begin
									sdram_cmd_r  <= `CMD_NOP;
									sdram_ba_r   <= 2'b11;
									sdram_addr_r <= 13'h1fff;	
								end
						endcase
				default: begin
							sdram_cmd_r  <= `CMD_NOP;
							sdram_ba_r   <= 2'b11;
							sdram_addr_r <= 13'h1fff;	
						end
			endcase
end

endmodule

