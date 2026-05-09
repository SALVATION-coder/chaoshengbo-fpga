// 仿真测试台：和主模块保持完全一致的时间单位
`timescale 1ns/1ps  
module tb_chao_sheng_bo;

// 1. 测试台信号定义
reg clk;          // 50MHz时钟输入
reg rst_n;        // 低电平复位
// 输出信号（自动观测波形）
wire ser;
wire srclk;
wire rclk;
wire zai_bo_40k;
wire tiao_zhi_1k;
wire tiao_zhi_shu_chu;

// 2. 例化顶层模块（核心：连接测试台和你的功能代码）
chao_sheng_bo_zong_kong u_top (
    .clk(clk),
    .rst_n(rst_n),
    .ser(ser),
    .srclk(srclk),
    .rclk(rclk),
    .zai_bo_40k(zai_bo_40k),
    .tiao_zhi_1k(tiao_zhi_1k),
    .tiao_zhi_shu_chu(tiao_zhi_shu_chu)
);

// 3. 生成 50MHz 时钟 (周期20ns，标准仿真时钟)
initial begin
    clk = 0;
    forever #10 clk = ~clk;  // 每10ns翻转一次 → 20ns周期
end

// 4. 复位时序 (先复位，后正常运行)
initial begin
    rst_n = 0;   // 复位有效
    #100;        // 保持100ns
    rst_n = 1;   // 释放复位，开始工作
    #10000000;   // 仿真运行10ms（足够观测1kHz调制信号）
    $stop;       // 自动停止仿真
end

endmodule