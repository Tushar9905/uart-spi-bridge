`timescale 1ns/1ps

// Sends each UART byte to the SPI slave and returns the slave's reply over UART
module uart_to_spi_bridge (
    input            clk,
    input            rst,

    input            uart_done,
    input      [7:0] uart_data,

    input            spi_done,
    input      [7:0] spi_rx_data,
    output reg       spi_start,
    output reg [7:0] spi_tx_data,

    output reg       tx_start,
    output reg [7:0] tx_data,
    input            tx_busy
);

    localparam IDLE      = 2'd0,
               WAIT_SPI  = 2'd1,
               SEND_UART = 2'd2;

    reg [1:0] state;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state       <= IDLE;
            spi_start   <= 0;
            spi_tx_data <= 0;
            tx_start    <= 0;
            tx_data     <= 0;
        end else begin
            spi_start <= 0;
            tx_start  <= 0;

            case (state)
                IDLE: begin
                    if (uart_done) begin
                        spi_tx_data <= uart_data;
                        spi_start   <= 1;
                        state       <= WAIT_SPI;
                    end
                end
                WAIT_SPI: begin
                    if (spi_done) begin
                        tx_data <= spi_rx_data;
                        state   <= SEND_UART;
                    end
                end
                SEND_UART: begin
                    if (!tx_busy) begin
                        tx_start <= 1;
                        state    <= IDLE;
                    end
                end
                default: state <= IDLE;
            endcase
        end
    end

endmodule
