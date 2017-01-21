`timescale 1ns / 1ps
////////////////////////////////////////////////////////////////////////////////
// Modified by : Xinkun Chu 
// Date        : 2016.08.09
// Project Name: daughter card
// Target Device: CycloneIII  EP3C40F484C8N
// SDRAM Device:  MT48LC16M16A2TG-75L
// Tool versions: Quartus II 11.0sp
// Description	: SDRAM-top control 				
////////////////////////////////////////////////////////////////////////////////

module sdram_top(
				clk,
				rst_n,
			    rd_req,
				wr_req,
				rd_bstop,
				sys_data_in,
				sys_data_out,
				sdram_init_done,
				sdram_cke,
				sdram_cs_n,
				sdram_ras_n,
				sdram_cas_n,
				sdram_we_n,
				sdram_ba,
				sdram_addr,
				sdram_data,
				sdram_wr_ack,
				sdram_rd_ack,
				sdram_dqm
			);

input clk;		//system clock input from pll£¬53MHz
input rst_n;	//sys_rst 

//internal connection 
input rd_req;  
input wr_req;
input[15:0]  sys_data_in;
output[15:0] sys_data_out;
output sdram_wr_ack;
output sdram_rd_ack;
output sdram_init_done;
output rd_bstop;

// FPGA & SDRAM hardware interface
output sdram_cke;			// SDRAM clock enable
output sdram_cs_n;			// SDRAM chip select
output sdram_ras_n;			// SDRAM row addr. enable 
output sdram_cas_n;			// SDRAM col addr. enable 
output sdram_we_n;			// SDRAM write enable
output[1:0]  sdram_ba;		// SDRAM L-Bank addr.
output[12:0] sdram_addr;	// SDRAM addr bus    
inout[15:0]  sdram_data;	// SDRAM data bus bi-direction
output sdram_dqm;

// SDRAM  internal interface
wire[4:0] init_state;	// SDRAM initial state reg.
wire[3:0] work_state;	// SDRAM work state reg.
wire[8:0] cnt_clk;		// clock count

// no need of dqm, but keep it low incase of unknown states on board
reg dqm;
always @ (posedge clk or negedge rst_n )
	if(!rst_n)   dqm <= 1'b1;
	else         dqm <= 1'b0;
assign 		sdram_dqm=dqm;
				
								
sdram_ctrl		module_001(		// SDRAM state control module
									.clk(clk),
									.rst_n(rst_n),
									.rd_req(rd_req),
									.wr_req(wr_req),
									.init_state(init_state),
									.work_state(work_state),
									.sdram_wr_ack(sdram_wr_ack),
									.sdram_rd_ack(sdram_rd_ack),
									.sdram_init_done(sdram_init_done),
									.cnt_clk(cnt_clk),
									.rd_bstop(rd_bstop)
								);

sdram_cmd		module_002(		// SDRAM command module
									.clk(clk),
									.rst_n(rst_n),								
									.sdram_cke(sdram_cke),		
									.sdram_cs_n(sdram_cs_n),	
									.sdram_ras_n(sdram_ras_n),	
									.sdram_cas_n(sdram_cas_n),	
									.sdram_we_n(sdram_we_n),	
									.sdram_ba(sdram_ba),			
									.sdram_addr(sdram_addr),										
									.init_state(init_state),	
									.work_state(work_state)
								);

sdram_wr_data	module_003(		// SDRAM data write/read module
									.clk(clk),
									.rst_n(rst_n),
									.sdram_data(sdram_data),
									.sys_data_in(sys_data_in),
									.sys_data_out(sys_data_out),
									.work_state(work_state),
									.cnt_clk(cnt_clk),
									.rd_bstop(rd_bstop)
								);
endmodule

