`timescale 1ns / 1ps

module hc595_qu_dong(
    input clk,
    input rst_n,
    input [31:0] data_in,
    output reg ser,
    output reg srclk,
    output reg rclk
);

// 使能脉冲：每25个50MHz时钟产生一个使能（步进速率2MHz）
reg [4:0] en_cnt;
reg clk_en;

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        en_cnt <= 5'd0;
        clk_en <= 1'b0;
    end else begin
        if(en_cnt == 5'd1) begin
            en_cnt <= 5'd0;
            clk_en <= 1'b1;
        end else begin
            en_cnt <= en_cnt + 5'd1;
            clk_en <= 1'b0;
        end
    end
end

// 状态机：统一用50MHz系统时钟
reg [1:0] state;
reg [4:0] bit_cnt;
reg [31:0] shift_reg;
reg [1:0] step_cnt;

localparam IDLE   = 2'd0;
localparam SHIFT  = 2'd1;
localparam LATCH  = 2'd2;

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        state <= IDLE;
        ser <= 1'b0;
        srclk <= 1'b0;
        rclk <= 1'b0;
        bit_cnt <= 5'd0;
        shift_reg <= 32'd0;
        step_cnt <= 2'd0;
    end else if(clk_en) begin
        case(state)
            IDLE: begin
                shift_reg <= data_in;
                bit_cnt <= 5'd0;
                step_cnt <= 2'd0;
                rclk <= 1'b0;
                srclk <= 1'b0;
                state <= SHIFT;
            end

            SHIFT: begin
                if(bit_cnt < 5'd31) begin
                    case(step_cnt)
                        2'd0: begin
                            ser <= shift_reg[31];
                            srclk <= 1'b0;
                            step_cnt <= step_cnt + 2'd1;
                        end
                        2'd1: begin
                            srclk <= 1'b1;
                            step_cnt <= step_cnt + 2'd1;
                        end
                        2'd2: begin
                            shift_reg <= {shift_reg[30:0], 1'b0};
                            bit_cnt <= bit_cnt + 5'd1;
                            step_cnt <= 2'd0;
                        end
                        default: step_cnt <= 2'd0;
                    endcase
                end else begin
                    state <= LATCH;
                    step_cnt <= 2'd0;
                    srclk <= 1'b0;
                end
            end

            LATCH: begin
                case(step_cnt)
                    2'd0: begin
                        rclk <= 1'b1;
                        step_cnt <= step_cnt + 2'd1;
                    end
                    2'd1: begin
                        rclk <= 1'b0;
                        step_cnt <= 2'd0;
                        state <= IDLE;
                    end
                    default: step_cnt <= 2'd0;
                endcase
            end

            default: state <= IDLE;
        endcase
    end
end

endmodule