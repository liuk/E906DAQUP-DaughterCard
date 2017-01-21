//----------------------------------------------------------------
module datagene(
				clk_133m,
				rst_n,
				conn_f,	
				sdram_cmd
			);

input clk_133m;
input rst_n;	
output sdram_cmd; 
inout[31:0] conn_f;  


/**************************************************
// Delay about 150us for SDRAM to be ready
**************************************************/
reg[15:0] delay;	

always @(posedge clk_133m or negedge rst_n)
	if(!rst_n) 
			delay <= 16'b0;
	else if(delay < 16'd20000) 
			delay <= delay+1'b1;

wire delay_done = (delay == 16'd20000);	


//**************************************************	
// Counter
//**************************************************
reg[14:0] cntwr;	     // 2^15*7.5ns --about 250us
always @(posedge clk_133m or negedge rst_n)
	if(!rst_n) 
			cntwr <= 15'b0;
	else if(delay_done) 
			cntwr <= cntwr+1'b1;

reg[16:0] cntrd;	     // 2^17*7.5ns --about 1ms
always @(posedge clk_133m or negedge rst_n)
	if(!rst_n) 
			cntrd <= 17'b0;
	else if(delay_done) 
			cntrd <= cntrd+1'b1;
// **************************************************
// Read/Write command sent to SDRAM
// 
// **************************************************

reg wr_reqr;
reg rd_reqr;
reg cond_31;
		
always @(posedge clk_133m or negedge rst_n)
	if(!rst_n) begin
			wr_reqr  <= 1'b0;
			rd_reqr  <= 1'b0;
			cond_31  <= 1'b0;
			end
/*	else if(cntwr >= 15'h05 && cntwr < 15'h105 ) begin 
							wr_reqr  <= 1'b1;
							cond_31  <= 1'b1;
							end						
	else if(cntrd >= 17'h1f100 && cntrd < 17'h1f200 ) begin 
							rd_reqr  <= 1'b1;
							cond_31  <= 1'b1;
							end					
   else if(cntrd >= 17'h1f300 && cntrd < 17'h1f400 ) begin 
							rd_reqr  <= 1'b1;
							cond_31  <= 1'b1;
							end										
*/
   else if(cntwr == 15'h05 ) begin 
							wr_reqr  <= 1'b1;
							cond_31  <= 1'b1;
							end						
	else if(cntrd == 17'h1f100 ) begin 
							rd_reqr  <= 1'b1;
							cond_31  <= 1'b1;
							end					
   else if(cntrd == 17'h1f300 ) begin 
							rd_reqr  <= 1'b1;
							cond_31  <= 1'b1;
							end	
	else 	begin 
	      wr_reqr <= 1'b0;
			rd_reqr <= 1'b0;
			cond_31  <= 1'b0;	
			end

// conn_f[31]  0- write    1-read 			
assign sdram_cmd = wr_reqr | rd_reqr; 
assign conn_f[31] = cond_31? ~(~rd_reqr & wr_reqr) : 1'hz;  			
						
//**************************************************
// Generate data to write into SDRAM
//**************************************************
reg[15:0] wrf_dinr;
reg conn_din;

always @(posedge clk_133m or negedge rst_n)
	if(!rst_n) begin 
			wrf_dinr <= 16'b0;
			conn_din <= 1'b0;
			end
	else if((cntwr > 15'h05) && (cntwr <= 15'h105))
			begin	
				wrf_dinr <= wrf_dinr+1'b1;
			   conn_din <= 1'b1;	
			end					
   else  conn_din <= 1'b0;
			
assign conn_f[15:0]  =  conn_din? wrf_dinr:16'hzzzz;
assign conn_f[31:16] =  conn_din? 16'h0000:16'hzzzz;					

endmodule

