`timescale 1 ns / 1 ns

module dmem(input clk, we,
			input  [15:0]    a,
			input  [7:0]    wd,
			output [7:0]    rd);

reg  [7:0]	RAM[40000-1:0];

assign rd = RAM[a];

always @(posedge clk)
	if (we)
		RAM[a] <= wd;
endmodule

module big_dmem(input clk, we,
			input  [15:0]    a,
			input  [23:0]    wd,
			output [23:0]    rd);

reg  [23:0]	RAM[40000-1:0];

assign rd = RAM[a];

always @(posedge clk)
	if (we)
		RAM[a] <= wd;
endmodule
