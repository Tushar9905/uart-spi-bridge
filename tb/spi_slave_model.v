`timescale 1ns/1ps

// Simulation model of an SPI slave (mode 0, MSB first)
module spi_slave_model (
    input            rst,
    input            sclk,
    input            cs_n,
    input            mosi,
    output           miso,
    input      [7:0] tx_byte,
    output reg [7:0] rx_byte
);

    reg  [7:0] shift_rx;
    reg  [2:0] rx_cnt, tx_cnt;
    wire       clear = rst | cs_n;

    assign miso = cs_n ? 1'bz : tx_byte[3'd7 - tx_cnt];

    always @(posedge sclk or posedge clear) begin
        if (clear) begin
            rx_cnt <= 0;
        end else begin
            shift_rx <= {shift_rx[6:0], mosi};
            rx_cnt   <= rx_cnt + 1;
            if (rx_cnt == 7)
                rx_byte <= {shift_rx[6:0], mosi};
        end
    end

    always @(negedge sclk or posedge clear) begin
        if (clear)
            tx_cnt <= 0;
        else
            tx_cnt <= tx_cnt + 1;
    end

    initial rx_byte = 0;

endmodule
