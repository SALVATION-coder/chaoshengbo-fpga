`timescale 1ns / 1ps


module top_ultrasonic_array(
    input clk,          // 系统时钟（假设50MHz，根据你的板子改）
    input rst_n,        // 复位按键
    output ser,         // 74HC595串行数据
    output srclk,       // 74HC595移位时钟
    output rclk,        // 74HC595锁存时钟
    // 任务4预留：XCS7478 ADC接口
    output adc_cs,
    output adc_sclk,
    input adc_sdo
);

    // --------------------------
    // 任务1：40kHz载波生成（幅度/相位控制）
    // --------------------------
    wire carrier_40k;
    wire [7:0] duty_cycle = 8'd128; // 占空比50%，调这个值改幅度（0-255）
    wire [7:0] phase_offset = 8'd0;  // 相位偏移，调这个值改相位（0-255）
    pwm_generator u_pwm(
        .clk(clk),
        .rst_n(rst_n),
        .duty_cycle(duty_cycle),
        .phase_offset(phase_offset),
        .pwm_out(carrier_40k)
    );

    // --------------------------
    // 任务3：1kHz调制信号生成 + DSB调制
    // --------------------------
    wire mod_1k;
    mod_1k_generator u_mod(
        .clk(clk),
        .rst_n(rst_n),
        .mod_out(mod_1k)
    );
    wire dsb_out = carrier_40k ^ mod_1k; // 1行代码实现DSB调制（方波等效乘法）

    // --------------------------
    // 任务2：74HC595驱动25路同相输出
    // --------------------------
    hc595_driver u_hc595(
        .clk(clk),
        .rst_n(rst_n),
        .data_in({25{dsb_out}}), // 25路全部同相输入DSB信号
        .ser(ser),
        .srclk(srclk),
        .rclk(rclk)
    );

    // --------------------------
    // 任务4预留：XCS7478 ADC驱动（需要时再实例化）
    // --------------------------
    // adc_driver u_adc(...);

endmodule

module pwm_generator(
    input clk,
    input rst_n,
    input [7:0] duty_cycle,  // 占空比：0-255（调幅度）
    input [7:0] phase_offset, // 相位偏移：0-255（调相位）
    output reg pwm_out
);

    reg [7:0] cnt;
    localparam CNT_MAX = 8'd249; // 50MHz时钟 → 40kHz（50M/40k/2 -1 = 624，简化用8位演示，根据实际改）

    always @(posedge clk or negedge rst_n) begin
        if(!rst_n)
            cnt <= phase_offset; // 相位偏移初始化
        else if(cnt >= CNT_MAX)
            cnt <= 8'd0;
        else
            cnt <= cnt + 1'd1;
    end

    always @(posedge clk or negedge rst_n) begin
        if(!rst_n)
            pwm_out <= 1'b0;
        else
            pwm_out <= (cnt < duty_cycle); // 占空比控制
    end

endmodule


module mod_1k_generator(
    input clk,
    input rst_n,
    output reg mod_out
);

    reg [15:0] cnt;
    localparam CNT_MAX = 16'd24999; // 50MHz时钟 → 1kHz（50M/1k/2 -1 = 24999）

    always @(posedge clk or negedge rst_n) begin
        if(!rst_n)
            cnt <= 16'd0;
        else if(cnt >= CNT_MAX)
            cnt <= 16'd0;
        else
            cnt <= cnt + 1'd1;
    end

    always @(posedge clk or negedge rst_n) begin
        if(!rst_n)
            mod_out <= 1'b0;
        else if(cnt < (CNT_MAX/2))
            mod_out <= 1'b1;
        else
            mod_out <= 1'b0;
    end

endmodule

module hc595_driver(
    input clk,
    input rst_n,
    input [24:0] data_in, // 25路输入数据
    output reg ser,
    output reg srclk,
    output reg rclk
);

    reg [4:0] bit_cnt;
    reg [24:0] shift_reg;

    // 状态机：移位 → 锁存
    localparam IDLE = 2'd0, SHIFT = 2'd1, LATCH = 2'd2;
    reg [1:0] state;

    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            state <= IDLE;
            bit_cnt <= 5'd0;
            ser <= 1'b0;
            srclk <= 1'b0;
            rclk <= 1'b0;
            shift_reg <= 25'd0;
        end else begin
            case(state)
                IDLE: begin
                    state <= SHIFT;
                    shift_reg <= data_in;
                    bit_cnt <= 5'd0;
                    rclk <= 1'b0;
                end
                SHIFT: begin
                    if(bit_cnt < 5'd25) begin
                        srclk <= ~srclk;
                        if(srclk) begin
                            ser <= shift_reg[24];
                            shift_reg <= {shift_reg[23:0], 1'b0};
                            bit_cnt <= bit_cnt + 1'd1;
                        end
                    end else begin
                        state <= LATCH;
                        srclk <= 1'b0;
                    end
                end
                LATCH: begin
                    rclk <= 1'b1;
                    state <= IDLE;
                end
            endcase
        end
    end

endmodule