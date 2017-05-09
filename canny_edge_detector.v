`timescale 1ns/10ps

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

module CannyEdge(dAddrRegRow, dAddrRegCol, bWE, bCE, InData, OutData,
	OPMode, bOPEnable, dReadReg, dWriteReg,	tclk, rst_b);

	input 	[2:0]				dAddrRegRow, dAddrRegCol;
	input						bWE, bCE;
	input 	[`DATA_WIDTH-1:0] 	InData;
	output	[`DATA_WIDTH-1:0] 	OutData;
	reg		[`DATA_WIDTH-1:0] 	OutData;

	input 	[2:0]				OPMode;
	input 						bOPEnable;
	input 	[3:0]				dReadReg, dWriteReg;

	input						tclk, rst_b;

	reg 	[`DATA_WIDTH-1:0]	regX[0:24];	// Index = Row*5+Col // Index <= [5][5]
	reg 	[`DATA_WIDTH-1:0]	regY[0:24];	// Index = Row*5+Col // Index <= [5][5]
	reg 	[`DATA_WIDTH-1:0]	regZ[0:24];	// Index = Row*5+Col // Index <= [5][5]
	reg 	[`DATA_WIDTH-1:0]	gf[0:24];	// 5x5 Gaussian Filter

	// reg signed type can be used here to avoid warning while synthesis, also option +v2k should be used for simulation.

	reg 	[`DATA_WIDTH-1:0]	Out_gf, Out_gradient, Out_direction, Out_bThres;

	parameter		dThresHigh = 15;
	parameter		dThresLow = 10;
	parameter		dWidth = 200;
	parameter		dHeight = 200;

	// Internal Signal;
	reg			[31:0]	tpSum;
	reg			[1:0]	IntSignal;
	reg signed [31:0]	Gx, Gy, fGx, fGy;
	reg signed	[1:0]	dx, dy;
	integer	k;

	always @(tclk or rst_b)
	begin
		if(!rst_b)
		begin
			// $display("Initialize: Gauss Mask/Sobel Operators.\n");
			// Initialize Gaussian Mask 
			// Filter. Matlab : Approximation of fspecial('gaussian', 5, 1.4)*128
			gf[0] =1;  gf[1] =3;  gf[2]=4;   gf[3]=3;   gf[4]=1;
			gf[5] =3;  gf[6] =7;  gf[7]=10;  gf[8]=7;   gf[9]=3;
			gf[10]=4;  gf[11]=10; gf[12]=16; gf[13]=10; gf[14]=4;
			gf[15]=3;  gf[16]=7;  gf[17]=10; gf[18]=7;  gf[19]=3;
			gf[20]=1;  gf[21]=3;  gf[22]=4;  gf[23]=3;  gf[24]=1;
		end
	end

	// Apply operations for Edge Detection
	always @(posedge tclk or negedge rst_b)
	begin
		if(!rst_b) begin
			IntSignal <= 2'b00;
		end

		// Load data from Test Bench
		else if(bCE==1'b0 && bWE==1'b0) 
		begin
			if(dWriteReg == `WRITE_REGX)
				regX[dAddrRegRow*5+dAddrRegCol] <= InData;
			else if(dWriteReg == `WRITE_REGY)
				regY[dAddrRegRow*5+dAddrRegCol] <= InData;
			else if(dWriteReg == `WRITE_REGZ)
				regZ[dAddrRegRow*5+dAddrRegCol] <= InData;
			else begin
				regX[dAddrRegRow*5+dAddrRegCol] <= regX[dAddrRegRow*5+dAddrRegCol];
				regY[dAddrRegRow*5+dAddrRegCol] <= regY[dAddrRegRow*5+dAddrRegCol];
				regZ[dAddrRegRow*5+dAddrRegCol] <= regZ[dAddrRegRow*5+dAddrRegCol];
			end
			//$display("Load Data from InData to Reg => Mode:%d\n",dWriteReg);	
		end

		// Output Data from Canny Edge Detector
		else if(bCE==1'b0 && bWE==1'b1)
		begin
			if(dReadReg == `REG_GAUSSIAN)
				OutData <= Out_gf;
			else if(dReadReg == `REG_GRADIENT)
				OutData <= Out_gradient;
			else if(dReadReg == `REG_DIRECTION)
				OutData <= Out_direction;
			else if(dReadReg == `REG_NMS)
				OutData <= Out_gradient;
			else if(dReadReg == `REG_HYSTERESIS)
				OutData <= Out_bThres;
			else
				OutData <= OutData;
			//$display("Read Data from Register or Array to OutData => Mode:%d\n", dReadReg);
		end

		else
		begin
			if(bOPEnable==1'b0)
			begin
				if(OPMode == `MODE_GAUSSIAN)
				begin
					if(IntSignal == 2'b00)	begin
						//tpSum <= (5x5 Guassian Filter) convolution (5x5 Pixels);
						tpSum <= (gf[0]*regX[0]+gf[1]*regX[1]+gf[2]*regX[2]+gf[3]*regX[3]+gf[4]*regX[4]+gf[5]*regX[5]+gf[6]*regX[6]+gf[7]*regX[7]+gf[8]*regX[8]+gf[9]*regX[9]+gf[10]*regX[10]+gf[11]*regX[11]+gf[12]*regX[12]+gf[13]*regX[13]+gf[14]*regX[14]+gf[15]*regX[15]+gf[16]*regX[16]+gf[17]*regX[17]+gf[18]*regX[18]+gf[19]*regX[19]+gf[20]*regX[20]+gf[21]*regX[21]+gf[22]*regX[22]+gf[23]*regX[23]+gf[24]*regX[24]);
						IntSignal <= 2'b01;
					end
					else if(IntSignal == 2'b01) begin
						// tpSum/128
						Out_gf <= tpSum >> 7;				 
					end
					else begin
						Out_gf <= Out_gf;
						IntSignal <= IntSignal;
					end
				end
				else if(OPMode == `MODE_SOBEL)
				begin
					// Gradient
					if(IntSignal == 2'b00)	begin
						// Calculate Gradiant for X and Y
						Gx <= -regX[0]-2*regX[5]-regX[10]+regX[2]+2*regX[7]+regX[12];
						Gy <= +regX[0]+2*regX[1]+regX[2]-regX[10]-2*regX[11]-regX[12];
						IntSignal <= 2'b01;
					end
					else if(IntSignal == 2'b01) begin
						//|G| = (|Gx|+|Gy|)/8
						if(Gx >= 0 && Gy >= 0)
							Out_gradient <= (Gx+Gy)/8;
						else if(Gx < 0 && Gy >=0)
							Out_gradient <= (-Gx+Gy)/8;
						else if(Gx >= 0 && Gy < 0)
							Out_gradient <= (Gx-Gy)/8;
						else if(Gx < 0 && Gy < 0)
							Out_gradient <= (-Gx-Gy)/8;
						else
							Out_gradient <= Out_gradient;
						IntSignal <= 2'b10;
					end	
					else if(IntSignal == 2'b10) begin
					// Direction (Theta) = tan(Gy/Gx)
					// make sure Gy > 0, so we can judge by the positive or negative of Gx.
						if(Gy < 0)
						begin
							fGx <= -Gx;
							fGy <= -Gy;
						end
						else
						begin
							fGx <= Gx;
							fGy <= Gy;
						end
						IntSignal <= 2'b11;
					end
					else if(IntSignal == 2'b11) begin
						// Edge Normal which is perpendicular to Edge Orientation
						// Edge Normal:0 -> Direction:90
						// Edge Normal:45 -> Direction:135
						// Edge Normal:90 -> Direction:0
						// Edge Normal:135 -> Direction:45
						// Because the testbench has turned normal to the direction, here will not turn.
						if(fGx >=0)
/*						begin
							if(fGy <= (fGx>>1)) //0.4*fGx
								Out_direction <= 0;
							else if(fGy > (fGx>>1) && fGy <= (fGx<<1+fGx>>1)) //2.4*fGx=2*fGx+0.5*fGx
								Out_direction <= 45;
							else if(fGy > (fGx<<1+fGx>>1))
								Out_direction <= 90;
							else
								Out_direction <= Out_direction;
						end
						else // if(fGx<0)
						begin
							if(fGy <= -(fGx>>1))
								Out_direction <= 0;
							else if(fGy > -(fGx>>1) && fGy <= -(fGx<<1+fGx>>1))
								Out_direction <= 135;
							else if(fGy > -(fGx<<1+fGx>>1))
								Out_direction <= 90;
							else
								Out_direction <= Out_direction;
						end */
						begin
							if(fGy <= fGx>>1) //0.4*fGx
								Out_direction <= 0;
							else if(fGy > fGx>>1 && fGy <= fGx*25/10) //2.4*fGx=2*fGx+0.5*fGx
								Out_direction <= 45;
							else if(fGy > fGx*25/10)
								Out_direction <= 90;
							else
								Out_direction <= Out_direction;
						end
						else // if(fGx<0)
						begin
							if(fGy <= -fGx>>1)
								Out_direction <= 0;
							else if(fGy > -fGx>>1 && fGy <= -fGx*25/10)
								Out_direction <= 135;
							else if(fGy > -fGx*25/10)
								Out_direction <= 90;
							else
								Out_direction <= Out_direction;
						end
						IntSignal <= IntSignal;
					end
				end
				else if(OPMode == `MODE_NMS)
				begin
					// regX = Gradient Image
					// regY = Theta Image
					if(IntSignal == 2'b00) begin
					// Direction is stored in regY[6], determin dx and dy
					// regX[6-5*dy-dx], regX[6+5*dy+dx]
						if(regY[6] == 0) begin
							dx <= 1;
							dy <= 0;
						end
						else if(regY[6] == 45) begin
							dx <= -1;
							dy <= 1;
						end
						else if(regY[6] == 90) begin
							dx <= 0;
							dy <= 1;
						end
						else if(regY[6] == 135) begin
							dx <= 1;
							dy <= 1;
						end
						else begin
							dx <= 0;//dx;
							dy <= 0;//dy;
						end
						// It's so clever that because the different direction corresponding to the different dx and dy, 
						// we do not have to discuss so much situations.
						IntSignal <= 2'b01;
					end
					else if(IntSignal == 2'b01) begin
						// Non-maximum suppression
						if(regX[6] < regX[6-5*dy-dx] | regX[6] < regX[6+5*dy+dx])
							regX[6] <= 0;
						IntSignal <= IntSignal;
						Out_gradient <= regX[6];
					end
				end
				else if(OPMode == `MODE_HYSTERESIS)
				begin
					// regX = Gradient Image
					// regY = Theta Image
					// regZ = bGxy Image (On/Off)
					if(IntSignal == 2'b00) begin
						if(regY[6] == 0) begin
							dx <= 1;
							dy <= 0;
						end
						else if(regY[6] == 45) begin
							dx <= -1;
							dy <= 1;
						end
						else if(regY[6] == 90) begin
							dx <= 0;
							dy <= 1;
						end
						else if(regY[6] == 135) begin
							dx <= 1;
							dy <= 1;
						end
						else begin
							dx <= 0;//dx;
							dy <= 0;//dy;
						end
						IntSignal <= 2'b01;
					end	
					else if(IntSignal == 2'b01) begin

						if(regX[6] >= dThresHigh)		// Keep Edge Info
							Out_bThres <= 1;
						else if(regX[6] <= dThresLow)	// Discard Pixel
							Out_bThres <= 0;
						else							// Follow Edge Trace
						begin
							if(regX[6-5*dy-dx] >= dThresHigh || regX[6+5*dy+dx] >= dThresHigh)
								Out_bThres <= 1;
							else if(regZ[6-5*dy-dx] == 1 || regZ[6+5*dy+dx] == 1)
								Out_bThres <= 1;
							else
								Out_bThres <= 0;
						end

						IntSignal <= IntSignal;
					end
				end
			end	
			else // of bOPEnable
				IntSignal <= 2'b00;
		end // of 'else' of '!rst_b'
	end
endmodule

