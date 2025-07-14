

`timescale 1ns / 1ps

module spi_master (
    input clk,
    input rst,
    input start,
    input [7:0] mosi_data_in,
    output reg [7:0] miso_data_out,
    output reg done,
    output reg sclk,
    output reg mosi,
    input miso,
    output reg cs
);

    reg [2:0] bit_cnt;
    reg [7:0] shift_reg_tx, shift_reg_rx;
    reg [2:0] state;
    reg [1:0] clk_div;

    localparam IDLE = 0,
               ASSERT_CS = 1,
               TRANSFER = 2,
               DEASSERT_CS = 3,
               DONE = 4;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= IDLE;
            bit_cnt <= 0;
            shift_reg_tx <= 0;
            shift_reg_rx <= 0;
            mosi <= 0;
            sclk <= 0;
            cs <= 1;
            done <= 0;
            miso_data_out <= 0;
            clk_div <= 0;
        end else begin
            clk_div <= clk_div + 1;
            case (state)
                IDLE: begin
                    done <= 0;
                    sclk <= 0;
                    cs <= 1;
                    if (start) begin
                        shift_reg_tx <= mosi_data_in;
                        bit_cnt <= 7;
                        cs <= 0;
                        clk_div <= 0;
                        state <= ASSERT_CS;
                    end
                end
                ASSERT_CS: begin
                    state <= TRANSFER;
                end
                TRANSFER: begin
                    if (clk_div == 2'b11) begin
                        sclk <= ~sclk;

                        if (sclk == 0) begin
                            
                            mosi <= shift_reg_tx[bit_cnt];
                        end else begin
                            
                            shift_reg_rx[bit_cnt] <= miso;
                            if (bit_cnt == 0) begin
                                state <= DEASSERT_CS;
                            end else begin
                                bit_cnt <= bit_cnt - 1;
                            end
                        end
                    end
                end
                DEASSERT_CS: begin
                    cs <= 1;
                    miso_data_out <= shift_reg_rx;
                    state <= DONE;
                end
                DONE: begin
                    done <= 1;
                    state <= IDLE;
                end
            endcase
        end
    end
endmodule


module spi_slave (
    input clk,
    input rst,
    input sclk,
    input mosi,
    output reg miso,
    input cs,
    output reg [7:0] data_out
);

    reg [7:0] shift_reg_rx = 0;
    reg [7:0] shift_reg_tx = 8'hA5;
    reg [2:0] bit_cnt = 0;

    always @(posedge sclk or posedge rst) begin
        if (rst) begin
            shift_reg_rx <= 0;
            data_out <= 0;
            bit_cnt <= 0;
            miso <= 0;
        end else if (!cs) begin
            shift_reg_rx[bit_cnt] <= mosi;
            miso <= shift_reg_tx[bit_cnt];
            if (bit_cnt == 7) begin
                data_out <= shift_reg_rx;
                bit_cnt <= 0;
            end else begin
                bit_cnt <= bit_cnt + 1;
            end
        end
    end
endmodule



