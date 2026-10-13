`timescale 1ns/1ps

// UART transmitter, 8N1, LSB first
module uart_tx #(
    parameter CLK_PER_BIT = 87  // 10 MHz / 87 ~= 115200 baud
) (
    input            clk,
    input            rst,
    input            start,
    input      [7:0] data_in,
    output reg       tx,
    output reg       busy
);

    reg [15:0] clk_count;
    reg [3:0]  bit_index;
    reg [8:0]  tx_shift;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            tx        <= 1;
            busy      <= 0;
            clk_count <= 0;
            bit_index <= 0;
            tx_shift  <= 9'h1FF;
        end else if (!busy) begin
            tx <= 1;
            if (start) begin
                tx_shift  <= {1'b1, data_in};  // data, then stop bit
                tx        <= 0;                // start bit
                busy      <= 1;
                clk_count <= 0;
                bit_index <= 0;
            end
        end else if (clk_count < CLK_PER_BIT - 1) begin
            clk_count <= clk_count + 1;
        end else begin
            clk_count <= 0;
            if (bit_index == 9) begin
                busy <= 0;
            end else begin
                tx        <= tx_shift[0];
                tx_shift  <= {1'b1, tx_shift[8:1]};
                bit_index <= bit_index + 1;
            end
        end
    end

endmodule
