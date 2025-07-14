module uart_to_spi_bridge (
    input clk,
    input rst,

    // UART Receiver interface
    input uart_done,
    input [7:0] uart_data,

    // SPI Master interface
    input spi_done,
    input [7:0] spi_rx_data,
    output reg spi_start,
    output reg [7:0] spi_tx_data,

    // UART Transmitter
    output reg tx_start,
    output reg [7:0] tx_data,
    input tx_busy
);

    // Verilog-style state definition
    reg [1:0] state;
    reg [1:0] next_state;

    localparam IDLE      = 2'd0;
    localparam SEND_SPI  = 2'd1;
    localparam WAIT_SPI  = 2'd2;
    localparam SEND_UART = 2'd3;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= IDLE;
            spi_start <= 0;
            tx_start <= 0;
        end else begin
            state <= next_state;

            // Control signals
            case (next_state)
                IDLE: begin
                    spi_start <= 0;
                    tx_start <= 0;
                end
                SEND_SPI: begin
                    spi_start <= 1;
                    tx_start <= 0;
                end
                WAIT_SPI: begin
                    spi_start <= 0;
                end
                SEND_UART: begin
                    if (!tx_busy)
                        tx_start <= 1;
                end
            endcase
        end
    end

    always @(*) begin
        next_state = state;
        case (state)
            IDLE: if (uart_done)
                      next_state = SEND_SPI;
            SEND_SPI: next_state = WAIT_SPI;
            WAIT_SPI: if (spi_done)
                          next_state = SEND_UART;
            SEND_UART: if (!tx_busy)
                           next_state = IDLE;
        endcase
    end

    always @(posedge clk) begin
        if (uart_done)
            spi_tx_data <= uart_data;

        if (spi_done)
            tx_data <= spi_rx_data;
    end

endmodule
