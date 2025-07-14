`timescale 1ns/1ps

module uart_testbench;

    reg clk = 0;
    reg rst = 1;
    reg start = 0;
    reg [7:0] data_in = 8'hA5;
    wire tx;
    wire busy;

    wire [7:0] data_out;
    wire done;

    // Clock generator: 10 MHz
    always #50 clk = ~clk;

    uart_tx #(.CLK_PER_BIT(87)) tx_inst (
        .clk(clk),
        .rst(rst),
        .start(start),
        .data_in(data_in),
        .tx(tx),
        .busy(busy)
    );

    uart_rx #(.CLK_PER_BIT(87)) rx_inst (
        .clk(clk),
        .rst(rst),
        .rx(tx),         // loopback
        .data_out(data_out),
        .done(done)
    );

    initial begin
        $dumpfile("wave.vcd");
        $dumpvars(0, uart_testbench);

        #200 rst = 0;
        #200 start = 1;
        #100 start = 0;

        wait (done == 1);
        #100;

        $display("[Testbench] Transmitted: %h", data_in);
        $display("[Testbench] Received:    %h", data_out);
        $finish;
    end
endmodule
