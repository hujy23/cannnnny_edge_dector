`timescale 1 ns / 1 ns
`define DATA_WIDTH 	8

module top(clk, rst_n, hsync, vsync, vga_r, vga_g, vga_b);

	input clk;
	input rst_n;
	output hsync;
	output vsync;
	output [3:0] vga_r;
	output [3:0] vga_g;
	output [3:0] vga_b;

	wire 	[2:0]				dAddrRegRow, dAddrRegCol;
	wire						bWE, bCE;
	wire 	[`DATA_WIDTH-1:0] 	InData;
	wire	[`DATA_WIDTH-1:0] 	OutData;

	wire 	[2:0]				OPMode;
	wire 						bOPEnable;
	wire 	[3:0]				dReadReg, dWriteReg;

	wire						tclk, pclk, rst_b;

	wire            weXG;
	wire            weGxy;
	wire            weThetaT;
	wire            weGxyT;
	wire            webGxyT;

	wire  [15:0]     X_addr;
	wire  [15:0]     XG_addr;
	wire  [15:0]     Gxy_addr;
	wire  [15:0]     ThetaT_addr;
	wire  [15:0]     GxyT_addr;
	wire  [15:0]     bGxyT_addr;

	wire [7:0]      X_douta;
	wire [7:0]      XG_douta;
	wire [7:0]      Gxy_douta;
	wire [23:0]      ThetaT_douta;
	wire [7:0]      GxyT_douta;
	wire [7:0]      bGxyT_douta;

clk_div getPCLK(.origin_clk(clk),
				.reset(rst_n),
				.div(4),
				.div_clk(pclk) // used for memory and vga
				);

clk_div getTCLK(.origin_clk(clk),
				.reset(rst_n),
				.div(20),
				.div_clk(tclk) // used for newTestbench and canny
				);

CannyEdge CannyEdge_01(dAddrRegRow, dAddrRegCol, bWE, bCE, InData, OutData,
	OPMode, bOPEnable, dReadReg, dWriteReg,	tclk, rst_n);
	
newtestbench newtestbench_01(dAddrRegRow, dAddrRegCol, bWE, bCE, InData, OutData,
	OPMode, bOPEnable, dReadReg, dWriteReg,	tclk, pclk, rst_n,
	weXG, weGxy, weThetaT, weGxyT, webGxyT,
	X_addr, XG_addr, Gxy_addr, ThetaT_addr, GxyT_addr, bGxyT_addr,
	X_douta, XG_douta, Gxy_douta, ThetaT_douta, GxyT_douta, bGxyT_douta
);

vga_display vga_display_01(pclk, rst_n, hsync, vsync, vga_r, vga_g, vga_b, 
                  weXG, weGxy, weThetaT, weGxyT, webGxyT,
                  X_addr, XG_addr, Gxy_addr, ThetaT_addr, GxyT_addr, bGxyT_addr,
                  X_douta, XG_douta, Gxy_douta, ThetaT_douta, GxyT_douta, bGxyT_douta
                  );
endmodule
