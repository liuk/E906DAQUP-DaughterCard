`timescale 1ns / 1ps
////////////////////////////////////////////////////////////////////////////////
// Module Name	: sdram_control
// Description	: SDRAM  state control for Init, Refresh, Write/Read 
////////////////////////////////////////////////////////////////////////////////

module sdram_ctrl(
				clk,
				rst_n,
				rd_req,
				wr_req,
				init_state,
				work_state,
				sdram_wr_ack,
				sdram_rd_ack,
				sdram_init_done,
				cnt_clk,
				rd_bstop
			 );
			
input clk;
input rst_n;				
input rd_req;     
input wr_req;
input rd_bstop;

// Internal Interface
output[4:0] init_state;	
output[3:0] work_state;	
output[8:0] cnt_clk;	  
output sdram_wr_ack;	
output sdram_rd_ack;

// indicatior
wire done_100us;		   // 100us after powup,   
output sdram_init_done;	   // SDRAM  init done
//wire sdram_busy;		   // SDRAM in working state
reg  sdram_ref_req;		   // SDRAM  auto-refresh request 
wire sdram_ref_ack;		   // SDRAM  auto-refresh acknowledge 

`include "D:/WorkSpace/FermiLab/FPGA/DaughterCardRWtest-3-1/src/sdram/sdr_para.v"

// SDRAM timing delay para.    
// @53 MHZ  18.9ns per clock
// tRCD-tRP-CL 3-3-3 @133MHZ     set as longer than the minimun timing requirement 
parameter	    TRP_CLK		= 9'd3,         // TRP =20ns pre-charge effective period
				TRFC_CLK	= 9'd4,     	// TRFC =66ns pre-refresh period
				TRCD_CLK	= 9'd3,     	// TRCD=20ns row select period
				TCL_CLK		= 9'd3,		    // TCL 3CLK@133MHZ  20ns
				
				TMRD_CLK	   = 9'd2,     	// model reg setting period 2CK 				
				TDAL_CLK	   = 9'd5,	    // Write waiting 5CLK  			
				TREAD_CLK	   = 9'd252,	// 256*16bit per event        
				TWRITE_CLK	   = 9'd254;  	   				


//------------------------------------------------------------------------------
// 100us counting after power up--> done_100us=1
// 7000 counts   @53 MHZ      132us
//------------------------------------------------------------------------------

reg[14:0] cnt_100us; 
always @ (posedge clk or negedge rst_n) 
	if(!rst_n)                    cnt_100us <= 15'd0;
	else if(cnt_100us < 15'd7000) cnt_100us <= cnt_100us+1'b1;	

assign done_100us = (cnt_100us == 15'd7000);	//done_100us=1，keep high 

//------------------------------------------------------------------------------
// SDRAM timing delay counter 
//------------------------------------------------------------------------------
reg[8:0] cnt_clk_r;	     // Counting clock 
reg      cnt_rst_n;		 // Reset counting clock 

always @ (posedge clk or negedge rst_n) 
	if(!rst_n) cnt_clk_r <= 9'd0;			
	else if(!cnt_rst_n)      cnt_clk_r <= 9'd0;	               
	else                     cnt_clk_r <= cnt_clk_r+1'b1;	   
	
assign cnt_clk = cnt_clk_r;			

//------------------------------------------------------------------------------
//SDRAM initial state machine
//------------------------------------------------------------------------------
reg[4:0] init_state_r;	

always @ (posedge clk or negedge rst_n)
	if(!rst_n) init_state_r <= `I_NOP;
	else 
		case (init_state_r)
				`I_NOP: 	init_state_r <= done_100us ? `I_PRE:`I_NOP;		    //Wait 100us 
				`I_PRE: 	init_state_r <= (TRP_CLK == 0) ? `I_AR1:`I_TRP;	    //Pre-charge 
				`I_TRP: 	init_state_r <= (cnt_clk_r	== TRP_CLK) ? `I_AR1:`I_TRP;			 //Waiting for Pre-charge
				`I_AR1: 	init_state_r <= (TRFC_CLK == 0) ? `I_AR2:`I_TRF1;	 //1st refersh
				`I_TRF1:	init_state_r <= (cnt_clk_r	== TRFC_CLK) ? `I_AR2:`I_TRF1;		 //Waiting for the end of 1st refersh
				`I_AR2: 	init_state_r <= (TRFC_CLK == 0) ? `I_AR3:`I_TRF2;   //2nd refersh
				`I_TRF2:	init_state_r <= (cnt_clk_r	== TRFC_CLK) ? `I_AR3:`I_TRF2; 		 //Waiting for the end of 2nd refersh
				`I_AR3: 	init_state_r <= (TRFC_CLK == 0) ? `I_AR4:`I_TRF3;   //3rd refersh
				`I_TRF3:	init_state_r <= (cnt_clk_r	== TRFC_CLK) ? `I_AR4:`I_TRF3;		 //Waiting for the end of 3rd refersh
				`I_AR4: 	init_state_r <= (TRFC_CLK == 0) ? `I_AR5:`I_TRF4;   //4th refersh
				`I_TRF4:	init_state_r <= (cnt_clk_r	== TRFC_CLK) ? `I_AR5:`I_TRF4; 		 //Waiting for the end of 4th refersh
				`I_AR5: 	init_state_r <= (TRFC_CLK == 0) ? `I_AR6:`I_TRF5;   //5th refersh
				`I_TRF5:	init_state_r <= (cnt_clk_r	== TRFC_CLK) ? `I_AR6:`I_TRF5;		 //Waiting for the end of 5th refersh
				`I_AR6: 	init_state_r <= (TRFC_CLK == 0) ? `I_AR7:`I_TRF6;   //6th refersh
				`I_TRF6:	init_state_r <= (cnt_clk_r	== TRFC_CLK) ? `I_AR7:`I_TRF6;	    //Waiting for the end of 6th refersh
				`I_AR7: 	init_state_r <= (TRFC_CLK == 0) ? `I_AR8:`I_TRF7;   //7th refersh	
				`I_TRF7: init_state_r <= (cnt_clk_r	== TRFC_CLK) ? `I_AR8:`I_TRF7;		 //Waiting for the end of 7th refersh
				`I_AR8: 	init_state_r <= (TRFC_CLK == 0) ? `I_MRS:`I_TRF8;	 //8th refersh
				`I_TRF8:	init_state_r <= (cnt_clk_r	== TRFC_CLK) ? `I_MRS:`I_TRF8;		 //Waiting for the end of 8th refersh
				`I_MRS:	init_state_r <= (TMRD_CLK == 0) ? `I_DONE:`I_TMRD;  //MRS setting	
				`I_TMRD:	init_state_r <= (cnt_clk_r	== TMRD_CLK) ? `I_DONE:`I_TMRD;		 //Waiting for the MRS
				`I_DONE:	init_state_r <= `I_DONE;		                      //SDRAM Init Done!
				default: init_state_r <= `I_NOP;
				endcase

assign init_state = init_state_r;
assign sdram_init_done = (init_state_r == `I_DONE);		// flag for SDRAM Init Done 


//------------------------------------------------------------------------------
//  7.5us counting， refresh  for  8192 row every 64ms  
//  Uplimit time for data not lost in the memory 64ms    64ms/8192 = 7.8125us
//  clock @53 MHZ,  counting 250
//------------------------------------------------------------------------------	 
reg[10:0] cnt_7us;	//counting reg

always @ (posedge clk or negedge rst_n)
	if(!rst_n)                       cnt_7us <= 11'd0;
    else if(cnt_7us < 11'd249)       cnt_7us <= cnt_7us+1'b1;	 
	else                             cnt_7us <= 11'd0;	          // reset 

always @ (posedge clk or negedge rst_n)
	if(!rst_n)                         sdram_ref_req <= 1'b0;
	else if(cnt_7us == 11'd248)        sdram_ref_req <= 1'b1;	   // generate request for self-refresh  
	else if(sdram_ref_ack)             sdram_ref_req <= 1'b0;	   // self-refresh has been ack.ed---reset

		
	
//------------------------------------------------------------------------------
//  SDRAM read/write/self-refresh state 
//------------------------------------------------------------------------------
reg[3:0] work_state_r;	
reg      sys_r_wn;	   // SDRAM read/write control    0-write    1-read & else
reg      rw_sign;	


always @ (posedge clk or negedge rst_n) begin
	if(!rst_n) work_state_r <= `W_IDLE;
	else 
		case (work_state_r)
 			`W_IDLE:	if (wr_req & sdram_init_done) begin
								work_state_r <= `W_ACTIVE_w; // write SDRAM， next--row active state
								sys_r_wn <= 1'b0;
							   end	
						else if (rd_req & sdram_init_done) begin 																	
								work_state_r <= `W_ACTIVE_r; // read SDRAM，  next--row active state
								sys_r_wn <= 1'b1;	
								end
						else if(sdram_ref_req & sdram_init_done) begin
								work_state_r <= `W_AR; 		// Period Refresh Request 
								sys_r_wn <= 1'b1;           
							end 		
						else begin 
								work_state_r <= `W_IDLE;
								sys_r_wn <= 1'b1;
							end		
			//row active
			`W_ACTIVE_r:   work_state_r <= `W_TRCD;      // Send active command with Bank and Row addr. 						  									              
            `W_ACTIVE_w:   work_state_r <= `W_TRCD;	 
							
			`W_TRCD:	 if(cnt_clk_r	== TRCD_CLK-1)  begin                           // wait TRCD
						 	      if(sys_r_wn) work_state_r <= `W_READ;
						 	      else work_state_r <= `W_WRITE;
						 	 end
						 else work_state_r <= `W_TRCD;
			// SDRAM: Read data state
			`W_READ:  	  work_state_r <= `W_CL;						     // Send Read command and col address
			`W_CL:		  work_state_r <= (`end_tcl) ? `W_RD:`W_CL;			 // W_CL  wait latency 3 CLK   
			`W_RD:		  work_state_r <= ((`end_tread)| rd_bstop) ? `W_B_R_STOP:`W_RD;	 
			`W_B_R_STOP:  work_state_r <= `W_RWAIT;
			`W_RWAIT:	  work_state_r <= (`end_trwait) ? `W_AR:`W_RWAIT;  
			// SDRAM: Write data state
			`W_WRITE:	  work_state_r <= `W_WD;			                    // Send Write command and col address
			`W_WD:		  work_state_r <= (`end_twrite) ? `W_B_W_STOP:`W_WD;     
			`W_B_W_STOP:  work_state_r <= `W_TDAL;
			`W_TDAL:	  work_state_r <= (`end_tdal) ? `W_AR:`W_TDAL;    // W_TDAL	 wait for the end of writing data and refresh 
			// SDRAM: Auto-refresh 
			`W_AR:	 	  work_state_r <= (TRFC_CLK == 0) ? `W_IDLE:`W_TRFC; // auto-refresh
			`W_TRFC:	  work_state_r <= (`end_trfc) ? `W_IDLE:`W_TRFC;     // Refresh wait
			default: 	  work_state_r <= `W_IDLE;
			endcase
end

assign work_state = work_state_r;		// SDRAM work state reg
//assign sdram_busy = (sdram_init_done && work_state_r == `W_IDLE) ? 1'b0:1'b1;	// SDRAM busy flag
assign sdram_ref_ack = (work_state_r == `W_AR);		// SDRAM refresh ack flag

assign sdram_wr_ack = ((work_state == `W_TRCD) & ~sys_r_wn & (cnt_clk_r	== TRCD_CLK-1)) | (work_state == `W_WRITE) | (work_state == `W_WD) ;	
//assign sdram_wr_ack = (work_state == `W_WRITE) | (work_state == `W_WD) ;		   
assign sdram_rd_ack = (work_state_r == `W_RD) &(cnt_clk_r >= 9'd1) |  (work_state == `W_B_R_STOP) | (work_state == `W_RWAIT & cnt_clk <= 9'd2)  ;	//读SDRAM响应信号
//assign sys_dout_rdy = (work_state_r == `W_RD && `end_tread);		// SDRAM数据输出完成标志


// ---------------------------------------------------------------------------
// Logic to decide when to reset the counter to 0
// -----------------------------------------------------------------------------
always @ (init_state_r or work_state_r or cnt_clk_r) begin
	case (init_state_r)
	    	`I_NOP:	 cnt_rst_n <= 1'b0;
	   		`I_PRE:	 cnt_rst_n <= (TRP_CLK != 0);            //预充电延时计数启动	
	   		`I_TRP:	 cnt_rst_n <= (`end_trp) ? 1'b0:1'b1;	 //等待预充电延时计数结束后，清零计数器
	    	`I_AR1,`I_AR2,`I_AR3,`I_AR4,`I_AR5,`I_AR6,`I_AR7,`I_AR8:
	         		 cnt_rst_n <= (TRFC_CLK != 0);			       //自刷新延时计数启动
	    	`I_TRF1,`I_TRF2,`I_TRF3,`I_TRF4,`I_TRF5,`I_TRF6,`I_TRF7,`I_TRF8:
	         		 cnt_rst_n <= (`end_trfc) ? 1'b0:1'b1;	   //等待自刷新延时计数结束后，清零计数器
			`I_MRS:	 cnt_rst_n <= (TMRD_CLK != 0);			      //模式寄存器设置延时计数启动
			`I_TMRD: cnt_rst_n <= (`end_tmrd) ? 1'b0:1'b1;	   //等待自刷新延时计数结束后，清零计数器
		   	`I_DONE:
	      		case (work_state_r)
						`W_IDLE:	    cnt_rst_n <= 1'b0;
						`W_ACTIVE_r: 	cnt_rst_n <= (TRCD_CLK == 0) ? 1'b0:1'b1;
						`W_ACTIVE_w: 	cnt_rst_n <= (TRCD_CLK == 0) ? 1'b0:1'b1;
						`W_TRCD:	    cnt_rst_n <= (`end_trcd) ? 1'b0:1'b1;
						`W_CL:		    cnt_rst_n <= (`end_tcl) ? 1'b0:1'b1;
						`W_RD:		    cnt_rst_n <= (`end_tread) ? 1'b0:1'b1;
						`W_RWAIT:	    cnt_rst_n <= (`end_trwait) ? 1'b0:1'b1;
						`W_WD:		    cnt_rst_n <= (`end_twrite) ? 1'b0:1'b1;
						`W_TDAL:	    cnt_rst_n <= (`end_tdal) ? 1'b0:1'b1;
						`W_TRFC:	    cnt_rst_n <= (`end_trfc) ? 1'b0:1'b1;
					default: cnt_rst_n <= 1'b0;
		         	endcase
		default: cnt_rst_n <= 1'b0;
		endcase
end

endmodule
