`timescale 1ns / 1ps
module tb_free();
    reg  [2:0]  a;
    reg  [2:0]  b;
    reg  rst_n;
    reg  sys_clk ;
    wire [2:0] c ;
    wire [2:0] d;

    free inst_free(
        .rst_n(rst_n),
        .clk(sys_clk),
        .a(a),
        .b(b),
        .c(c),
        .d(d)

    );
    initial begin
        sys_clk = 0;
        forever #5 sys_clk = ~sys_clk;
    end

    initial begin
        rst_n = 0 ;
        a = 0;
        b = 0;
        
       repeat(100)@(posedge sys_clk);
       rst_n = 1;

       repeat(100)@(posedge sys_clk);
       gen_test_data();

    end    

    task gen_test_data();
    integer i;begin
        
        for (i =0 ;i<10 ;i= i+1 ) begin
            a = i[2:0];//取i的第三位进行赋值
            b = i[2:0]+1;
            repeat(100)@(posedge sys_clk);
        end
    end
    endtask

endmodule