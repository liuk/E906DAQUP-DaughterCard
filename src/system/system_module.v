`timescale 1 ps / 1 ps

//  First test      data transfer                                                                    
//  use a signle FIFO      v1495-> daughter card FIFO -> v1495
//  connector   nOEF as the CMD,  low-active  
//  Separate the conn_f to in and out, so it's one-directional
//  CMD=0   conn_f_in[15]=0(E[31])   Write       conn_f_in  (E[31:16])  data input
//  CMD=0   conn_f_in[15]=1(E[31])   Read        conn_f_out (E[15:0])   data output 

// @clock 53 MHZ 

module system_module(
	 clk, 
	 sdram_clk,
	 rw_cmd,
	 conn_f_in,
	 conn_f_out, 
	 led1,
	 	 
	 sdram_cas_n,
	 sdram_cke,
	 sdram_cs_n,
	 sdram_ras_n,
	 
	 sdram_we_n,
	 sdram_ba,
	 sdram_addr,
	 sdram_data,	
     sdram_dqm
);

input clk;	
input rw_cmd; 
input[15:0]  conn_f_in;  
output[15:0] conn_f_out;
output led1;
output sdram_clk;

wire  [15:0] sys_data_in;
wire  [15:0] sys_data_out;
wire 		 sdram_wr_ack;
wire         sdram_rd_ack;
wire         sdram_init_done;

output sdram_cas_n;
output sdram_cke;
output sdram_cs_n;
output sdram_ras_n;

output          sdram_we_n;
output[1:0]	    sdram_ba;
output[12:0]	sdram_addr;
inout [15:0]	sdram_data;
output          sdram_dqm;

wire  clk_53m;
wire  sys_rst_n;
wire  rd_req;
wire  wr_req;
wire  rd_bstop;
	
sys_ctrl		uut_sysctrl(
					.clk(clk),
					.sys_rst_n(sys_rst_n),
					.clk_53m(clk_53m),
					.sdram_clk(sdram_clk)
					);	
					
cache_ctrl  uut_cache(					   					
					   .led1(led1),				
				       .clk(clk_53m),
				       .rst_n(sys_rst_n),
				       
				       .conn_f_in(conn_f_in),	
					   .conn_f_out(conn_f_out),
				       .sys_data_in(sys_data_in),
				       .sys_data_out(sys_data_out),
				       .sdram_init_done(sdram_init_done),
				       
				       .sdram_wr_ack(sdram_wr_ack),
				       .sdram_rd_ack(sdram_rd_ack),				      										       				       
				       .rd_req(rd_req),
				       .wr_req(wr_req),
				       .rd_bstop(rd_bstop),			         
				       .rw_cmd(rw_cmd)
					);

 
sdram_top		uut_sdramtop(				
							.clk(clk_53m),
							.rst_n(sys_rst_n),							
							.rd_req(rd_req),
							.wr_req(wr_req),
							
							.sys_data_in(sys_data_in),
							.sys_data_out(sys_data_out),
					    	.sdram_wr_ack(sdram_wr_ack),	
							.sdram_rd_ack(sdram_rd_ack),
							.sdram_init_done(sdram_init_done),
							
							.rd_bstop(rd_bstop),
							.sdram_cke(sdram_cke),
							.sdram_cs_n(sdram_cs_n),
							.sdram_ras_n(sdram_ras_n),
							.sdram_cas_n(sdram_cas_n),
							
							.sdram_we_n(sdram_we_n),
							.sdram_ba(sdram_ba),
							.sdram_addr(sdram_addr),
							.sdram_data(sdram_data),
							.sdram_dqm(sdram_dqm)
					);
						
endmodule