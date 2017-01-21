////////////////////////////////////////////////////////////////////////////////
// PLL control, SYSTEM RESET
////////////////////////////////////////////////////////////////////////////////
module sys_ctrl(
				clk,
				sys_rst_n,				
				clk_53m,
				sdram_clk
			);

input clk;		//FPAG input clock from v1495  SELE 53MHZ 

output clk_53m;	
output sdram_clk;
output sys_rst_n;	//system reset(0)

//----------------------------------------------
// System reset
//----------------------------------------------
reg[5:0] cnt_delay = 6'b0;    //counting clock
reg      sysrst_nr1;
always @(posedge clk)	
	if(cnt_delay < 6'd40) begin
	             cnt_delay <= cnt_delay + 1'b1;	
                 if (cnt_delay == 6'd30)  sysrst_nr1 <= 1'b0;
                 else                     sysrst_nr1 <= 1'b1;
           end 

assign sys_rst_n  = sysrst_nr1;
//----------------------------------------------
// PLL instantial
//----------------------------------------------
pll 		uut_PLL_ctrl(					
					.inclk0(clk),		 
					.c0(clk_53m),
					.c1(sdram_clk)     					 
				);
				
endmodule

