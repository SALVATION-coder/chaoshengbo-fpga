`timescale 1ns / 1ps

module zai_bo_sheng_cheng(
    input clk,
    input rst_n,
    input [7:0] duty_cycle,
    input [7:0] phase_offset,
    output reg pwm_out
);

localparam CNT_MAX    = 11'd1249;
localparam PHASE_SCALE= 11'd5;

reg [10:0] cnt;

// 计数器时序逻辑（2018无锁存器警告）
always @(posedge clk or negedge rst_n) begin
    if(!rst_n)
        cnt <= phase_offset * PHASE_SCALE;
    else if(cnt >= CNT_MAX)
        cnt <= 11'd0;
    else
        cnt <= cnt + 1'd1;
end

// PWM输出逻辑
always @(posedge clk or negedge rst_n) begin
    if(!rst_n)
        pwm_out <= 1'b0;
    else
        pwm_out <= (cnt < (duty_cycle * PHASE_SCALE));
end

endmodule
