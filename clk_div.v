`timescale 1 ns / 1 ns

module clk_div(
    input origin_clk,
    input reset,
    input [7:0] div,
    output reg div_clk
    );
    
    reg [7:0] count;
    
    always@(posedge origin_clk or negedge reset)
    begin
        if(!reset)
        begin
            div_clk <= 0;
            count <= 0;
        end
        else
        begin
            if(count == div)
            begin
                div_clk <= ~div_clk;
                count <= 0;
            end
            else
                count <= count + 1'b1;
        end
    end

endmodule
