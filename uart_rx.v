module uart_rx (
    input clk,
    input rst,
    input rx,
    output reg [7:0] data_out,
    output reg done
);

    parameter CLK_PER_BIT = 87;

    reg [15:0] clk_count = 0;
    reg [3:0] bit_index = 0;
    reg [7:0] rx_shift = 0;
    reg receiving = 0;

    localparam IDLE = 0,
               START = 1,
               DATA = 2,
               STOP = 3;

    reg [1:0] state = IDLE;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= IDLE;
            clk_count <= 0;
            bit_index <= 0;
            rx_shift <= 0;
            data_out <= 0;
            done <= 0;
        end else begin
            case (state)
                IDLE: begin
                    done <= 0;
                    if (rx == 0) begin // Start bit detected
                        clk_count <= CLK_PER_BIT / 2;
                        state <= START;
                    end
                end
                START: begin
                    if (clk_count == 0) begin
                        state <= DATA;
                        clk_count <= CLK_PER_BIT - 1;
                        bit_index <= 0;
                    end else begin
                        clk_count <= clk_count - 1;
                    end
                end
                DATA: begin
                    if (clk_count == 0) begin
                        rx_shift[bit_index] <= rx;
                        bit_index <= bit_index + 1;
                        if (bit_index == 7) begin
                            state <= STOP;
                        end
                        clk_count <= CLK_PER_BIT - 1;
                    end else begin
                        clk_count <= clk_count - 1;
                    end
                end
                STOP: begin
                    if (clk_count == 0) begin
                        data_out <= rx_shift;
                        done <= 1;
                        state <= IDLE;
                    end else begin
                        clk_count <= clk_count - 1;
                    end
                end
            endcase
        end
    end
endmodule
