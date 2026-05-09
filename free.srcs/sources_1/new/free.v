`timescale 1ns / 1ps

module free(
    input   wire clk,
    input   wire rst_n,
    input   wire  [2:0]  a,
    input   wire  [2:0]  b,
    output  reg   [2:0]  c,
    output  wire  [2:0]  d
    );
always @(posedge clk)begin 
    if(rst_n == 1'b0) begin
        c <= 3'd0;
    end
    else begin
        c <= a & b;
    end
end
assign d = (a > b) ? 'd1 : 'd0;

endmodule
