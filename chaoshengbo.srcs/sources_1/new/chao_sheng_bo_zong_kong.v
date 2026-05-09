`timescale 1ns / 1ps

module chao_sheng_bo_zong_kong(
    input clk,
    input rst_n,
    output ser,
    output srclk,
    output rclk,
    // ADC硬件接口端口
    output adc_cs_n,
    output adc_sclk,
    input  adc_dout,
    // 模式选择：0=固定1kHz调制，1=ADC音频调制
    input  mod_mode,
    // 心跳灯
    output pl_led
);

// ===================== 载波生成 =====================
wire zai_bo_40k;

// 40kHz超声载波生成
zai_bo_sheng_cheng u_zai_bo(
    .clk(clk),
    .rst_n(rst_n),
    .duty_cycle(8'd128),
    .phase_offset(8'd0),
    .pwm_out(zai_bo_40k)
);

// ===================== 调制信号生成 =====================
// 1kHz固定调制信号
wire tiao_zhi_1k;
tiao_zhi_sheng_cheng u_tiao_zhi(
    .clk(clk),
    .rst_n(rst_n),
    .mod_out(tiao_zhi_1k)
);

// ADC音频采集模块
wire [7:0] adc_audio_data;
adc_xcs7478_driver u_adc_xcs7478_driver(
    .sys_clk        (clk),
    .sys_rst_n      (rst_n),
    .adc_cs_n       (adc_cs_n),
    .adc_sclk       (adc_sclk),
    .adc_dout       (adc_dout),
    .audio_out      (adc_audio_data)
);

// ADC音频转1bit调制信号（过零比较）
// 注意：硬件VIN偏置为1.65V（3.3V分压），对应ADC值约84
wire audio_mod;
assign audio_mod = (adc_audio_data > 8'd84) ? 1'b1 : 1'b0;

// ===================== 调制源选择 =====================
wire mod_signal;
assign mod_signal = mod_mode ? audio_mod : tiao_zhi_1k;

// ===================== DSB幅度调制 =====================
// DSB调制：载波与调制信号异或（当调制信号为0时反相载波）
wire tiao_zhi_shu_chu;
assign tiao_zhi_shu_chu = zai_bo_40k ^ (~mod_signal);

// ===================== 595数据组装 =====================
// 32位595数据：按原理图U1→U2→U3→U4级联
// U1: QA空(bit0), QB~QH接CH1~7(bit1~7)
// U2: QA空(bit8), QB~QH接CH8~14(bit9~15)
// U3: QA空(bit16), QB~QH接CH15~21(bit17~23)
// U4: QA/QF/QG/QH空(bit24/bit29/bit30/bit31), QB~QE接CH22~25(bit25~28)

wire [31:0] data_595;

assign data_595 = {
    3'd0,                           // [31:29] U4 QH/QG/QF 空
    {4{tiao_zhi_shu_chu}},          // [28:25] U4 QE/QD/QC/QB CH22~25
    1'b0,                           // [24]    U4 QA 空
    {7{tiao_zhi_shu_chu}},          // [23:17] U3 QH~QB CH15~21
    1'b0,                           // [16]    U3 QA 空
    {7{tiao_zhi_shu_chu}},          // [15:9]  U2 QH~QB CH8~14
    1'b0,                           // [8]     U2 QA 空
    {7{tiao_zhi_shu_chu}},          // [7:1]   U1 QH~QB CH1~7
    1'b0                            // [0]     U1 QA 空
};

// ===================== 74HC595驱动 =====================
hc595_qu_dong u_595(
    .clk(clk),
    .rst_n(rst_n),
    .data_in(data_595),
    .ser(ser),
    .srclk(srclk),
    .rclk(rclk)
);

// ===================== 心跳灯 =====================
// 50MHz时钟，0.5s翻转一次，周期1s
reg [24:0] cnt_led;
reg pl_led_reg;
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        cnt_led <= 25'd0;
        pl_led_reg <= 1'b0;
    end
    else if(cnt_led == 25'd24999999) begin
        cnt_led <= 25'd0;
        pl_led_reg <= ~pl_led_reg;
    end
    else begin
        cnt_led <= cnt_led + 1'b1;
    end
end
assign pl_led = pl_led_reg;

endmodule
