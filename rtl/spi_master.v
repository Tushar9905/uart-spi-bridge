`timescale 1ns/1ps

// SPI master, mode 0, MSB first. SCLK = clk / (2 * CLK_DIV)
module spi_master #(
    parameter CLK_DIV = 4
) (
    input            clk,
    input            rst,
    input            start,
    input      [7:0] mosi_data_in,
    output reg [7:0] miso_data_out,
    output reg       done,
    output           busy,
    output reg       sclk,
    output reg       mosi,
    input            miso,
    output reg       cs_n
);

    localparam IDLE     = 2'd0,
               TRANSFER = 2'd1,
               HOLD     = 2'd2;

    reg [1:0]  state;
    reg [15:0] div_count;
    reg [2:0]  bit_cnt;
    reg [7:0]  shift_tx, shift_rx;

    assign busy = (state != IDLE);

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state         <= IDLE;
            div_count     <= 0;
            bit_cnt       <= 0;
            shift_tx      <= 0;
            shift_rx      <= 0;
            miso_data_out <= 0;
            done          <= 0;
            sclk          <= 0;
            mosi          <= 0;
            cs_n          <= 1;
        end else begin
            done <= 0;

            case (state)
                IDLE: begin
                    sclk <= 0;
                    cs_n <= 1;
                    if (start) begin
                        shift_tx  <= mosi_data_in;
                        mosi      <= mosi_data_in[7];
                        cs_n      <= 0;
                        bit_cnt   <= 0;
                        div_count <= 0;
                        state     <= TRANSFER;
                    end
                end
                TRANSFER: begin
                    if (div_count == CLK_DIV - 1) begin
                        div_count <= 0;
                        sclk      <= ~sclk;
                        if (!sclk) begin
                            // rising edge: sample
                            shift_rx <= {shift_rx[6:0], miso};
                        end else begin
                            // falling edge: shift out
                            shift_tx <= {shift_tx[6:0], 1'b0};
                            mosi     <= shift_tx[6];
                            bit_cnt  <= bit_cnt + 1;
                            if (bit_cnt == 7)
                                state <= HOLD;
                        end
                    end else begin
                        div_count <= div_count + 1;
                    end
                end
                HOLD: begin
                    if (div_count == CLK_DIV - 1) begin
                        div_count     <= 0;
                        cs_n          <= 1;
                        miso_data_out <= shift_rx;
                        done          <= 1;
                        state         <= IDLE;
                    end else begin
                        div_count <= div_count + 1;
                    end
                end
                default: state <= IDLE;
            endcase
        end
    end

endmodule
