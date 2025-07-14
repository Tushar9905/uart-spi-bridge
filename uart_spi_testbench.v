`timescale 1ns/1ps

module uart_spi_testbench;

    reg clk = 0;
    reg rst = 1;
    reg uart_rx_line = 1;

    // Clock: 10 MHz
    always #50 clk = ~clk;

    // TX controller
    reg start_uart_tx = 0;
    reg [7:0] uart_tx_data = 8'h3C; // Example byte

    wire tx_busy;
    wire uart_tx_line;
    wire uart_done_rx;
    wire [7:0] uart_data_rx;
    wire [7:0] spi_miso_data;
    wire [7:0] slave_data_out;

    // Instantiate UART transmitter to simulate PC sender
    uart_tx #(.CLK_PER_BIT(87)) uart_sender (
        .clk(clk),
        .rst(rst),
        .start(start_uart_tx),
        .data_in(uart_tx_data),
        .tx(uart_tx_line),
        .busy(tx_busy)
    );

    // Connect transmitter to receiver line (loopback)
    always @(posedge clk)
        uart_rx_line <= uart_tx_line;

    // UART Receiver (Bridge input)
    uart_rx #(.CLK_PER_BIT(87)) uart_receiver (
        .clk(clk),
        .rst(rst),
        .rx(uart_rx_line),
        .data_out(uart_data_rx),
        .done(uart_done_rx)
    );

    // SPI Master
    wire spi_start;
    wire spi_done;
    wire [7:0] spi_tx_data;
    wire [7:0] spi_rx_data;
    wire sclk, mosi, miso, cs;

    spi_master spi_master_inst (
        .clk(clk),
        .rst(rst),
        .start(spi_start),
        .mosi_data_in(spi_tx_data),
        .miso_data_out(spi_rx_data),
        .done(spi_done),
        .sclk(sclk),
        .mosi(mosi),
        .miso(miso),
        .cs(cs)
    );

    // SPI Slave
    spi_slave spi_slave_inst (
        .clk(clk),
        .rst(rst),
        .sclk(sclk),
        .mosi(mosi),
        .miso(miso),
        .cs(cs),
        .data_out(slave_data_out)
    );

    // UART-to-SPI Bridge
    wire tx_start;
    wire [7:0] tx_data;
    wire tx_line;

    uart_to_spi_bridge bridge (
        .clk(clk),
        .rst(rst),
        .uart_done(uart_done_rx),
        .uart_data(uart_data_rx),
        .spi_done(spi_done),
        .spi_rx_data(spi_rx_data),
        .spi_start(spi_start),
        .spi_tx_data(spi_tx_data),
        .tx_start(tx_start),
        .tx_data(tx_data),
        .tx_busy(tx_busy)
    );

    // Dummy receiver to complete TX circuit
    uart_tx #(.CLK_PER_BIT(87)) uart_echo (
        .clk(clk),
        .rst(rst),
        .start(tx_start),
        .data_in(tx_data),
        .tx(tx_line),
        .busy(tx_busy)
    );

    initial begin
        $dumpfile("wave.vcd");
        $dumpvars(0, uart_spi_testbench);

        #200 rst = 0;
        #200 start_uart_tx = 1;
        #100 start_uart_tx = 0;

        wait (bridge.spi_done);
        #500;

        $display("[UART→Bridge] Sent: %h", uart_tx_data);
        $display("[SPI Master] Received: %h", spi_rx_data);
        $display("[SPI Slave] Received: %h", slave_data_out);
        $finish;
    end
endmodule
