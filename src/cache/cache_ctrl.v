module cache_ctrl(			
                clk,  
                rst_n,	 	
				conn_f_in,
			    conn_f_out,							
				led1,				
				rw_cmd,	
				rd_bstop,
				
				sdram_wr_ack,
				sdram_rd_ack,
			    sdram_init_done,
			    
				sys_data_in,
				sys_data_out,

				rd_req,
				wr_req			
			);

input 			  clk;
input             rst_n;
input[15:0]       conn_f_in;
output[15:0]      conn_f_out;
output[15:0] 	  sys_data_in;		   // wrFIFO output data bus
input[15:0] 	  sys_data_out;	       // rFIFO  input  data bus
input             sdram_init_done;

output            rd_req;           // Write/Read Delayed command sent to SDRAM
output            wr_req;

input             rw_cmd;
output    		  led1;
input             rd_bstop;

input 			  sdram_wr_ack;	   // SDRAM write response signal 
input             sdram_rd_ack;       // SDRAM read  response signal 

wire[7:0]         wrf_use;			//  FIFO Used Words [0,256]  
wire[7:0]         rdf_use;  
wire              w_sclr;
wire              r_sclr;

//------------------------------------------------
// wr v1495 E PORT -> daughCard wFIFO -> SDRAM            first wr_reqr to wFIFO,  then wr_reqr_delay to SDRAM
// rd        SDRAM -> daughCard rFIFO -> v1495 E PORT     first rd_reqr to SDRAM, then rd_reqr_delat to rFIFO 
reg              wr_reqr;    //  Write/Read Delayed command sent to FIFO
reg              wr_reqr1;
reg              wr_reqr2;

reg              rd_reqr;
reg              wr_reqr_d;  //Send out wr_reqr_d to SDRAM after delay   Data should flow into wFIFO first 
reg              rd_reqr_d;  //Send out rd_reqr_d to rFIFO
reg              cnt_w_en;
reg              cnt_r_en;
reg              rd_bstop_fifo;
reg              rd_bstop_fifo_clr;

//----------------------------------------------------------------------------
reg[8:0] cnt_w;	   // Writing/Reading counting clock 
reg[8:0] cnt_r;   
reg cnt_rst_w;     // Clock reset 
reg cnt_rst_r;
reg w_sclr1;
reg r_sclr1;

always @(posedge clk or negedge rst_n)	
    if(!rst_n)             cnt_w  <= 9'b0;
	else if(!cnt_rst_w)    cnt_w  <= 9'b0;	   
	else if(cnt_w_en)      cnt_w  <= cnt_w+9'b1;	 

always @(posedge clk or negedge rst_n)
    if(!rst_n)             cnt_r  <= 9'b0;
	else if(!cnt_rst_r)    cnt_r  <= 9'b0;	
	else if(cnt_r_en)      cnt_r  <= cnt_r+9'b1;	 	

//-----------------------------------------------------------------------------
always @(posedge clk or negedge rst_n)
    if(!rst_n) begin
			wr_reqr1   <= 1'b0;			 
			wr_reqr_d <= 1'b0;			 
			cnt_w_en  <= 1'b0;			 
			cnt_rst_w <= 1'b1;			 			 
			end	
	else if(rw_cmd==0 && conn_f_in[15]==0 && sdram_init_done) begin
			w_sclr1    <= 1'b1;
			cnt_w_en   <= 1'b1;     
			wr_reqr1   <= 1'b1;     // wr_reqr sent to FIFO needs to keep high for 256 words                  
			end  		
// delayed rw request 
    else if (cnt_w >= 9'd5 && cnt_w < 9'd15) begin    // wr_reqr_d sent to SDRAM keeps high for 10 clocks 
			wr_reqr_d <= 1'b1;
			w_sclr1   <= 1'b0;
			end	       			
// stop after 256 counting	        
    else if (cnt_w == 9'd255)       // low down wr_reqr to FIFO after 256 counting
    	    wr_reqr1   <= 1'b0;
    else if (cnt_w == 9'd275) begin
            w_sclr1    <= 1'b1;
            cnt_rst_w  <= 1'b0;
            cnt_w_en   <= 1'b0;
            end                    			
	else  begin
			wr_reqr_d  <= 1'b0;         // doesn't need to keep high, so low down
			cnt_rst_w  <= 1'b1;
			w_sclr1    <= 1'b0;
			end

always @(posedge clk)				 // delay one clock
		    wr_reqr2 <= wr_reqr1;			
always @(posedge clk)				 // delay one clock
		    wr_reqr <= wr_reqr2;
 
always @(posedge clk or negedge rst_n)
    if(!rst_n) begin			
			rd_reqr   <= 1'b0;			
			rd_reqr_d <= 1'b0;			
			cnt_r_en  <= 1'b0;			
			cnt_rst_r <= 1'b1;
			r_sclr1   <= 1'b0;
			end	
  	else if(rw_cmd==0 && conn_f_in[15]==1 && sdram_init_done) begin
			rd_reqr  <= 1'b1;     
            cnt_r_en <= 1'b1;
            r_sclr1  <= 1'b1;  			
			end
    else if (cnt_r_en && cnt_r < 9'd10) begin
	        rd_reqr  <= 1'b1;
	        r_sclr1  <= 1'b0;
	        end			
    else if (cnt_r == 9'd19) 
            rd_reqr_d  <= 1'b1;                    
	else if (cnt_r == 9'd275 | rd_bstop_fifo )      // re_reqr_d keep high for 256 count
            rd_reqr_d  <= 1'b0;            
    else if (cnt_r == 9'd276 | rd_bstop_fifo_clr) begin    
            r_sclr1    <= 1'b1;
            cnt_rst_r  <= 1'b0;
			cnt_r_en   <= 1'b0;	
            end      			
	else  begin			
		    rd_reqr    <= 1'b0;  			
			cnt_rst_r  <= 1'b1;			
			r_sclr1    <= 1'b0;
			end

				
				
// R/W request to SDRAM
assign wr_req =  wr_reqr_d;
assign rd_req =  rd_reqr;
assign w_sclr =  w_sclr1;
assign r_sclr =  r_sclr1;				
			
			
				
// *****************************************************************************			
// Decide the time to stop the read request to rFIFO when receives the rd_bstop 
// *****************************************************************************	
reg bstop_en;
reg flag;

always @(posedge clk or negedge rst_n)
     if(!rst_n)   begin 
			      rd_bstop_fifo     <= 1'b0;
			      rd_bstop_fifo_clr <= 1'b0;
			      bstop_en  <= 1'b0; 
			      flag      <= 1'b1;			       
			      end  
     else if(rd_bstop & flag) begin          
                  bstop_en  <= 1'b1;
                  flag      <= 1'b0;
                  end			      
     else if(bstop_en && conn_f_out[15] ) begin
                  rd_bstop_fifo   <= 1'b1;
                  bstop_en <= 1'b0;
                  end
     else if(rd_bstop_fifo) begin 
                  rd_bstop_fifo_clr <= 1'b1;
                  rd_bstop_fifo     <= 1'b0;
                  end
     else  begin  rd_bstop_fifo     <= 1'b0;
                  rd_bstop_fifo_clr <= 1'b0;
                  flag  <= 1'b1;
           end 			
				
				
//**************************************************
// Use LED for test 
//****************************************************
reg[25:0] cnt_led;	
always @(posedge clk or negedge rst_n)
      if(!rst_n)                                 cnt_led     <= 26'b0;	
      else if(rd_req |  wr_req )                 cnt_led[25] <= 1'b1;	
      else if(cnt_led[25])                       cnt_led     <= cnt_led + 1'b1;	
 

reg[28:0] cnt_led2;	
always @(posedge clk or negedge rst_n)
      if(!rst_n)                     cnt_led2   <=  29'b0;		
      else                           cnt_led2   <=  cnt_led2 + 1'b1;	
      
assign led1   =  cnt_led[25] | cnt_led2[28];	
//*****************************************************
      
			
wfifo			uut_wrfifo(
					.data(conn_f_in[15:0]),        // data in 
					.rdreq(sdram_wr_ack),		   // request of FIFO->SDRAM 			
					.clock(clk),
					.wrreq(wr_reqr),               // write to FIFO request 
					.q(sys_data_in),               // data   ->SDRAM 
					.usedw(wrf_use),
					.sclr(w_sclr)					
					);	

					
rfifo			uut_rfifo(
					.data(sys_data_out),           // data    SDRAM->
					.rdreq(rd_reqr_d), 
					.clock(clk),
					.wrreq(sdram_rd_ack),
					.q(conn_f_out[15:0]),
					.usedw(rdf_use),
					.sclr(r_sclr)
					);		
	
endmodule
