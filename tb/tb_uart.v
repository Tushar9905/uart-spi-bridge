`timescale 1ns/1ps

module tb_uart;

    localparam CLK_PER_BIT = 87;
    localparam BIT_NS      = CLK_PER_BIT * 100;
    localparam N           = 8;

    reg clk = 0;
    reg rst = 1;
    always #50 clk = ~clk;  // 10 MHz

    reg        start = 0;
    reg  [7:0] data_in = 0;
    reg        tb_line = 1;
    wire       tx, busy;
    wire [7:0] data_out;
    wire       done, frame_err;

    uart_tx #(.CLK_PER_BIT(CLK_PER_BIT)) dut_tx (
        .clk(clk), .rst(rst), .start(start), .data_in(data_in),
        .tx(tx), .busy(busy)
    );

    uart_rx #(.CLK_PER_BIT(CLK_PER_BIT)) dut_rx (
        .clk(clk), .rst(rst), .rx(tx & tb_line),
        .data_out(data_out), .done(done), .frame_err(frame_err)
    );

    reg [7:0] vectors  [0:N-1];
    reg [7:0] received [0:N-1];
    integer   rx_count = 0, ferr_count = 0, errors = 0, i;

    always @(posedge clk) begin
        if (done) begin
            if (rx_count < N) received[rx_count] = data_out;
            rx_count = rx_count + 1;
        end
        if (frame_err)
            ferr_count = ferr_count + 1;
    end

    task send_byte;
        input [7:0] b;
        begin
            @(negedge clk);
            while (busy) @(negedge clk);
            data_in = b;
            start   = 1;
            @(negedge clk);
            start   = 0;
        end
    endtask

    // frame driven directly on the line, with a chosen stop bit
    task drive_frame;
        input [7:0] b;
        input       stop_bit;
        integer k;
        begin
            tb_line = 0;
            #(BIT_NS);
            for (k = 0; k < 8; k = k + 1) begin
                tb_line = b[k];
                #(BIT_NS);
            end
            tb_line = stop_bit;
            #(BIT_NS);
            tb_line = 1;
        end
    endtask

    initial begin
        vectors[0] = 8'h00; vectors[1] = 8'hFF; vectors[2] = 8'h12; vectors[3] = 8'h13;
        vectors[4] = 8'h80; vectors[5] = 8'h01; vectors[6] = 8'hC1; vectors[7] = 8'h3C;

        $dumpfile("tb_uart.vcd");
        $dumpvars(0, tb_uart);

        #500 rst = 0;
        #500;

        // loopback, back-to-back
        for (i = 0; i < N; i = i + 1)
            send_byte(vectors[i]);
        #(12 * BIT_NS);
        if (rx_count != N) begin
            $display("FAIL: received %0d bytes, expected %0d", rx_count, N);
            errors = errors + 1;
        end
        for (i = 0; i < N; i = i + 1)
            if (received[i] !== vectors[i]) begin
                $display("FAIL: byte %0d: sent %h, received %h", i, vectors[i], received[i]);
                errors = errors + 1;
            end

        // short glitch must be ignored
        rx_count = 0;
        tb_line = 0;
        #1000;
        tb_line = 1;
        #(12 * BIT_NS);
        if (rx_count != 0) begin
            $display("FAIL: glitch accepted as a start bit");
            errors = errors + 1;
        end

        // bad stop bit must give frame_err and no data
        drive_frame(8'h5A, 0);
        #(2 * BIT_NS);
        if (ferr_count != 1 || rx_count != 0) begin
            $display("FAIL: bad stop bit not detected");
            errors = errors + 1;
        end

        if (errors == 0) $display("PASS: tb_uart");
        else             $display("FAIL: tb_uart, %0d error(s)", errors);
        $finish;
    end

endmodule
