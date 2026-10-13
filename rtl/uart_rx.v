`timescale 1ns/1ps

// UART receiver, 8N1, LSB first
module uart_rx #(
    parameter CLK_PER_BIT = 87
) (
    input            clk,
    input            rst,
    input            rx,
    output reg [7:0] data_out,
    output reg       done,
    output reg       frame_err
);

    localparam IDLE  = 2'd0,
               START = 2'd1,
               DATA  = 2'd2,
               STOP  = 2'd3;

    reg [1:0]  state;
    reg [15:0] clk_count;
    reg [2:0]  bit_index;
    reg [7:0]  rx_shift;
    reg        rx_meta, rx_sync, rx_prev;

    // synchronizer
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            rx_meta <= 1;
            rx_sync <= 1;
            rx_prev <= 1;
        end else begin
            rx_meta <= rx;
            rx_sync <= rx_meta;
            rx_prev <= rx_sync;
        end
    end

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state     <= IDLE;
            clk_count <= 0;
            bit_index <= 0;
            rx_shift  <= 0;
            data_out  <= 0;
            done      <= 0;
            frame_err <= 0;
        end else begin
            done      <= 0;
            frame_err <= 0;

            case (state)
                IDLE: begin
                    clk_count <= 0;
                    if (rx_prev && !rx_sync)
                        state <= START;
                end
                START: begin
                    if (clk_count == (CLK_PER_BIT - 1) / 2) begin
                        clk_count <= 0;
                        bit_index <= 0;
                        state     <= rx_sync ? IDLE : DATA;  // ignore glitches
                    end else begin
                        clk_count <= clk_count + 1;
                    end
                end
                DATA: begin
                    if (clk_count == CLK_PER_BIT - 1) begin
                        clk_count <= 0;
                        rx_shift  <= {rx_sync, rx_shift[7:1]};
                        bit_index <= bit_index + 1;
                        if (bit_index == 7)
                            state <= STOP;
                    end else begin
                        clk_count <= clk_count + 1;
                    end
                end
                STOP: begin
                    if (clk_count == CLK_PER_BIT - 1) begin
                        clk_count <= 0;
                        if (rx_sync) begin
                            data_out <= rx_shift;
                            done     <= 1;
                        end else begin
                            frame_err <= 1;
                        end
                        state <= IDLE;
                    end else begin
                        clk_count <= clk_count + 1;
                    end
                end
            endcase
        end
    end

endmodule
