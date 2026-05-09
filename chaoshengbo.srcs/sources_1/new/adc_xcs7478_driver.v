`timescale 1ns / 1ps
// XCS7478串行ADC驱动模块（8位版本）
// Vivado 2018全版本兼容，Verilog-2001标准
// 系统时钟50MHz，采样率8kHz，8位分辨率，SPI模式0
// 所有逻辑统一在50MHz系统时钟下运行，无时钟域交叉
module adc_xcs7478_driver(
    input           sys_clk,        // 系统50MHz时钟
    input           sys_rst_n,      // 系统复位，低电平有效
    // ADC硬件接口
    output  reg     adc_cs_n,       // ADC片选信号，低电平有效
    output  reg     adc_sclk,       // ADC SPI串行时钟
    input           adc_dout,       // ADC串行数据输出（SDATA）
    // 对接DSB调制模块的输出接口
    output  reg [7:0]   audio_out   // 8位音频数据，范围0~255
);

// ===================== 时钟分频与采样触发 =====================
// 8kHz采样率：50MHz / 6250 = 8kHz
parameter   SAMPLE_CNT_MAX = 13'd6249;
reg [12:0]  sample_cnt;
reg         sample_trig;

always @(posedge sys_clk or negedge sys_rst_n) begin
    if(!sys_rst_n) begin
        sample_cnt <= 13'd0;
        sample_trig <= 1'b0;
    end
    else if(sample_cnt == SAMPLE_CNT_MAX) begin
        sample_cnt <= 13'd0;
        sample_trig <= 1'b1;
    end
    else begin
        sample_cnt <= sample_cnt + 13'd1;
        sample_trig <= 1'b0;
    end
end

// ===================== SPI状态机定义 =====================
parameter   IDLE      = 3'd0;  // 空闲状态
parameter   CS_LOW    = 3'd1;  // 片选拉低
parameter   READ      = 3'd2;  // 读取串行数据（12个SCLK周期）
parameter   CS_HIGH   = 3'd3;  // 片选拉高
parameter   WAIT_CS   = 3'd4;  // 等待1μs（CS恢复时间）
parameter   DATA_PROC = 3'd5;  // 数据预处理

reg [2:0]   curr_state;
reg [2:0]   next_state;
reg [3:0]   bit_cnt;        // 位计数，12个SCLK周期（4个前导零+8位数据）
reg [15:0]  adc_data_buf;   // 串行数据缓存

// 状态机时序逻辑
always @(posedge sys_clk or negedge sys_rst_n) begin
    if(!sys_rst_n)
        curr_state <= IDLE;
    else
        curr_state <= next_state;
end

// 状态机组合逻辑
reg [5:0] wait_cnt;
wire wait_done = (wait_cnt == 6'd49);

always @(*) begin
    case(curr_state)
        IDLE:       next_state = sample_trig ? CS_LOW : IDLE;
        CS_LOW:     next_state = READ;
        READ:       next_state = (bit_cnt == 4'd12) ? CS_HIGH : READ;
        CS_HIGH:    next_state = WAIT_CS;
        WAIT_CS:    next_state = wait_done ? DATA_PROC : WAIT_CS;
        DATA_PROC:  next_state = IDLE;
        default:    next_state = IDLE;
    endcase
end

// ===================== SPI时钟生成 =====================
// 生成1MHz SPI时钟（50MHz系统时钟分频，50分频=1MHz）
// SCLK在sclk_en有效时翻转，每25个sys_clk翻转一次
reg [4:0]   sclk_div_cnt;
reg         sclk_en;

always @(posedge sys_clk or negedge sys_rst_n) begin
    if(!sys_rst_n) begin
        sclk_div_cnt <= 5'd0;
        adc_sclk <= 1'b1;
    end
    else if(sclk_en) begin
        if(sclk_div_cnt == 5'd24) begin
            sclk_div_cnt <= 5'd0;
            adc_sclk <= ~adc_sclk;
        end
        else
            sclk_div_cnt <= sclk_div_cnt + 5'd1;
    end
    else begin
        sclk_div_cnt <= 5'd0;
        adc_sclk <= 1'b1;
    end
end

// ===================== SCLK上升沿检测 =====================
// 在50MHz时钟域检测adc_sclk的上升沿，用于数据采样
reg adc_sclk_d1;  // 延迟1拍
reg adc_sclk_d2;  // 延迟2拍
wire sclk_rise = (~adc_sclk_d2 & adc_sclk_d1);  // 上升沿脉冲

always @(posedge sys_clk or negedge sys_rst_n) begin
    if(!sys_rst_n) begin
        adc_sclk_d1 <= 1'b1;
        adc_sclk_d2 <= 1'b1;
    end
    else begin
        adc_sclk_d1 <= adc_sclk;
        adc_sclk_d2 <= adc_sclk_d1;
    end
end

// ===================== 位计数与数据读取 =====================
// 在SCLK上升沿（sclk_rise）时采样adc_dout
always @(posedge sys_clk or negedge sys_rst_n) begin
    if(!sys_rst_n) begin
        bit_cnt <= 4'd0;
        adc_data_buf <= 16'd0;
    end
    else if(curr_state == READ && sclk_rise) begin
        bit_cnt <= bit_cnt + 4'd1;
        adc_data_buf <= {adc_data_buf[14:0], adc_dout};
    end
    else if(curr_state == CS_LOW) begin
        bit_cnt <= 4'd0;
    end
end

// ===================== 片选与时钟使能控制 =====================
always @(posedge sys_clk or negedge sys_rst_n) begin
    if(!sys_rst_n) begin
        adc_cs_n <= 1'b1;
        sclk_en <= 1'b0;
        wait_cnt <= 6'd0;
    end
    else begin
        case(curr_state)
            CS_LOW: begin
                adc_cs_n <= 1'b0;
                sclk_en <= 1'b1;
                wait_cnt <= 6'd0;
            end
            CS_HIGH: begin
                adc_cs_n <= 1'b1;
                sclk_en <= 1'b0;
                wait_cnt <= 6'd0;
            end
            WAIT_CS: begin
                adc_cs_n <= 1'b1;
                sclk_en <= 1'b0;
                wait_cnt <= wait_cnt + 6'd1;
            end
            default: begin
                adc_cs_n <= 1'b1;
                sclk_en <= 1'b0;
                wait_cnt <= 6'd0;
            end
        endcase
    end
end

// ===================== 音频数据预处理 =====================
// XCS7478：16位帧 = 4前导零 + 8位数据(MSB先) + 4尾随零
// 采样后数据布局（左移入buf）：
//   buf[11:8] = 4个前导零
//   buf[7:0]  = D7 D6 D5 D4 D3 D2 D1 D0 (8位有效数据)
always @(posedge sys_clk or negedge sys_rst_n) begin
    if(!sys_rst_n)
        audio_out <= 8'd84;         // 中值初始化（VIN偏置在1.65V，对应ADC值约84）
    else if(curr_state == DATA_PROC) begin
        audio_out <= adc_data_buf[7:0];  // 提取8位有效数据
    end
    else
        audio_out <= audio_out;
end

endmodule
