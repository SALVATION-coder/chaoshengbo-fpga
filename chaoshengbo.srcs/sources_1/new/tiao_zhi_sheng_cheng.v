`timescale 1ns / 1ps

module tiao_zhi_sheng_cheng(
    input clk,
    input rst_n,
    output reg mod_out
);

reg [15:0] cnt;
localparam CNT_MAX = 16'd49999;  // 50MHz / 50000 = 1kHz

// 计数器逻辑
always @(posedge clk or negedge rst_n) begin
    if(!rst_n)
        cnt <= 16'd0;
    else if(cnt >= CNT_MAX)
        cnt <= 16'd0;
    else
        cnt <= cnt + 1'd1;
end

// 调制信号输出（50%占空比方波）
always @(posedge clk or negedge rst_n) begin
    if(!rst_n)
        mod_out <= 1'b0;
    else
        mod_out <= (cnt < 16'd25000);
end

endmodule
