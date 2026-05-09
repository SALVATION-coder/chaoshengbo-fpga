
# 50MHz系统时钟 匹配Mizar Z7用户手册Table3-2 xc7z020专用
set_property PACKAGE_PIN H16 [get_ports clk]
set_property IOSTANDARD LVCMOS33 [get_ports clk]
create_clock -add -name sys_clk_pin -period 20.00 [get_ports clk]

# 复位按键 匹配Mizar Z7用户手册Table3-16
set_property PACKAGE_PIN R19 [get_ports rst_n]
set_property IOSTANDARD LVCMOS33 [get_ports rst_n]

# 74HC595控制引脚 匹配Mizar Z7用户手册Table3-18 JP1扩展口
set_property PACKAGE_PIN N18 [get_ports ser]
set_property IOSTANDARD LVCMOS33 [get_ports ser]

set_property PACKAGE_PIN N17 [get_ports srclk]
set_property IOSTANDARD LVCMOS33 [get_ports srclk]

set_property PACKAGE_PIN N20 [get_ports rclk]
set_property IOSTANDARD LVCMOS33 [get_ports rclk]

# ===================== XCS7478 ADC引脚约束 =====================
set_property PACKAGE_PIN M15 [get_ports adc_sclk]
set_property IOSTANDARD LVCMOS33 [get_ports adc_sclk]

set_property PACKAGE_PIN N15 [get_ports adc_cs_n]
set_property IOSTANDARD LVCMOS33 [get_ports adc_cs_n]

set_property PACKAGE_PIN K14 [get_ports adc_dout]
set_property IOSTANDARD LVCMOS33 [get_ports adc_dout]

# ===================== 模式选择引脚约束 =====================
# mod_mode: 0=固定1kHz调制, 1=ADC音频调制
# 使用JP1扩展口 GPIO1_3P (Pin 7)
set_property PACKAGE_PIN T17 [get_ports mod_mode]
set_property IOSTANDARD LVCMOS33 [get_ports mod_mode]

# 心跳灯 匹配Mizar Z7用户手册Table3-17 PL_LED1
set_property PACKAGE_PIN G14 [get_ports pl_led]
set_property IOSTANDARD LVCMOS33 [get_ports pl_led]
