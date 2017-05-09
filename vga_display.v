`timescale 1 ns / 1 ns

module vga_display(pclk, rst_n, hsync, vsync, vga_r, vga_g, vga_b, 
                  weXG, weGxy, weThetaT, weGxyT, webGxyT,
                  X_addr, XG_addr, Gxy_addr, ThetaT_addr, GxyT_addr, bGxyT_addr,
                  X_douta, XG_douta, Gxy_douta, ThetaT_douta, GxyT_douta, bGxyT_douta
                  );
   
   input           pclk;
   input           rst_n;
   
   //out for vga
   output          hsync;
   output          vsync;
   output reg [3:0]    vga_r;
   output reg [3:0]    vga_g;
   output reg [3:0]    vga_b;
   
   //memory write enable input(always disable when display)
   //input    wire            weX;
   input    wire            weXG;
   input    wire            weGxy;
   input    wire            weThetaT;
   input    wire            weGxyT;
   input    wire            webGxyT;
   //addr out
   output   reg  [15:0]     X_addr;
   output   reg  [15:0]     XG_addr;
   output   reg  [15:0]     Gxy_addr;
   output   reg  [15:0]     ThetaT_addr;
   output   reg  [15:0]     GxyT_addr;
   output   reg  [15:0]     bGxyT_addr;
   //read out input
   input    wire [7:0]      X_douta;
   input    wire [7:0]      XG_douta;
   input    wire [7:0]      Gxy_douta;
   input    wire [23:0]     ThetaT_douta;
   input    wire [7:0]      GxyT_douta;
   input    wire [7:0]      bGxyT_douta;
   
   //internal signal
   wire            valid;
   wire [9:0]      h_cnt;
   wire [9:0]      v_cnt;
   reg [23:0]      vga_data;

   wire            display_area;
   wire      [2:0] display;

   //some parameter
   parameter [9:0] ini_x = 20;
   parameter [9:0] ini_y = 40;

   parameter [9:0] iWidth = 200;
   parameter [9:0] iHeight = 200;

   //flag
   wire DISPLAY_ORIGIN;
   wire DISPLAY_GAUSSIAN;
   wire DISPLAY_GRADIENT;
   wire DISPLAY_DIRECTION;
   wire DISPLAY_NMS;
   wire DISPLAY_HYSTERESIS;
   
   //vga timing
	vga_640x480 u1 (
		.pclk(pclk), 
		.reset(rst_n), 
		.hsync(hsync), 
		.vsync(vsync), 
		.valid(valid), 
		.h_cnt(h_cnt), 
		.v_cnt(v_cnt)
		);

   //assign display_area = ((v_cnt >= ini_y) & (v_cnt <= ini_y + 2*iHeight - 1) & (h_cnt >= ini_x) & (h_cnt <= ini_x + 3*iWidth - 1)) ? 1'b1 : 1'b0;
   
   assign DISPLAY_ORIGIN = ((v_cnt >= ini_y) && (v_cnt <= ini_y + iHeight -1) && (h_cnt >= ini_x) && (h_cnt <= ini_x + iWidth - 1)) ? 1 : 0;
   assign DISPLAY_GAUSSIAN = ((v_cnt >= ini_y) && (v_cnt <= ini_y + iHeight -1) && (h_cnt >= ini_x + iWidth) && (h_cnt <= ini_x + 2*iWidth - 1)) ? 1 : 0;
   assign DISPLAY_GRADIENT = ((v_cnt >= ini_y) && (v_cnt <= ini_y + iHeight -1) && (h_cnt >= ini_x + 2*iWidth) && (h_cnt <= ini_x + 3*iWidth - 1)) ? 1 : 0;
   assign DISPLAY_DIRECTION = ((v_cnt >= ini_y + iHeight) && (v_cnt <= ini_y + 2*iHeight -1) && (h_cnt >= ini_x) && (h_cnt <= ini_x + iWidth - 1)) ? 1 : 0;
   assign DISPLAY_NMS = ((v_cnt >= ini_y + iHeight) && (v_cnt <= ini_y + 2*iHeight -1) && (h_cnt >= ini_x + iWidth) && (h_cnt <= ini_x + 2*iWidth - 1)) ? 1 : 0;
   assign DISPLAY_HYSTERESIS = ((v_cnt >= ini_y + iHeight) && (v_cnt <= ini_y + 2*iHeight -1) && (h_cnt >= ini_x + 2*iWidth) && (h_cnt <= ini_x + 3*iWidth - 1)) ? 1 : 0;

   always @(posedge pclk or negedge rst_n)
   begin
      if (!rst_n)
         vga_data <= 0;
      else 
      begin
         if (valid == 1'b1)
         begin
         //if (display_area == 1'b1)
         //begin
            if (DISPLAY_ORIGIN)
            begin
               X_addr <= X_addr + 16'b0000000000000001;
               vga_data <= X_douta;
            end
            else if (DISPLAY_GAUSSIAN)
            begin
               XG_addr <= XG_addr + 16'b0000000000000001;
               vga_data <= XG_douta;
            end
            else if (DISPLAY_GRADIENT)
            begin
               Gxy_addr <= Gxy_addr + 16'b0000000000000001;
               vga_data <= Gxy_douta;
            end
            else if (DISPLAY_DIRECTION)
            begin
               ThetaT_addr <= ThetaT_addr + 16'b0000000000000001;
               vga_data <= ThetaT_douta;
            end
            else if (DISPLAY_NMS)
            begin
               GxyT_addr <= GxyT_addr + 16'b0000000000000001;
               vga_data <= GxyT_douta;
            end
            else if (DISPLAY_HYSTERESIS)
            begin
               bGxyT_addr <= bGxyT_addr + 16'b0000000000000001;
               vga_data <= bGxyT_douta;
            end
         //end
            else
            begin
               X_addr <= X_addr;
               XG_addr <= XG_addr;
               Gxy_addr <= Gxy_addr;
               ThetaT_addr <= ThetaT_addr;
               GxyT_addr <= GxyT_addr;
               bGxyT_addr <= bGxyT_addr;
               vga_data <= 0;
            end
         end
         else // of valid
         begin
            vga_data <= 0;//black
            if (v_cnt == 0)
            begin
               X_addr <= 16'b0000000000000000;
               XG_addr <= 16'b0000000000000000;
               Gxy_addr <= 16'b0000000000000000;
               ThetaT_addr <= 16'b0000000000000000;
               GxyT_addr <= 16'b0000000000000000;
               bGxyT_addr <= 16'b0000000000000000;
            end
         end
      end
   end

   always @(weXG or weGxy or weGxyT or weThetaT or webGxyT or vga_data or DISPLAY_ORIGIN or DISPLAY_GAUSSIAN or DISPLAY_GRADIENT or DISPLAY_NMS or DISPLAY_HYSTERESIS or DISPLAY_DIRECTION)
   begin
      if (DISPLAY_ORIGIN || !weXG & DISPLAY_GAUSSIAN || !weGxy & DISPLAY_GRADIENT || !weGxyT & DISPLAY_NMS || !webGxyT & DISPLAY_HYSTERESIS)
      begin
         vga_r <= vga_data[7:4];
         vga_g <= vga_data[7:4];
         vga_b <= vga_data[7:4];
      end
      else if (!weThetaT & DISPLAY_DIRECTION)
      begin
         vga_r <= vga_data[7:4];
         vga_g <= vga_data[15:12];
         vga_b <= vga_data[23:20];
      end
	  else
	  begin
		vga_r <= 4'b0000;
		vga_g <= 4'b0000;
		vga_b <= 4'b0000;
	  end
   end
endmodule