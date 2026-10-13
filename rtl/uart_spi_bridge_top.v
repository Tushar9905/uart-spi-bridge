`timescale 1ns/1ps

module uart_spi_bridge_top #(
    parameter CLK_PER_BIT = 87,
    parameter SPI_CLK_DIV = 4
) (
    input  clk,
    input  rst,

    input  uart_rx,
    output uart_tx,

    output spi_sclk,
    output spi_mosi,
    input  spi_miso,
    output spi_cs_n,

    output frame_err
);

    // async assert, sync release
    reg [1:0] rst_sync;
    always @(posedge clk or posedge rst) begin
        if (rst)
            rst_sync <= 2'b11;
        else
            rst_sync <= {rst_sync[0], 1'b0};
    end
    wire rst_i = rst_sync[1];

    wire       rx_done;
    wire [7:0] rx_data;
    wire       spi_start, spi_done;
    wire [7:0] spi_tx_data, spi_rx_data;
    wire       tx_start, tx_busy;
    wire [7:0] tx_data;

    uart_rx #(.CLK_PER_BIT(CLK_PER_BIT)) u_uart_rx (
        .clk       (clk),
        .rst       (rst_i),
        .rx        (uart_rx),
        .data_out  (rx_data),
        .done      (rx_done),
        .frame_err (frame_err)
    );

    uart_to_spi_bridge u_bridge (
        .clk         (clk),
        .rst         (rst_i),
        .uart_done   (rx_done),
        .uart_data   (rx_data),
        .spi_done    (spi_done),
        .spi_rx_data (spi_rx_data),
        .spi_start   (spi_start),
        .spi_tx_data (spi_tx_data),
        .tx_start    (tx_start),
        .tx_data     (tx_data),
        .tx_busy     (tx_busy)
    );

    spi_master #(.CLK_DIV(SPI_CLK_DIV)) u_spi_master (
        .clk           (clk),
        .rst           (rst_i),
        .start         (spi_start),
        .mosi_data_in  (spi_tx_data),
        .miso_data_out (spi_rx_data),
        .done          (spi_done),
        .busy          (),
        .sclk          (spi_sclk),
        .mosi          (spi_mosi),
        .miso          (spi_miso),
        .cs_n          (spi_cs_n)
    );

    uart_tx #(.CLK_PER_BIT(CLK_PER_BIT)) u_uart_tx (
        .clk     (clk),
        .rst     (rst_i),
        .start   (tx_start),
        .data_in (tx_data),
        .tx      (uart_tx),
        .busy    (tx_busy)
    );

endmodule
