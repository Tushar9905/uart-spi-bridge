module uart_tx (
    input clk,
    input rst,
    input start,
    input [7:0] data_in,
    output reg tx,
    output reg busy
);

    parameter CLK_PER_BIT = 87; // For 115200 baud at 10MHz clock

    reg [3:0] bit_index = 0;
    reg [15:0] clk_count = 0;
    reg [9:0] tx_shift = 10'b1111111111;
    reg sending = 0;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            tx <= 1;
            busy <= 0;
            clk_count <= 0;
            bit_index <= 0;
            tx_shift <= 10'b1111111111;
            sending <= 0;
        end else begin
            if (start && !busy) begin
                // Load frame: start(0), data, stop(1)
                tx_shift <= {1'b1, data_in, 1'b0}; 
                busy <= 1;
                sending <= 1;
                clk_count <= 0;
                bit_index <= 0;
            end else if (sending) begin
                if (clk_count < CLK_PER_BIT - 1) begin
                    clk_count <= clk_count + 1;
                end else begin
                    clk_count <= 0;
                    tx <= tx_shift[bit_index];
                    bit_index <= bit_index + 1;

                    if (bit_index == 9) begin
                        sending <= 0;
                        busy <= 0;
                        tx <= 1;
                    end
                end
            end
        end
    end
endmodule
