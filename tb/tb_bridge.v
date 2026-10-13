`timescale 1ns/1ps

// The testbench acts as the PC on the UART side and uses spi_slave_model
// as the SPI device.
module tb_bridge;

    localparam CLK_PER_BIT = 87;
    localparam BIT_NS      = CLK_PER_BIT * 100;
    localparam N           = 8;

    reg clk = 0;
    reg rst = 1;
    always #50 clk = ~clk;  // 10 MHz

    reg        uart_rx = 1;
    wire       uart_tx;
    wire       sclk, mosi, miso, cs_n, frame_err;
    reg  [7:0] slave_tx;
    wire [7:0] slave_rx;

    uart_spi_bridge_top #(.CLK_PER_BIT(CLK_PER_BIT), .SPI_CLK_DIV(4)) dut (
        .clk(clk), .rst(rst),
        .uart_rx(uart_rx), .uart_tx(uart_tx),
        .spi_sclk(sclk), .spi_mosi(mosi), .spi_miso(miso), .spi_cs_n(cs_n),
        .frame_err(frame_err)
    );

    spi_slave_model slave (
        .rst(rst), .sclk(sclk), .cs_n(cs_n), .mosi(mosi), .miso(miso),
        .tx_byte(slave_tx), .rx_byte(slave_rx)
    );

    reg [7:0] sent      [0:N-1];
    reg [7:0] reply     [0:N-1];
    reg [7:0] slave_got [0:N-1];
    reg [7:0] echoed    [0:N-1];
    integer   xfers = 0, echoes = 0, errors = 0, i, k;
    reg       in_xfer = 0;
    reg [7:0] b;

    // record each SPI transfer and load the next reply
    always @(negedge cs_n) in_xfer = 1;
    always @(posedge cs_n) if (in_xfer) begin
        in_xfer = 0;
        if (xfers < N) slave_got[xfers] = slave_rx;
        xfers = xfers + 1;
        if (xfers < N) slave_tx = reply[xfers];
    end

    task send_frame;
        input [7:0] d;
        begin
            uart_rx = 0;
            #(BIT_NS);
            for (k = 0; k < 8; k = k + 1) begin
                uart_rx = d[k];
                #(BIT_NS);
            end
            uart_rx = 1;
            #(BIT_NS);
        end
    endtask

    // decode the UART reply line
    integer j;
    always begin
        @(negedge uart_tx);
        #(BIT_NS / 2);
        if (uart_tx === 0) begin
            for (j = 0; j < 8; j = j + 1) begin
                #(BIT_NS);
                b[j] = uart_tx;
            end
            #(BIT_NS);
            if (echoes < N) echoed[echoes] = b;
            echoes = echoes + 1;
        end
    end

    initial begin
        sent[0] = 8'h12; reply[0] = 8'hC1;
        sent[1] = 8'h13; reply[1] = 8'h83;
        sent[2] = 8'h80; reply[2] = 8'h01;
        sent[3] = 8'h00; reply[3] = 8'hFF;
        sent[4] = 8'hFF; reply[4] = 8'h00;
        sent[5] = 8'h6B; reply[5] = 8'hD2;
        sent[6] = 8'h01; reply[6] = 8'h80;
        sent[7] = 8'hE7; reply[7] = 8'h18;
        slave_tx = reply[0];

        $dumpfile("tb_bridge.vcd");
        $dumpvars(0, tb_bridge);

        #500 rst = 0;
        #(2 * BIT_NS);

        for (i = 0; i < N; i = i + 1)
            send_frame(sent[i]);
        #(15 * BIT_NS);

        if (xfers != N || echoes != N) begin
            $display("FAIL: %0d SPI transfers, %0d UART replies, expected %0d", xfers, echoes, N);
            errors = errors + 1;
        end
        for (i = 0; i < N; i = i + 1)
            if (slave_got[i] !== sent[i] || echoed[i] !== reply[i]) begin
                $display("FAIL: byte %0d: slave got %h (exp %h), reply %h (exp %h)",
                         i, slave_got[i], sent[i], echoed[i], reply[i]);
                errors = errors + 1;
            end

        if (errors == 0) $display("PASS: tb_bridge");
        else             $display("FAIL: tb_bridge, %0d error(s)", errors);
        $finish;
    end

endmodule
