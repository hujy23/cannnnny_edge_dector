// New testbench, can be systh
`timescale 1 ns / 1 ns

`define MODE_GAUSSIAN	0
`define MODE_SOBEL		1
`define MODE_NMS		2
`define MODE_HYSTERESIS	3

`define DATA_WIDTH	8
`define REG_ROW		5
`define REG_COL		5

`define REG_GAUSSIAN	0
`define REG_GRADIENT	1
`define REG_DIRECTION	2
`define REG_NMS			3
`define REG_HYSTERESIS	4

`define WRITE_REGX	0
`define WRITE_REGY	1
`define WRITE_REGZ	2

`define DATA_WIDTH 	8

module newtestbench(AddrRegRow, AddrRegCol, bWE, bCE, InData, OutData,
	OPMode, bOPEnable, dReadReg, dWriteReg,	tclk, pclk, rst_b,
	weXG, weGxy, weThetaT, weGxyT, webGxyT,
	X_addr_, XG_addr_, Gxy_addr_, ThetaT_addr_, GxyT_addr_, bGxyT_addr_,
	X_douta, XG_douta, Gxy_douta, ThetaT_douta, GxyT_douta, bGxyT_douta
);

	output 	reg [2:0]			AddrRegRow, AddrRegCol;
	output	reg 				bWE, bCE;
	output 	[`DATA_WIDTH-1:0] 	InData;
	input	[`DATA_WIDTH-1:0] 	OutData;
	reg		[`DATA_WIDTH-1:0] 	InData;

	output 	reg [2:0]			OPMode;
	output 	reg					bOPEnable;
	output 	reg [3:0]			dReadReg, dWriteReg;

	input						tclk, pclk, rst_b;

	reg [7:0] cnt;
	reg [7:0] i,j,k,l,t;
	reg [2:0] intSignal;
	reg [7:0] rR,rG,rB;
	
	parameter		dWidth = 200;
	parameter		dHeight = 200;

	//out for display
	//memory write enable output(always disable when display)
	//output    wire            weX;
	output    reg            weXG;
	output    reg            weGxy;
	output    reg            weThetaT;
	output    reg            weGxyT;
	output    reg            webGxyT;
	//addr in
	input    wire  [15:0]     X_addr_;
	input    wire  [15:0]     XG_addr_;
	input    wire  [15:0]     Gxy_addr_;
	input    wire  [15:0]     ThetaT_addr_;
	input    wire  [15:0]     GxyT_addr_;
	input    wire  [15:0]     bGxyT_addr_;
	
	reg  [15:0]     X_addr;
	reg  [15:0]     XG_addr;
	reg  [15:0]     Gxy_addr;
	reg  [15:0]     ThetaT_addr;
	reg  [15:0]     GxyT_addr;
	reg  [15:0]     bGxyT_addr;
	
	assign X_addr_ = X_addr;
	assign XG_addr_ = XG_addr;
	assign Gxy_addr_ = Gxy_addr;
	assign ThetaT_addr_ = ThetaT_addr;
	assign GxyT_addr_ = GxyT_addr;
	assign bGxyT_addr_ = bGxyT_addr;
	//read out output
	output    wire [7:0]      X_douta;
	output    wire [7:0]      XG_douta;
	output    wire [7:0]      Gxy_douta;
	output    wire [23:0]     ThetaT_douta;
	output    wire [7:0]      GxyT_douta;
	output    wire [7:0]      bGxyT_douta;

	reg weTheta;
	reg webGxy;
	
	reg [15:0]     Theta_addr;
	reg [15:0]     bGxy_addr;
	
	wire [7:0]      Theta_douta;
	wire [7:0]      bGxy_douta;
	
	reg [7:0] XG_in;
	reg [7:0] Gxy_in;
	reg [7:0] Theta_in;
	reg [23:0] ThetaT_in;
	reg [7:0] GxyT_in;
	reg [7:0] bGxy_in;
	reg [7:0] bGxyT_in;
	
memX memX_01 (              //memX is created and initialed by ip.
			.clka(pclk),    // input wire clka
			.addra(X_addr),  // input wire [15 : 0] addra
			.douta(X_douta)  // output wire [7 : 0] douta
			);
dmem memXG (.clk(pclk),
			.we(weXG),
			.a(XG_addr),
			.wd(XG_in),
			.rd(XG_douta)
			);
dmem memGxy (.clk(pclk),
			.we(weGxy),
			.a(Gxy_addr),
			.wd(Gxy_in),
			.rd(Gxy_douta)
			);
dmem memTheta (.clk(pclk),
			.we(weTheta),
			.a(Theta_addr),
			.wd(Theta_in),
			.rd(Theta_douta)
			);
dmem membGxy (.clk(pclk),
			.we(webGxy),
			.a(bGxy_addr),
			.wd(bGxy_in),
			.rd(bGxy_douta)
			);

big_dmem memThetaT (.clk(pclk),
			.we(weThetaT),
			.a(ThetaT_addr),
			.wd(ThetaT_in),
			.rd(ThetaT_douta) // output wire [23 : 0] douta
			);
dmem memGxyT (.clk(pclk),
			.we(weGxyT),
			.a(GxyT_addr),
			.wd(GxyT_in),
			.rd(GxyT_douta)
			);
dmem membGxyT (.clk(pclk),
			.we(webGxyT),
			.a(bGxyT_addr),
			.wd(bGxyT_in),
			.rd(bGxyT_douta)
			);

always @(posedge tclk or negedge rst_b)
begin
	if(!rst_b)
		cnt <= 0;
	else
		cnt <= cnt + 1;
end

//Read image function is no need. 
//Because we initial it in memX by Vivado.
//0.OutputOrigin function is no need. 
//Because we use vga which displays R=G=B=high 4 bits of [7:0]memX.

always @(posedge tclk or negedge rst_b)
begin
	if(!rst_b)
	begin
		dReadReg <= `REG_GAUSSIAN;
		dWriteReg <= `WRITE_REGX;
		OPMode <= `MODE_GAUSSIAN;
		bOPEnable <= 1;
		intSignal <= 0;
		k <= -2;
		l <= -2;
		i <= 0;
		j <= 0;
		bWE <= 0; // write mode
		bCE <= 1; // disable canny memory operation
	end
	else
	begin
		if(OPMode == `MODE_GAUSSIAN)//------------------------------
		begin
			if(intSignal == 0)
			begin
				//send_5x5(i,j);
				if(cnt == 1)
				begin
					if(i<2 || j<2 || i>=dHeight-2 || j>= dWidth-2)
					begin
						weXG <= 1;
						XG_addr <= i*dWidth+j;
						X_addr <= i*dWidth+j;
						XG_in <= X_douta;
					end
					else
					begin
						AddrRegRow <= k + 2;
						AddrRegCol <= l + 2;
						X_addr <= (i+k)*dWidth+(j+l);
						InData <= X_douta;
					end
				end
				else if(cnt == 2)
					bCE <= 0;
				else if(cnt == 3)
					bCE <= 1;
				else if(cnt == 4)
				begin
					cnt <= 0;
					l <= l+1;
				end	
				
				if(l == 3) //2+1
				begin
					l <= -2;
					k <= k+1;
				end
				if(k == 3) //2+1
				begin
					k <= -2;
					intSignal <= 1;
					cnt <= 0;
				end				
			end // of if(intSignal == 0)
			else if(intSignal == 1)
			begin
				// read_pixel(i,j);
				if(cnt == 1)
					bOPEnable <= 0;
				else if(cnt == 6)
				begin
					bOPEnable <= 1;
					bWE <= 1; // read mode
					bCE <= 1; // disable canny memory operation
				end
				else if(cnt == 7)
					bCE <= 0; // enable canny memory operation
				else if(cnt == 8)
				begin // read data
					weXG <= 1;
					XG_addr <= i*dWidth+j;
					XG_in <= OutData; 
				end
				else if(cnt == 9)
				begin
					bCE <= 1; // disable canny memory operation
				end
				else if(cnt == 10)
				begin
					cnt <= 0;
					j <= j+1;
				end
				
				if(j == dWidth) // not dWidth+1
				begin
					j <= 0;
					i <= i+1;
				end
				if(i == dHeight)
				begin //prepare for next mode
					//dReadReg has two value.
					dWriteReg <= `WRITE_REGX;
					OPMode <= `MODE_SOBEL;
					bOPEnable <= 1;
					intSignal <= 0;
					k <= -1;
					l <= -1; 
					i <= 0;
					j <= 0;
					bWE <= 0; // write mode
					bCE <= 1; // disable canny memory operation
					cnt <= 0;
				end
			end // of else if(intSignal == 1)
		end //of if(OPMode == `MODE_GAUSSIAN)
		//1.OutputGauss function is no need. 
		//Because we use vga which displays R=G=B=high 4 bits of [7:0]memXG.
		else if(OPMode == `MODE_SOBEL)//----------------------------
		begin
			if(intSignal == 0)
			begin
				//send_3x3(i,j);
				if(cnt == 1)
				begin
					if(i+k<0 || j+l<0 || i+k>=dHeight || j+l>= dWidth)
						InData <= 0;
					else
					begin
						AddrRegRow <= k + 1;
						AddrRegCol <= l + 1;
						XG_addr <= (i+k)*dWidth+(j+l);
						InData <= XG_douta;
					end
				end
				else if(cnt == 2)
					bCE <= 0;
				else if(cnt == 3)
					bCE <= 1;
				else if(cnt == 4)
				begin
					cnt <= 0;
					l <= l+1;
				end	
				
				if(l == 2) //1+1
				begin
					l <= -1;
					k <= k+1;
				end
				if(k == 2) //1+1
				begin
					k <= -1;
					intSignal <= 1;
					cnt <= 0;
				end				
			end // of if(intSignal == 0)
			else if(intSignal == 1)
			begin
				// read_pixel(i,j);
				if(cnt == 1)
					bOPEnable <= 0;
				else if(cnt == 6)
				begin
					bOPEnable <= 1;
					dReadReg <= `REG_GRADIENT;
					bWE <= 1; // read mode
					bCE <= 1; // disable canny memory operation
				end
				else if(cnt == 7)
					bCE <= 0; // enable canny memory operation
				else if(cnt == 8)
				begin // read data
					weGxy <= 1;
					Gxy_addr <= i*dWidth+j;
					Gxy_in <= OutData; 
				end
				else if(cnt == 9)
				begin
					bCE <= 1; // disable canny memory operation
				end
				else if(cnt == 10)
				begin
					dReadReg <= `REG_DIRECTION;
					bWE <= 1;
					bCE <= 1;
				end
				else if(cnt == 11)
					bCE <= 0; // enable canny memory operation
				else if(cnt == 12)
				begin // read data
					weTheta <= 1;
					Theta_addr <= i*dWidth+j;
					Theta_in <= OutData; 
				end
				else if(cnt == 13)
				begin
					bCE <= 1; // disable canny memory operation
				end
				else if(cnt == 14)
				begin
					cnt <= 0;
					j <= j+1;
				end
				
				if(j == dWidth) // not dWidth+1
				begin
					j <= 0;
					i <= i+1;
				end
				if(i == dHeight)
				begin //prepare for next mode
					cnt <= 0;
					intSignal <= 2;
					i <= 0;
					j <= 0;
				end
			end // of else if(intSignal == 1)
			//2.OutputGradient function is no need. 
			//Because we use vga which displays R=G=B=high 4 bits of [7:0]memGxy.
			//3.OutputDirection function is need. 
			//Because [7:0]memTheta stores Theta, not color, we need turn them into color to display.
			else if(intSignal == 2)
			begin
				Theta_addr <= (dHeight-i-1)*dWidth+j;
				if(ThetaT_douta == 90) begin
					rR <= 8'hff; rG <= 8'h00; rB <= 8'hff;
				end
				else if(ThetaT_douta == 135) begin
					rR <= 8'hff; rG <= 8'h00; rB <= 8'h00;
				end
				else if(ThetaT_douta == 0) begin
					rR <= 8'h00; rG <= 8'hff; rB <= 8'h00;
				end
				else begin // if(ThetaT_douta == 45) begin
					rR <= 8'h00; rG <= 8'h00; rB <= 8'hff;
				end
//				assign rR = (Theta_douta == 90 || Theta_douta == 45) ? 8'hff : 8'h00;
//				assign rG = (Theta_douta == 90 || Theta_douta == 135) ? 8'hff : 8'h00;
//				assign rB = (Theta_douta == 0) ? 8'hff : 8'h00;
				weThetaT <= 1;
				ThetaT_addr <= (dHeight-i-1)*dWidth+j;
				ThetaT_in <= {rR,rG,rB};
				j <= j+1;
				if(j == dWidth) // not dWidth+1
				begin
					j <= 0;
					i <= i+1;
				end
				if(i == dHeight)
				begin //prepare for next mode
					dReadReg <= `REG_NMS;
					//dWriteReg has two possible value.
					OPMode <= `MODE_NMS;
					bOPEnable <= 1;
					intSignal <= 0;
					k <= -1;
					l <= -1;
					i <= 0;
					j <= 0;
					t <= 0;
					bWE <= 0;
					bCE <= 1;
					cnt <= 0;
				end
			end // of else if(intSignal == 2)
		end //of if(OPMode == `MODE_SOBEL)
		else if(OPMode == `MODE_NMS)
		begin
			if(intSignal == 0)
			begin
				if(t==0)
					dWriteReg <= `WRITE_REGX;
				else
					dWriteReg <= `WRITE_REGY;
				//send_3x3(i,j);
				if(cnt == 1)
				begin
					if(i+k<0 || j+l<0 || i+k>=dHeight || j+l>= dWidth)
						InData <= 0;
					else
					begin
						AddrRegRow <= k + 1;
						AddrRegCol <= l + 1;
						if(t == 0) begin
							Gxy_addr <= (i+k)*dWidth+(j+l);
							InData <= Gxy_douta;
						end
						else begin
							Theta_addr <= (i+k)*dWidth+(j+l);
							InData <= Theta_douta;
						end
					end
				end
				else if(cnt == 2)
					bCE <= 0;
				else if(cnt == 3)
					bCE <= 1;
				else if(cnt == 4)
				begin
					cnt <= 0;
					l <= l+1;
				end	
				
				if(l == 2) //1+1
				begin
					l <= -1;
					k <= k+1;
				end
				if(k == 2) //1+1
				begin
					k <= -1;
					t <= t+1;
				end
				if(t == 2)
				begin
					intSignal <= 1;
					cnt <= 0;
				end	
			end // of if(intSignal == 0)
			else if(intSignal == 1)
			begin
				// read_pixel(i,j);
				if(cnt == 1)
					bOPEnable <= 0;
				else if(cnt == 6)
				begin
					bOPEnable <= 1;
					bWE <= 1; // read mode
					bCE <= 1; // disable canny memory operation
				end
				else if(cnt == 7)
					bCE <= 0; // enable canny memory operation
				else if(cnt == 8)
				begin // read data
					weGxy <= 1;
					Gxy_addr <= i*dWidth+j;
					Gxy_in <= OutData; 
					weGxyT <= 1;              //
					GxyT_addr <= i*dWidth+j;  //
					GxyT_in <= OutData;       // in order of display.
				end
				else if(cnt == 9)
				begin
					bCE <= 1; // disable canny memory operation
				end
				else if(cnt == 10)
				begin
					cnt <= 0;
					j <= j+1;
				end
				
				if(j == dWidth) // not dWidth+1
				begin
					j <= 0;
					i <= i+1;
				end
				if(i == dHeight)
				begin //prepare for next mode
					dReadReg <= `REG_HYSTERESIS;
					//dWriteReg has two value.
					OPMode <= `MODE_HYSTERESIS;
					bOPEnable <= 1;
					intSignal <= 0;
					k <= -1;
					l <= -1; 
					i <= 0;
					j <= 0;
					t <= 0;
					bWE <= 0; // write mode
					bCE <= 1; // disable canny memory operation
					cnt <= 0;
				end
			end // of else if(intSignal == 1)
		end // of if(OPMode == `MODE_NMS)
		//4.OutputNMS function is no need. 
		//Because we use vga which displays R=G=B=high 4 bits of [7:0]memGxyT.
		else if(OPMode == `MODE_HYSTERESIS)
		begin
			if(intSignal == 0)
			begin
				if(t==0)
					dWriteReg <= `WRITE_REGX;
				else if(t==1)
					dWriteReg <= `WRITE_REGY;
				else
					dWriteReg <= `WRITE_REGZ;
				//send_3x3(i,j);
				if(cnt == 1)
				begin
					if(i+k<0 || j+l<0 || i+k>=dHeight || j+l>= dWidth)
						InData <= 0;
					else
					begin
						AddrRegRow <= k + 1;
						AddrRegCol <= l + 1;
						if(t == 0) begin
							Gxy_addr <= (i+k)*dWidth+(j+l);
							InData <= Gxy_douta;
						end
						else if(t == 1) begin
							Theta_addr <= (i+k)*dWidth+(j+l);
							InData <= Theta_douta;
						end
						else begin
							bGxy_addr <= (i+k)*dWidth+(j+l);
							InData <= bGxy_douta;
						end
					end
				end
				else if(cnt == 2)
					bCE <= 0;
				else if(cnt == 3)
					bCE <= 1;
				else if(cnt == 4)
				begin
					cnt <= 0;
					l <= l+1;
				end	
				
				if(l == 2) //1+1
				begin
					l <= -1;
					k <= k+1;
				end
				if(k == 2) //1+1
				begin
					k <= -1;
					t <= t+1;
				end
				if(t == 3)
				begin
					intSignal <= 1;
					cnt <= 0;
				end	
			end // of if(intSignal == 0)
			else if(intSignal == 1)
			begin
				// read_pixel(i,j);
				if(cnt == 1)
					bOPEnable <= 0;
				else if(cnt == 6)
				begin
					bOPEnable <= 1;
					bWE <= 1; // read mode
					bCE <= 1; // disable canny memory operation
				end
				else if(cnt == 7)
					bCE <= 0; // enable canny memory operation
				else if(cnt == 8)
				begin // read data
					webGxy <= 1;
					bGxy_addr <= i*dWidth+j;
					bGxy_in <= OutData; 
				end
				else if(cnt == 9)
				begin
					bCE <= 1; // disable canny memory operation
				end
				else if(cnt == 10)
				begin
					cnt <= 0;
					j <= j+1;
				end
				
				if(j == dWidth) // not dWidth+1
				begin
					j <= 0;
					i <= i+1;
				end
				if(i == dHeight)
				begin
					intSignal <= 2;
					cnt <= 0;
					i <= 0;
					j <= 0;
				end
			end // of else if(intSignal == 1)
			//5.OutputHysteresis function is need. 
			//Because [7:0]membGxy stores 1 or 0, not color, we need turn them into color to display.
			else if(intSignal == 2)
			begin
				bGxy_addr <= (dHeight-i-1)*dWidth+j;
				if(bGxy_douta != 0) begin
					rR <= 8'hff;
				end
				else begin
					rR <= 8'h00;
				end
				webGxyT <= 1;
				bGxyT_addr <= (dHeight-i-1)*dWidth+j;
				bGxyT_in <= rR;
				j <= j+1;
				if(j == dWidth) // not dWidth+1
				begin
					j <= 0;
					i <= i+1;
				end
				if(i == dHeight)
				begin //Finally, there is no next mode to prepare for. I'm going mad. I love EDA, I love canny , I love Jun Wang. Thanks.
					intSignal <= intSignal;
					weXG <= 0;
					weGxy <= 0;
					weGxyT <= 0;
					weTheta <= 0;
					weThetaT <= 0;
					webGxy <= 0;
					webGxyT <= 0;
				end			
			end // of else if(intSignal == 2)
		end // of if(OPMode == `MODE_HYSTERESIS)
	end // of else of if(!rst_b)

end // of always
endmodule
